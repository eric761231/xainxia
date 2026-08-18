import '../../opcodes/client_opcodes.dart';

/// 進入傳送點（換圖）請求。
/// 伺服器依 portalId 查表決定目的地；facing 0-7 為玩家踏上傳送點時的當下面向，
/// 傳送點未指定 dest_heading 時到達沿用此面向。
class CEnterPortal {
  CEnterPortal._();

  static Map<String, dynamic> build({
    required int portalId,
    required int facing,
  }) =>
      {
        'op': ClientOpcodes.cEnterPortal,
        'data': {'portalId': portalId, 'facing': facing},
      };
}
