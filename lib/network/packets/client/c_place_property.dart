import '../../opcodes/client_opcodes.dart';

/// 放置家具（洞府布置）。
///
/// 伺服器會驗證：是否在可布置的地圖、物件是否可放置、放置面規則
/// （地板家具需可走格、壁掛物需不可走格）、是否重疊、是否超過件數上限。
class CPlaceProperty {
  CPlaceProperty._();

  static Map<String, dynamic> build({
    required int propertyId,
    required int x,
    required int y,
  }) =>
      {
        'op': ClientOpcodes.cPlaceProperty,
        'data': {'propertyId': propertyId, 'x': x, 'y': y},
      };
}

/// 移除家具（只能移除自己的）。
class CRemoveProperty {
  CRemoveProperty._();

  static Map<String, dynamic> build({required int objId}) => {
        'op': ClientOpcodes.cRemoveProperty,
        'data': {'objId': objId},
      };
}

/// 請求可放置家具清單。
class CPlaceableList {
  CPlaceableList._();

  static Map<String, dynamic> build() => {
        'op': ClientOpcodes.cPlaceableList,
        'data': <String, dynamic>{},
      };
}

/// 搬動已放置的家具。
///
/// 伺服器驗證與放置同一套規則，但會排除「正在搬的這一件」——
/// 否則往旁邊移一格會撞到自己原本的佔格而永遠被拒。
class CMoveProperty {
  CMoveProperty._();

  static Map<String, dynamic> build({
    required int objId,
    required int x,
    required int y,
  }) =>
      {
        'op': ClientOpcodes.cMoveProperty,
        'data': {'objId': objId, 'x': x, 'y': y},
      };
}

/// GM 編輯地形碰撞：把單一格子設為可走／不可走。
///
/// 地形是全體共用的，伺服器改完會廣播 S_MAP_COLLISION 給所有人。
class CGmCollision {
  CGmCollision._();

  static Map<String, dynamic> build({
    required int x,
    required int y,
    required bool blocked,
  }) =>
      {
        'op': ClientOpcodes.cGmCollision,
        'data': {'x': x, 'y': y, 'blocked': blocked},
      };
}
