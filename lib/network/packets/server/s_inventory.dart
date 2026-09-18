/// 背包裡的一件道具。
///
/// 模板欄位（名稱、類型、可否使用）由伺服器一併帶來，前端因此
/// **不需要一份 item 表的副本** —— 道具定義只存在伺服器，加新道具不必改前端。
class InventoryItem {
  const InventoryItem({
    required this.objId,
    required this.itemId,
    required this.count,
    required this.name,
    required this.itemType,
    required this.stackable,
    required this.usable,
    required this.equipped,
    required this.enchantLevel,
  });

  /// 這一筆的唯一編號。使用／丟棄都以它指定，不是用 itemId ——
  /// 同一種道具可能有多筆（不可疊加的武器）。
  final int objId;

  /// 道具種類編號（→ 伺服器 item 表）。
  final int itemId;
  final int count;
  final String name;

  /// 0=一般 1=武器 2=防具。
  final int itemType;
  final bool stackable;
  final bool usable;
  final bool equipped;
  final int enchantLevel;

  bool get isWeapon => itemType == 1;
  bool get isArmor => itemType == 2;

  /// 顯示名稱：有強化等級就加上 +N。
  String get displayName =>
      enchantLevel > 0 ? '$name +$enchantLevel' : name;

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        objId: (j['objId'] as num?)?.toInt() ?? 0,
        itemId: (j['itemId'] as num?)?.toInt() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        itemType: (j['itemType'] as num?)?.toInt() ?? 0,
        stackable: j['stackable'] as bool? ?? false,
        usable: j['usable'] as bool? ?? false,
        equipped: j['equipped'] as bool? ?? false,
        enchantLevel: (j['enchantLevel'] as num?)?.toInt() ?? 0,
      );
}

/// 整份背包。進遊戲時送一次，之後的變動走 S_ITEM_UPDATE／S_ITEM_REMOVE。
class SInventory {
  const SInventory({required this.items});

  final List<InventoryItem> items;

  factory SInventory.fromData(Map<String, dynamic> data) => SInventory(
        items: [
          for (final i in (data['items'] as List<dynamic>? ?? const []))
            InventoryItem.fromJson(i as Map<String, dynamic>),
        ],
      );
}

/// 單一道具新增或變更。**upsert 語意**：objId 已存在就更新，沒有就新增。
///
/// 所以「撿到新道具」與「數量改變」共用同一個封包。
class SItemUpdate {
  const SItemUpdate({required this.item});

  final InventoryItem item;

  factory SItemUpdate.fromData(Map<String, dynamic> data) => SItemUpdate(
        item: InventoryItem.fromJson(
            data['item'] as Map<String, dynamic>? ?? const {}),
      );
}

/// 道具整筆從背包消失（用光、丟棄、賣掉）。
///
/// 數量減少但還有剩的情況走 S_ITEM_UPDATE —— 前端據此決定是移除該格還是只改數字。
class SItemRemove {
  const SItemRemove({required this.objId});

  final int objId;

  factory SItemRemove.fromData(Map<String, dynamic> data) =>
      SItemRemove(objId: (data['objId'] as num?)?.toInt() ?? 0);
}
