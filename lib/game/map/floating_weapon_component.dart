import 'dart:math' as math;

import 'package:flame/components.dart';

import 'scene_asset_loader.dart';

/// 目前可在角色本體外獨立顯示的武器外觀。
///
/// 這不是戰鬥武器資料；後端裝備欄位接入前，它只決定前端測試用的視覺層。
/// `none` 是目前的預設：靈珠的圖把**透明棋盤畫進了像素**
/// （外圍白方塊 alpha 200~255，只有最外框是透明），漂浮定位也還沒對，
/// 所以先不讓它出現。素材修好、定位驗過之後再改回 pearl。
enum WeaponVisual { none, pearl, flyingSword }

/// 靈珠的八向定位與 idle/walk 動作。
///
/// 圖片只負責主珠與內部流紋；所有漂浮、繞行與前後層級都在這個 component
/// 執行。因此不需要把珠子、人物或接地陰影預先合成，也不需要畫八張珠圖。
class FloatingPearlComponent extends SpriteAnimationComponent {
  FloatingPearlComponent({
    required this.facingProvider,
    required this.isMovingProvider,
  }) : super(anchor: Anchor.center, size: Vector2.all(40), priority: 1);

  static const assetPath = 'pearl_01_flow.png';
  static const frameCount = 6;
  static const frameSize = 128.0;
  static const flowStepTime = .14;

  /// 對應人物 facing：NE, E, SE, S, SW, W, NW, N。
  /// 所有值都是相對人物腳底 `(0, 0)` 的螢幕 px 位移。
  static const _homeOffsets = <List<double>>[
    [22, -50], // NE
    [28, -42], // E
    [24, -34], // SE
    [18, -32], // S
    [-18, -32], // SW
    [-26, -42], // W
    [-22, -50], // NW
    [-16, -56], // N
  ];

  final int Function() facingProvider;
  final bool Function() isMovingProvider;

  double _elapsed = 0;

  /// 供測試與後續 catalog 匯入使用；呼叫端可安全傳入任何 int。
  static Vector2 homeOffsetFor(int facing) {
    final offset = _homeOffsets[facing.clamp(0, _homeOffsets.length - 1)];
    return Vector2(offset[0], offset[1]);
  }

  @override
  Future<void> onLoad() async {
    final image = await SceneAssetLoader.loadWeaponImage(assetPath);
    if (image != null) {
      animation = SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: frameCount,
          stepTime: flowStepTime,
          textureSize: Vector2.all(frameSize),
        ),
      );
    }
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final home = homeOffsetFor(facingProvider());
    final walking = isMovingProvider();
    if (walking) {
      // Walk 不繞圈：保持同一側，只在垂直方向有很小的呼吸感。
      position = home + Vector2(0, math.sin(_elapsed * math.pi * 2 / .42) * 2);
    } else {
      // Idle 僅在人物同側的小橢圓安全帶內移動，不跨過腳底中心線。
      position =
          home +
          Vector2(
            math.sin(_elapsed * math.pi * 2 / 1.6) * 6,
            math.cos(_elapsed * math.pi * 2 / 1.6) * 2,
          );
    }

    // 軌道位於人物軀幹上方時放在人物後；較低的半圈放在人物前。
    // group 的預設 priority 為 0，這個相對 priority 不影響世界碰撞或深度。
    priority = position.y < -42 ? -1 : 1;
  }
}
