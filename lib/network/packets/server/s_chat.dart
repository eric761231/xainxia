/// 聊天頻道（與伺服器 ChatChannel 的 int 值對應）。
enum ChatChannel {
  /// 綜合：前端「全部顯示」的檢視用，不可發送。
  general,

  /// 世界：全服廣播。
  world,

  /// 隊伍（尚無組隊系統）。
  party,

  /// 門派（尚無門派系統）。
  guild,

  /// 私聊：需指定對象。
  whisper,

  /// 系統：僅伺服器產生。
  system;

  int get code => index;

  /// 由伺服器代號轉列舉；未知代號一律視為 [system]（最保守，不會被誤當成可發送頻道）。
  static ChatChannel fromCode(int code) =>
      (code >= 0 && code < ChatChannel.values.length)
          ? ChatChannel.values[code]
          : ChatChannel.system;

  /// 客戶端是否允許以此頻道發言。
  bool get sendable =>
      this == world || this == party || this == guild || this == whisper;

  String get label => switch (this) {
        ChatChannel.general => '綜合',
        ChatChannel.world => '世界',
        ChatChannel.party => '隊伍',
        ChatChannel.guild => '門派',
        ChatChannel.whisper => '私聊',
        ChatChannel.system => '系統',
      };
}

/// 聊天訊息。系統訊息的 [sender] 為空字串。
class SChat {
  const SChat({
    required this.channel,
    required this.sender,
    required this.text,
  });

  final ChatChannel channel;
  final String sender;
  final String text;

  factory SChat.fromData(Map<String, dynamic> data) => SChat(
        channel: ChatChannel.fromCode((data['channel'] as num?)?.toInt() ?? 5),
        sender: data['sender'] as String? ?? '',
        text: data['text'] as String? ?? '',
      );
}
