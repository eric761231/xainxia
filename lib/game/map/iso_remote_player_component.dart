import 'iso_map_data.dart';
import 'iso_player_component.dart';
import 'scene_asset_loader.dart';

/// 其他玩家。
///
/// 沿用 [IsoPlayerComponent] 的走格動畫與深度排序，只改掉三件與「這不是我」
/// 有關的事：不畫面向箭頭、不受本地碰撞圖限制、頭上掛名字。
///
/// 位置一律由伺服器推動（S_PC_PACK 的名單、S_CHAR_MOVE 的每一步），
/// 沒有任何本地輸入會碰到它。
class IsoRemotePlayerComponent extends IsoPlayerComponent {
  // charName 也要傳給父類的 displayName，不能改寫成 super parameters。
  // ignore: use_super_parameters
  IsoRemotePlayerComponent({
    required this.charName,
    required this.objId,
    required int initialTileX,
    required int initialTileY,
    required IsoMapData mapData,
    int initialFacing = 2,
    CharacterSpriteSet? spriteSet,
  }) : super(
         initialTileX: initialTileX,
         initialTileY: initialTileY,
         mapData: mapData,
         initialFacing: initialFacing,
         spriteSet: spriteSet,
         displayName: charName,
       );

  /// 角色名。S_CHAR_MOVE／S_CHAR_FACE 以名字識別人物，這是對得上的那把鑰匙。
  final String charName;

  /// 角色 objId。給右鍵選單（邀請組隊、查看資料）用。
  final int objId;

  /// 別人的移動已經由伺服器驗過了。
  ///
  /// 本地碰撞圖只是自己走路時的預測，而且遠端玩家可能站在我這邊還沒收到的
  /// 家具上 —— 拿它去擋別人，結果是對方卡在錯的格子上，之後每一步都歪。
  @override
  bool canEnter(int tx, int ty) => true;

  @override
  bool get showsFacingArrow => false;

  /// 伺服器說他現在在這裡。
  ///
  /// 差一格以內走過去（看起來是在走路），差更多就直接瞬移 —— 那代表
  /// 傳送、剛進圖、或前後端已經不同步，用走的只會走出一段假動畫。
  void applyServerPosition(int x, int y, {int? facing}) {
    final far = (x - tileX).abs() > 1 || (y - tileY).abs() > 1;
    if (far) {
      snapTo(x, y, facing: facing);
      return;
    }
    if (facing != null) {
      this.facing = facing.clamp(0, 7);
    }
    moveTo(x, y);
  }
}

/// 建立一個遠端玩家元件（含 sprite 載入）。
///
/// 外觀目前只由性別決定，與本機玩家共用同一組資產。
Future<IsoRemotePlayerComponent> createRemotePlayer({
  required String charName,
  required int objId,
  required int x,
  required int y,
  required int facing,
  required int sex,
  required IsoMapData mapData,
}) async {
  final spriteSet = await SceneAssetLoader.loadCharacterSprites(
    sex == 1 ? 'female' : 'male',
  );
  return IsoRemotePlayerComponent(
    charName: charName,
    objId: objId,
    initialTileX: x,
    initialTileY: y,
    initialFacing: facing,
    mapData: mapData,
    spriteSet: spriteSet,
  );
}
