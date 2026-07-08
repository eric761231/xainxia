/// 對話選項。
class DialogOption {
  const DialogOption({required this.id, required this.text});

  final int id;
  final String text;

  factory DialogOption.fromData(Map<String, dynamic> data) => DialogOption(
        id: data['id'] as int? ?? 0,
        text: data['text'] as String? ?? '',
      );
}

/// NPC 對話封包（回應 C_INTERACT）。
///
/// [options] 為可選的回覆分支；空清單代表單純顯示一句話。
class SDialog {
  const SDialog({
    required this.npcId,
    required this.npcName,
    required this.text,
    required this.options,
  });

  final int npcId;
  final String npcName;
  final String text;
  final List<DialogOption> options;

  factory SDialog.fromData(Map<String, dynamic> data) => SDialog(
        npcId: data['npcId'] as int? ?? 0,
        npcName: data['npcName'] as String? ?? '',
        text: data['text'] as String? ?? '',
        options: (data['options'] as List<dynamic>? ?? [])
            .map((o) => DialogOption.fromData(o as Map<String, dynamic>))
            .toList(),
      );
}
