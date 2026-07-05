import 'dart:convert';

import 'packet_codec.dart';

/// 明文 JSON 行協議（utf8 + \n），對齊 XinServer Netty StringEncoder
class PlainTextCodec implements PacketCodec {
  final StringBuffer _buffer = StringBuffer();

  @override
  // 將 JSON 行轉換為 bytes，並在末尾加上 \n
  List<int> encode(String jsonLine) {
    return utf8.encode('$jsonLine\n');
  }

  @override
  // 餵入收到的 bytes，若有完整一行 JSON 則回傳，否則 null
  String? decode(List<int> chunk) {
    // 將收到的 bytes 轉換為字串，並附加到緩衝區
    _buffer.write(utf8.decode(chunk));
    // 將緩衝區的內容轉換為字串
    final content = _buffer.toString();
    // 查找末尾的 \n
    // 找到末尾的 \n
    final newlineIndex = content.indexOf('\n');
    if (newlineIndex < 0) {
      return null;
    }

    // 截取到末尾的 \n 之前的內容
    final line = content.substring(0, newlineIndex).trim();
    // 截取到末尾的 \n 之後的內容
    final remainder = content.substring(newlineIndex + 1);
    // 清空緩衝區，並附加剩餘的內容
    _buffer
      ..clear()
      ..write(remainder);

    // 如果截取到的內容為空，則返回 null
    if (line.isEmpty) {
      return null;
    }
    return line;
  }

  @override
  // 清空緩衝區
  void reset() {
    _buffer.clear();
  }
}
