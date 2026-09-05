import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'iso_coord.dart';
import 'iso_map_data.dart';
import 'iso_object_component.dart';
import 'scene_asset_loader.dart';

/// 面向定義（0-7，對應畫面方向順時針）：
/// 0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N
///
/// Tile 位移 → facing：
///   dy-1        → 0 (NE)
///   dx+1, dy-1  → 1 (E)
///   dx+1        → 2 (SE)
///   dx+1, dy+1  → 3 (S)
///   dy+1        → 4 (SW)
///   dx-1, dy+1  → 5 (W)
///   dx-1        → 6 (NW)
///   dx-1, dy-1  → 7 (N)
class IsoPlayerComponent extends PositionComponent {
  IsoPlayerComponent({
    required int initialTileX,
    required int initialTileY,
    required this.mapData,
    int initialFacing = 2,
    this.onStep,
    this.onFace,
    this.spriteSet,
  })  : tileX = initialTileX.clamp(mapData.minMapCoord, mapData.maxMapCoordX),
        tileY = initialTileY.clamp(mapData.minMapCoord, mapData.maxMapCoordY),
        facing = initialFacing.clamp(0, 7),
        super(anchor: Anchor.center, size: Vector2.zero());

  final IsoMapData mapData;

  /// 人物 8 向 sprite（null 時回退為 canvas 手繪火柴人）。
  final CharacterSpriteSet? spriteSet;

  /// sprite 動畫組（spriteSet 存在時使用）。
  SpriteAnimationGroupComponent<int>? _group;
  int _currentAnimKey = -1;
  CharacterAnimationState? _transientState;
  double _transientRemaining = 0;
  bool _dead = false;
  FloatingSwordComponent? _flyingSword;

  /// 每走一格回呼：(newX, newY, facing)，用於送出 C_MOVE 封包。
  final void Function(int x, int y, int facing)? onStep;

  /// 僅轉向回呼：(facing)，用於送出 C_FACE 封包。
  final void Function(int facing)? onFace;

  int tileX;
  int tileY;
  int facing; // 面向 0-7（預設 2=SE，由 initialFacing 設定）

  // ── 目標 tile（點選移動）─────────────────────────────────────
  int? _targetTileX;
  int? _targetTileY;

  // ── 逐格動畫 ──────────────────────────────────────────────
  Vector2 _moveFrom = Vector2.zero();
  Vector2 _moveTo = Vector2.zero();
  double _moveProgress = 1.0; // 1.0 = 停止
  static const _stepDuration = 0.14;

  bool get _isMoving => _moveProgress < 1.0;

  /// 是否正在移動動畫中。
  bool get isMoving => _isMoving;
  bool get isDead => _dead;

  /// 是否還有待走的目標格。
  bool get hasTarget => _targetTileX != null;

  /// 停止且無待走目標（供互動框架判斷「已走到定位」）。
  bool get isIdle => !_isMoving && _targetTileX == null;

  @override
  Future<void> onLoad() async {
    _snapToTile();

    final set = spriteSet;
    if (set != null) {
      final size = set.frameSize * set.renderScale;
      _group = SpriteAnimationGroupComponent<int>(
        animations: set.animations,
        current: CharacterSpriteSet.keyFor(moving: false, facing: facing),
        size: size,
        anchor: Anchor.bottomCenter,
        // 站位：sprite 底部落在 tile 中心，footOffsetY 微調。
        // 位移是**逐 state** 的（見 offsetYFor）—— 倒下的身體會往畫面下方長，
        // 死亡的錨點必須放在格子內部，再由這裡推回來。
        position: Vector2(0, set.offsetYFor(CharacterAnimationState.idle)),
      );
      _currentAnimKey =
          CharacterSpriteSet.keyFor(moving: false, facing: facing);
      add(_group!);
      _flyingSword = FloatingSwordComponent(
        facingProvider: () => facing,
        halfTileWidth: mapData.halfTileWidth,
        halfTileHeight: mapData.halfTileHeight,
      );
      add(_flyingSword!);
    }
  }

