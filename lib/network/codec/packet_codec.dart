/// 封包編解碼抽象層（日後可替換為加密 Codec）
abstract class PacketCodec {
  List<int> encode(String jsonLine);

  /// 餵入收到的 bytes，若有完整一行 JSON 則回傳，否則 null
  String? decode(List<int> chunk);

  void reset(); // 重置
}
