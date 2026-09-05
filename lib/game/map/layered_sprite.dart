import 'package:flame/components.dart';

/// 讓多個 [SpriteAnimationGroupComponent] 逐幀播在同一格上。
///
/// ## 為什麼需要它
///
/// 角色要分成「本體 → 外袍 → 髮」三層來畫（換裝時只換外袍那一層）。
/// 但 [SpriteAnimationGroupComponent] 一個實例只播一組動畫，三層就是三個
/// 元件，而**它們各自有自己的 ticker**：建立時間差一點、或某一層在不同
/// 時刻被 `current =` 重設（那會呼叫 `animationTicker?.reset()`），
/// 三層就會播在不同的影格上 —— 畫面上是衣服跟身體對不起來。
///
/// 好消息是 Flame 1.37 的 [SpriteAnimationTicker] 把 `currentIndex`、
/// `clock`、`elapsed` 都開成公開可寫欄位，所以可以直接把「跟隨層」的
/// ticker 對齊到「主導層」，不必自己重寫動畫元件。
///
/// 用法：本體層當 leader，外袍與髮當 follower，每次 `update()` 之後呼叫
/// [syncTo]。
class LayeredSpriteSync {
  const LayeredSpriteSync._();

  /// 把 [followers] 的播放進度對齊到 [leader]。
  ///
  /// **要在 leader 更新過之後才呼叫** —— 對齊的是「這一幀最終的進度」。
  /// 三個欄位都要抄：只抄 `currentIndex` 的話，下一次 `update(dt)` 會從
  /// 各自殘留的 `clock` 繼續累加，隔幾秒又會漂開。
  static void syncTo<T>(
    SpriteAnimationGroupComponent<T> leader,
    Iterable<SpriteAnimationGroupComponent<T>> followers,
  ) {
    final lead = leader.animationTicker;
    if (lead == null) {
      return;
    }
    for (final f in followers) {
      if (f.current != leader.current) {
        // 先讓狀態一致，否則取到的是另一組動畫的 ticker。
        f.current = leader.current;
      }
      final t = f.animationTicker;
      if (t == null) {
        continue;
      }
      t
        ..currentIndex = lead.currentIndex
        ..clock = lead.clock
        ..elapsed = lead.elapsed;
    }
  }
}
