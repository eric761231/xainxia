import 'packet_codec.dart';
import 'plain_text_codec.dart';

// 封包編解碼器工廠
class CodecFactory {
  CodecFactory._();

  // 根據 codecName 創建對應的 PacketCodec 實例
  static PacketCodec create(String codecName) {
    switch (codecName) {
      // 明文 JSON 行協議（utf8 + \n），對齊 XinServer Netty StringEncoder
      case 'plain':
        // 創建 PlainTextCodec 實例
        return PlainTextCodec();
      // 不支援的 codec，則拋出 UnsupportedError
      default:
        throw UnsupportedError('不支援的 codec: $codecName'); // 拋出 UnsupportedError
    }
  }
}
