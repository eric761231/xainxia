import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/network/codec/plain_text_codec.dart';

void main() {
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