  /// 伺服器確認的攻擊演出。缺 action 圖時安全回退為原本 idle/walk。
  void playAttack() {
    if (_dead || spriteSet?.has(CharacterAnimationState.attack) != true) return;
    _transientState = CharacterAnimationState.attack;
    _transientRemaining = 0.72;
    _flyingSword?.attack();
  }

  void playHurt() {
    if (_dead || spriteSet?.has(CharacterAnimationState.hurt) != true) return;
    _transientState = CharacterAnimationState.hurt;
    _transientRemaining = 0.36;
  }

  /// 死亡永久鎖在最後一格，直到地圖／重生流程移除或重建元件。
  void playDeath() {
    if (_dead) return;
    _dead = true;
    _targetTileX = null;
    _targetTileY = null;
    _moveProgress = 1.0;
    _transientState = CharacterAnimationState.death;
    _flyingSword?.drop();
  }

  void _snapToTile() {
    position = _tileCenter(tileX, tileY);
    priority = mapData.characterLayer * kLayerStride + position.y.round();
    _moveFrom = position.clone();
    _moveTo = position.clone();
    _moveProgress = 1.0;
    _targetTileX = null;
    _targetTileY = null;
  }

  /// 地圖座標 → 該格中心的 local 螢幕座標。
  ///
  /// 投影一律在<b>陣列索引空間</b>進行（座標先減 coordOffset），
  /// 這樣不論伺服器的地圖邊界從 1 還是 31 開始，菱形都畫在同一個位置，
  /// 不必連動調整 hitbox 與底圖原點。
  Vector2 _tileCenter(int tx, int ty) {
    final sp = IsoCoord.tileToScreen(mapData.toIndex(tx), mapData.toIndex(ty),
        mapData.halfTileWidth, mapData.halfTileHeight);
    return sp + Vector2(0, mapData.halfTileHeight);
  }

  /// 外部呼叫：設定目標 tile，角色開始逐步行走。
  void moveTo(int tx, int ty) {
    if (_dead) return;
    final clampedTX = tx.clamp(mapData.minMapCoord, mapData.maxMapCoordX);
    final clampedTY = ty.clamp(mapData.minMapCoord, mapData.maxMapCoordY);
    if (clampedTX == tileX && clampedTY == tileY) return;
    _targetTileX = clampedTX;
    _targetTileY = clampedTY;
  }

  /// 外部呼叫：無視動畫與碰撞，直接把角色瞬移到指定格。
  ///
  /// 用於伺服器的移動修正 —— 前端是「先本地走再送 C_MOVE」，伺服器若判定
  /// 該步非法會回送正確座標，此時必須硬拉回去，否則兩邊會永久不同步。
  /// 刻意不觸發 [onStep]，避免修正又送出一次 C_MOVE 形成迴圈。
  void snapTo(int tx, int ty, {int? facing}) {
    tileX = tx.clamp(mapData.minMapCoord, mapData.maxMapCoordX);
    tileY = ty.clamp(mapData.minMapCoord, mapData.maxMapCoordY);
    if (facing != null) {
      this.facing = facing.clamp(0, 7);
    }
    _snapToTile();
    _dead = false;
    _transientState = null;
    _flyingSword?.reset();
    _syncAnimation();
  }

  /// 外部呼叫：僅轉向，不移動，並觸發 [onFace] 回呼送出 C_FACE 封包。
  void setFacing(int newFacing) {
    final f = newFacing.clamp(0, 7);
    if (f == facing) return;
    facing = f;
    onFace?.call(f);
  }

  /// facing 計算工具（tile 位移 → facing 值）。
  static int facingFromDelta(int dx, int dy) => _facingFromDelta(dx, dy);

  /// 這一格能不能走進去。
  ///
  /// 抽成方法是為了讓遠端玩家覆寫 —— 別人的移動已經由伺服器驗過，
  /// 本地碰撞圖只是自己的預測，拿它去擋別人只會讓對方卡在錯的格子上。
  bool canEnter(int tx, int ty) => !mapData.isBlocked(tx, ty);

  /// 是否畫出面向箭頭。箭頭是「這是我」的提示，遠端玩家不需要。
  bool get showsFacingArrow => true;

