import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/codec/plain_text_codec.dart';

/// 明文 JSON 行協議的切行。
///
/// TCP 分段的切點是任意的：可能切在中文字中間、一段裡有好幾行、一行跨好幾段。
/// 解錯了不會拋例外，只會讓整個封包消失 —— 地圖上的物件就不見了。
void main() {
  /// 把整串 bytes 依固定大小切段餵進去，收集所有解出的行。
  List<String> feed(PlainTextCodec codec, List<int> bytes, int chunkSize) {
    final out = <String>[];
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, bytes.length);
      var chunk = bytes.sublist(i, end);
      while (true) {
        final line = codec.decode(chunk);
        if (line == null) break;
        out.add(line);
        chunk = const <int>[];
      }
    }
    return out;
  }

  test('中文字被切在兩段之間也能完整解出', () {
    final codec = PlainTextCodec();
    final bytes = utf8.encode('{"name":"古橡"}\n');
    // 每 1 byte 一段：每個中文字的 3 個 bytes 都被拆開
    expect(feed(codec, bytes, 1), ['{"name":"古橡"}']);
  });

  test('一段裡有多行、空行略過，全部解出且順序不變', () {
    final codec = PlainTextCodec();
    final bytes = utf8.encode('{"a":1}\n\n{"b":"黑森林"}\n{"c":3}\n');
    expect(feed(codec, bytes, bytes.length), ['{"a":1}', '{"b":"黑森林"}', '{"c":3}']);
  });

  test('上千筆中文物件的大封包跨多段到達，內容一字不差', () {
    final codec = PlainTextCodec();
    final props = List.generate(3000, (i) => {'objId': i, 'name': '枯枒（鏡像）$i'});
    final line = jsonEncode({'op': 'S_PROPERTY_PACK', 'data': {'properties': props}});
    final bytes = utf8.encode('$line\n{"op":"NEXT"}\n');
    // 奇數大小的段落，保證切點會落在多位元組字元中間
    final lines = feed(codec, bytes, 4093);
    expect(lines, hasLength(2));
    expect(lines.first, line);
    expect(lines.last, '{"op":"NEXT"}');
  });

  test('reset 丟掉還沒收完的半行', () {
    final codec = PlainTextCodec();
    expect(codec.decode(utf8.encode('{"half":')), isNull);
    codec.reset();
    expect(feed(codec, utf8.encode('{"ok":1}\n'), 3), ['{"ok":1}']);
  });

  group('PlainTextCodec', () {
    test('single chunk with multiple JSON lines decodes all lines', () {
      final codec = PlainTextCodec();
      const amount = '{"op":"S_CHARACTER_AMOUNT","data":{"count":1,"maxSlots":2}}';
      const list = '{"op":"S_CHARACTER_LIST","data":{"characters":[]}}';
      final chunk = utf8.encode('$amount\n$list\n');

      expect(codec.decode(chunk), amount);
      expect(codec.decode(const <int>[]), list);
      expect(codec.decode(const <int>[]), isNull);
    });

    test('create char triple response decodes in loop pattern', () {
      final codec = PlainTextCodec();
      const result =
          '{"op":"S_CREATE_CHAR_RESULT","data":{"success":true,"reason":"OK","message":"角色建立成功"}}';
      const amount = '{"op":"S_CHARACTER_AMOUNT","data":{"count":1,"maxSlots":2}}';
      const list =
          '{"op":"S_CHARACTER_LIST","data":{"characters":[{"name":"雷帝","level":1,"sex":0,"attribute":0}]}}';
      final chunk = utf8.encode('$result\n$amount\n$list\n');

      final lines = <String>[];
      var pending = chunk;
      while (true) {
        final line = codec.decode(pending);
        if (line == null) {
          break;
        }
        lines.add(line);
        pending = Uint8List(0);
      }

      expect(lines, [result, amount, list]);
    });
  });
}
