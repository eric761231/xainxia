import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'iso_coord.dart';
import 'iso_map_data.dart';
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
    this.onStep,
    this.onFace,
    this.spriteSet,
  })  : tileX = initialTileX.clamp(0, mapData.width - 1),
        tileY = initialTileY.clamp(0, mapData.height - 1),
        super(anchor: Anchor.center, size: Vector2.zero());

  final IsoMapData mapData;

  /// 人物 8 向 sprite（null 時回退為 canvas 手繪火柴人）。
  final CharacterSpriteSet? spriteSet;

  /// sprite 動畫組（spriteSet 存在時使用）。
  SpriteAnimationGroupComponent<int>? _group;
  int _currentAnimKey = -1;

  /// 每走一格回呼：(newX, newY, facing)，用於送出 C_MOVE 封包。
  final void Function(int x, int y, int facing)? onStep;

  /// 僅轉向回呼：(facing)，用於送出 C_FACE 封包。
  final void Function(int facing)? onFace;

  int tileX;
  int tileY;
  int facing = 2; // 預設面向 SE

  // ── 目標 tile（點選移動）─────────────────────────────────────
  int? _targetTileX;
  int? _targetTileY;

  // ── 逐格動畫 ──────────────────────────────────────────────
  Vector2 _moveFrom = Vector2.zero();
  Vector2 _moveTo = Vector2.zero();
  double _moveProgress = 1.0; // 1.0 = 停止
  static const _stepDuration = 0.14;

  bool get _isMoving => _moveProgress < 1.0;

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
        // 站位：sprite 底部落在 tile 中心，footOffsetY 微調
        position: Vector2(0, set.footOffsetY),
      );
      _currentAnimKey =
          CharacterSpriteSet.keyFor(moving: false, facing: facing);
      add(_group!);
    }
  }

  void _snapToTile() {
    position = _tileCenter(tileX, tileY);
    _moveFrom = position.clone();
    _moveTo = position.clone();
    _moveProgress = 1.0;
    _targetTileX = null;
    _targetTileY = null;
  }

  Vector2 _tileCenter(int tx, int ty) {
    final sp = IsoCoord.tileToScreen(
        tx, ty, mapData.halfTileWidth, mapData.halfTileHeight);
    return sp + Vector2(0, mapData.halfTileHeight);
  }

  /// 外部呼叫：設定目標 tile，角色開始逐步行走。
  void moveTo(int tx, int ty) {
    final clampedTX = tx.clamp(0, mapData.width - 1);
    final clampedTY = ty.clamp(0, mapData.height - 1);
    if (clampedTX == tileX && clampedTY == tileY) return;
    _targetTileX = clampedTX;
    _targetTileY = clampedTY;
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

  @override
  void update(double dt) {
    _syncAnimation();

    // 動畫進度
    if (_isMoving) {
      _moveProgress = (_moveProgress + dt / _stepDuration).clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom.x + (_moveTo.x - _moveFrom.x) * _moveProgress,
        _moveFrom.y + (_moveTo.y - _moveFrom.y) * _moveProgress,
      );
    }

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
    final newTX = (tileX + dx).clamp(0, mapData.width - 1);
    final newTY = (tileY + dy).clamp(0, mapData.height - 1);

    if (newTX == tileX && newTY == tileY) {
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
    final key = CharacterSpriteSet.keyFor(moving: _isMoving, facing: facing);
    if (key != _currentAnimKey) {
      _currentAnimKey = key;
      group.current = key;
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
    _drawFacingArrow(canvas, r);
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