  @override
  void update(double dt) {
    if (!_dead && _transientState != null) {
      _transientRemaining -= dt;
      if (_transientRemaining <= 0) _transientState = null;
    }
    _syncAnimation();

    // 動畫進度
    if (_isMoving) {
      _moveProgress = (_moveProgress + dt / _stepDuration).clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom.x + (_moveTo.x - _moveFrom.x) * _moveProgress,
        _moveFrom.y + (_moveTo.y - _moveFrom.y) * _moveProgress,
      );
    }

    // 深度排序：characterLayer 分層 + 腳底(position.y)，與物件（IsoObjectComponent）同一
    // 基準，讓 Flame 自動決定玩家在物件前或後（樹在屋後、花在門前）。
    priority = mapData.characterLayer * kLayerStride + position.y.round();

    // 動畫到 85% 才踏下一步（流暢連走）
    if (_moveProgress < 0.85) return;

    final tx = _targetTileX;
    final ty = _targetTileY;
    if (tx == null || ty == null) return;
    if (tx == tileX && ty == tileY) {
      _targetTileX = null;
      _targetTileY = null;
      return;
    }

    // 計算下一步方向
    final dx = (tx - tileX).clamp(-1, 1);
    final dy = (ty - tileY).clamp(-1, 1);
    final newTX = (tileX + dx).clamp(mapData.minMapCoord, mapData.maxMapCoordX);
    final newTY = (tileY + dy).clamp(mapData.minMapCoord, mapData.maxMapCoordY);

    if (newTX == tileX && newTY == tileY) {
      _targetTileX = null;
      _targetTileY = null;
      return;
    }

    // 碰撞：下一格被擋則停在原地
    if (!canEnter(newTX, newTY)) {
      _targetTileX = null;
      _targetTileY = null;
      return;
    }

    // 更新面向
    facing = _facingFromDelta(dx, dy);

    // 啟動動畫
    _moveFrom = _tileCenter(tileX, tileY);
    _moveTo = _tileCenter(newTX, newTY);
    _moveProgress = 0;
    tileX = newTX;
    tileY = newTY;

