/// 對話選項。
class DialogOption {
  const DialogOption({required this.id, required this.text});

  final int id;
  final String text;

  factory DialogOption.fromData(Map<String, dynamic> data) => DialogOption(
        id: (data['id'] as num?)?.toInt() ?? 0,
        text: data['text'] as String? ?? '',
      );
}

/// NPC 對話視窗封包（回應 C_INTERACT）。
///
/// [options] 為可選的回覆分支；空清單代表單純顯示一句話。
/// 與 SBubbleDialog 的分工：本封包是有選項的對話視窗（NPC／商店），
/// 氣泡對話則是物件頭上的一句話（場景物件）。
///
/// 對話對象以 [objId] 識別，而非模板編號 —— 同張圖的同名 NPC 會撞在一起。
class SDialog {
  const SDialog({
    required this.objId,
    required this.name,
    required this.text,
    required this.options,
  });

  final int objId;
  final String name;
  final String text;
  final List<DialogOption> options;

  factory SDialog.fromData(Map<String, dynamic> data) => SDialog(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        name: data['name'] as String? ?? '',
        text: data['text'] as String? ?? '',
        options: (data['options'] as List<dynamic>? ?? [])
            .map((o) => DialogOption.fromData(o as Map<String, dynamic>))
            .toList(),
      );
}
