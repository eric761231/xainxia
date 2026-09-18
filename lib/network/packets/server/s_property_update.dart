/// 場景物件狀態變化（藥草被採了一次、礦石被挖了一段進度）。
///
/// 只帶會變動的欄位；圖片、名稱等靜態設定沿用 S_PROPERTY_PACK 收到的資料。
/// 物件若直接消失（採光／挖盡），伺服器改送 S_OBJECT_REMOVE。
class SPropertyUpdate {
  const SPropertyUpdate({
    required this.objId,
    required this.value,
    required this.action,
  });

  final int objId;

  /// 變化後的數值（進度條之類的）。
  final int value;

  /// 變化後是否仍可互動（採空後為 false）。
  final bool action;

  factory SPropertyUpdate.fromData(Map<String, dynamic> data) => SPropertyUpdate(
        objId: (data['objId'] as num?)?.toInt() ?? 0,
        value: (data['value'] as num?)?.toInt() ?? 0,
        action: data['action'] as bool? ?? false,
      );
}
