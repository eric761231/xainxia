/// 網路封包的通用外殼。
///
/// 所有收發封包皆為 JSON：{ "op": "封包類型", "data": { ... } }
/// - [op]：封包類型字串，見 [ServerOpcodes] / [ClientOpcodes]
/// - [data]：該封包的實際內容，由各封包類別的 fromData 進一步解析
class GamePacket {
  const GamePacket({
    required this.op,
    required this.data,
  });

  /// 封包類型，例如 "S_LOGIN_RESULT"、"C_AUTH_LOGIN"。
  final String op;

  /// 封包內容（JSON 物件），需再交給 SLoginResult.fromData 等解析。
  final Map<String, dynamic> data;

  /// 從 GameSocket 收到的 JSON 建立 [GamePacket]。
  factory GamePacket.fromJson(Map<String, dynamic> json) {
    final op = json['op'];
    if (op is! String) {
      throw FormatException('封包缺少 op 欄位');
    }
    final rawData = json['data'];
    return GamePacket(
      op: op,
      data: rawData is Map<String, dynamic>
          ? rawData
          : (rawData is Map ? Map<String, dynamic>.from(rawData) : {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'op': op,
        'data': data,
      };
}
