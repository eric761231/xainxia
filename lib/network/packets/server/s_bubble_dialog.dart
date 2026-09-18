/// 氣泡對話：顯示於物件頭上的一句話。
///
/// 與 [SDialog] 的分工：本封包是無選項的頭上氣泡（場景物件），
/// 對話視窗則是有回覆分支的 UI（NPC／商店）。
/// [name] 可為空字串，代表只顯示對話內容而不顯示名稱。
class SBubbleDialog {
  const SBubbleDialog({
    required this.objId,
    required this.name,
    required this.text,
  });

  /// 氣泡要顯示在哪個物件頭上。
  final int objId;
  final String name;
  final String text;

  factory SBubbleDialog.fromData(Map<String, dynamic> data) => SBubbleDialog(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        name: data['name'] as String? ?? '',
        text: data['text'] as String? ?? '',
      );
}
