import 'dart:convert';

import 'packet_codec.dart';

/// 明文 JSON 行協議（utf8 + \n），對齊 XinServer Netty StringEncoder
///
/// **以位元組為單位切行，切出完整一行才解碼 UTF-8。**
/// TCP 會把一個大封包拆成好幾段送達，切點可能落在中文字（3 bytes）的中間。
/// 以前每收到一段就先 `utf8.decode` 再找換行，大封包（例如黑森林上千筆
/// 場景物件的 S_PROPERTY_PACK，名稱都是中文）幾乎一定被切壞，整包遺失 ——
/// 畫面上就是「進地圖看不到物件」，而且沒有任何錯誤提示。
/// 換行字元 0x0A 不會出現在 UTF-8 多位元組序列裡，所以按位元組切行是安全的。
class PlainTextCodec implements PacketCodec {
  final List<int> _pending = [];

  /// 上次已經找過、確定沒有換行的位置；大封包分段到達時不必每次從頭掃。
  int _scanFrom = 0;

  static const int _newline = 0x0A;

  @override
  // 將 JSON 行轉換為 bytes，並在末尾加上 \n
  List<int> encode(String jsonLine) {
    return utf8.encode('$jsonLine\n');
  }

  @override
  // 餵入收到的 bytes，若有完整一行 JSON 則回傳，否則 null
  String? decode(List<int> chunk) {
    if (chunk.isNotEmpty) _pending.addAll(chunk);
    while (true) {
      final index = _pending.indexOf(_newline, _scanFrom);
      if (index < 0) {
        _scanFrom = _pending.length;
        return null;
      }
      final bytes = _pending.sublist(0, index);
      _pending.removeRange(0, index + 1);
      _scanFrom = 0;
      final line = utf8.decode(bytes, allowMalformed: true).trim();
      // 空行略過，繼續找下一行，不要讓後面已到達的封包卡到下一次收資料
      if (line.isNotEmpty) return line;
    }
  }

  @override
  // 清空緩衝區
  void reset() {
    _pending.clear();
    _scanFrom = 0;
  }
}