    // 送出移動封包
    onStep?.call(tileX, tileY, facing);
  }

  /// 依「是否移動 + 面向」切換 sprite 動畫（僅在有 spriteSet 時）。
  void _syncAnimation() {
    final group = _group;
    if (group == null) return;
    var state = _dead
        ? CharacterAnimationState.death
        : (_transientState ??
            (_isMoving ? CharacterAnimationState.walk : CharacterAnimationState.idle));
    if (!spriteSet!.has(state)) {
      state = _isMoving ? CharacterAnimationState.walk : CharacterAnimationState.idle;
    }
    final key = CharacterSpriteSet.keyFor(state: state, facing: facing);
    if (key != _currentAnimKey) {
      _currentAnimKey = key;
      group.current = key;
      // death 等橫向 frame 不可壓回站姿的 64px 寬；bottomCenter anchor
      // 保持不變，所以腳底／倒地接地點仍對齊同一個 tile 中心。
      group.size = spriteSet!.frameSizeFor(state) * spriteSet!.renderScale;
      // 垂直位移也要跟著換。死亡的格子比站姿高、錨點在格內（不在格底），
      // 沒有這一行的話整具屍體會浮在正確位置上方 offsetY 那麼多。
      group.position = Vector2(0, spriteSet!.offsetYFor(state));
    }
  }

  // ── 渲染 ──────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    // 有 sprite 時只畫地面陰影，人物由 SpriteAnimationGroupComponent 子元件繪製。
    if (_group != null) {
      final rs = mapData.halfTileWidth * 0.30;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 2), width: rs * 2.4, height: rs * 0.85),
        Paint()..color = const Color(0x55000000),
      );
      return;
    }

    final r = mapData.halfTileWidth * 0.30;

    // 地面陰影
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 2), width: r * 2.4, height: r * 0.85),
      Paint()..color = const Color(0x55000000),
    );

    // 下半身（腳部）
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -r * 0.5), width: r * 1.4, height: r),
      Paint()..color = const Color(0xFFB05C20),
    );

    // 上半身
    canvas.drawCircle(
      Offset(0, -r * 2.0),
      r * 0.95,
      Paint()..color = const Color(0xFFE8A020),
    );
    canvas.drawCircle(
      Offset(0, -r * 2.0),
      r * 0.95,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 頭部
    canvas.drawCircle(
      Offset(0, -r * 3.4),
      r * 0.65,
      Paint()..color = const Color(0xFFF5C887),
    );
    canvas.drawCircle(
      Offset(0, -r * 3.4),
      r * 0.65,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 面向指示箭頭（畫在腳部）
    if (showsFacingArrow) {
      _drawFacingArrow(canvas, r);
    }
  }

  void _drawFacingArrow(Canvas canvas, double r) {
    final angle = _facingAngle(facing, mapData.halfTileWidth, mapData.halfTileHeight);
    final arrowLen = r * 1.3;
    final dx = math.cos(angle) * arrowLen;
    final dy = math.sin(angle) * arrowLen;

    final tip = Offset(dx, dy);
    final base = Offset(-math.cos(angle) * r * 0.3, -math.sin(angle) * r * 0.3);
    final perp = Offset(-math.sin(angle) * r * 0.35, math.cos(angle) * r * 0.35);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
      ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
      ..close();

    canvas.drawPath(
        path, Paint()..color = const Color(0xFFFFFFCC));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xAA000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  // ── 靜態工具 ──────────────────────────────────────────────

  static int _facingFromDelta(int dx, int dy) {
    if (dx == 0 && dy == -1) return 0;
    if (dx == 1 && dy == -1) return 1;
    if (dx == 1 && dy == 0) return 2;
    if (dx == 1 && dy == 1) return 3;
    if (dx == 0 && dy == 1) return 4;
    if (dx == -1 && dy == 1) return 5;
    if (dx == -1 && dy == 0) return 6;
    if (dx == -1 && dy == -1) return 7;
    return 2;
  }

  /// facing → 畫面角度（弧度，0=右，順時針增加）。
  static double _facingAngle(int f, double halfW, double halfH) {
    const deltas = [
      (0, -1), (1, -1), (1, 0), (1, 1),
      (0, 1), (-1, 1), (-1, 0), (-1, -1),
    ];
    final (ddx, ddy) = deltas[f.clamp(0, 7)];
    final sx = (ddx - ddy) * halfW;
    final sy = (ddx + ddy) * halfH;
    return math.atan2(sy, sx);
  }
}

/// 獨立於人物本體的浮游飛劍層。它不參與碰撞；死亡時落到目前面向的前方。
class FloatingSwordComponent extends PositionComponent {
  FloatingSwordComponent({
    required this.facingProvider,
    required this.halfTileWidth,
    required this.halfTileHeight,
  }) : super(anchor: Anchor.center, size: Vector2(32, 32));

  final int Function() facingProvider;
  final double halfTileWidth;
  final double halfTileHeight;
  double _attack = 0;
  double _drop = -1;

  void attack() { _attack = 0.72; }
  void drop() { _drop = 0; _attack = 0; }
  void reset() { _attack = 0; _drop = -1; }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attack > 0) _attack = math.max(0, _attack - dt);
    if (_drop >= 0) _drop = math.min(1, _drop + dt / 0.72);
    final f = facingProvider();
    const dx = [0, 1, 1, 1, 0, -1, -1, -1];
    const dy = [-1, -1, 0, 1, 1, 1, 0, -1];
    final sx = (dx[f] - dy[f]) * halfTileWidth;
    final sy = (dx[f] + dy[f]) * halfTileHeight;
    if (_drop >= 0) {
      position = Vector2(sx * .46, sy * .46 + 8 * _drop);
    } else if (_attack > 0) {
      final p = math.sin((1 - _attack / .72) * math.pi);
      position = Vector2(sx * (.25 + .55 * p), sy * (.25 + .55 * p) - 16 * (1 - p));
    } else {
      position = Vector2(18, -40 + math.sin(DateTime.now().millisecondsSinceEpoch / 300) * 2);
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE7F3FF);
    canvas.save();
    canvas.rotate(_drop >= 0 ? .55 : -.45);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -14, 4, 22), const Radius.circular(2)), paint);
    canvas.drawCircle(const Offset(0, 9), 3, Paint()..color = const Color(0xFF5FC7E8));
    canvas.restore();
  }
}
