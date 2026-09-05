import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xianxia_game/game/map/scene_asset_loader.dart';

/// 逐 state 的垂直位移是**死亡素材能不能放對位置的前提**，
/// 但它平常不會被執行到 —— 現有的 character_sprites.json 沒有任何 offsetY，
/// 所以編譯過了也不代表行為對。這幾個測試把行為釘住。
///
/// 背景：sprite 是 [Anchor.bottomCenter]，格底會被釘在 tile 中心。站姿沒問題，
/// 但**倒下的身體會往畫面下方長** —— 朝 S/SE/SW 倒下時格底以下就是格外，
/// 畫多少切多少。所以死亡的錨點必須放在格子內部（DrawPng 用 208 高的格、
/// 錨點在 y=138），再由 offsetY 把整張圖往下推回來 208−138 = 70px。
///
/// 原本只有一個 sheet 級的 footOffsetY，那個值一設下去 idle/walk/attack
/// 會**一起下移**。所以位移必須是逐 state 的。
void main() {
  CharacterStateSpec spec(Map<String, dynamic> j) =>
      CharacterStateSpec.fromJson(j);

  test('沒寫 offsetY 時預設 0 —— 既有 sheet 的行為完全不變', () {
    expect(spec({'frameCount': 4}).offsetY, 0.0);
  });

  test('offsetY 讀得到，且吃得下整數與小數', () {
    expect(spec({'offsetY': 70}).offsetY, 70.0);
    expect(spec({'offsetY': -12.5}).offsetY, -12.5);
  });

  test('offsetYFor 疊在 sheet 級的 footOffsetY 之上，而不是取代它', () {
    final set = CharacterSpriteSet(
      animations: const {},
      frameSize: Vector2.zero(),
      stateFrameSizes: const {},
      stateOffsets: const {
        CharacterAnimationState.death: 70.0,
      },
      footOffsetY: 6.0,
      renderScale: 1.0,
    );
    // 死亡：6 + 70
    expect(set.offsetYFor(CharacterAnimationState.death), 76.0);
    // 沒宣告位移的 state 只拿 sheet 級的值 —— 這一條是關鍵：
    // 死亡需要的 +70 不可以外溢到 idle/walk，否則整個角色會下沉。
    expect(set.offsetYFor(CharacterAnimationState.idle), 6.0);
    expect(set.offsetYFor(CharacterAnimationState.walk), 6.0);
  });
}
