import '../../opcodes/client_opcodes.dart';

/// 請求當前地圖資訊（小地圖：地名 + 傳送點清單）。
/// 伺服器依角色當前 mapId 回 S_MAP_INFO；通常用於重整小地圖。
class CMapInfo {
  CMapInfo._();

  static Map<String, dynamic> build() => {
        'op': ClientOpcodes.cMapInfo,
        'data': <String, dynamic>{},
      };
}
