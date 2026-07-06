import 'dart:ui' as ui;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../game/map/iso_coord.dart';
import '../../game/map/iso_tile_palette.dart';

/// 編輯模式。
enum EditMode { tile, collision, align }

/// 等距地圖編輯畫布。
///
/// - tile：左鍵塗選定 tile、右鍵擦除。
/// - collision：左鍵擋(1)、右鍵可走(0)。
/// - align：左鍵拖曳移動背景圖 origin。
/// - 通用：中鍵拖曳平移、滾輪縮放。被擋格永遠畫半透明紅（碰撞模式較亮）。
class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.grid,
    required this.collision,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.mode,
    required this.onPaintTile,
    required this.onPaintCollision,
    this.background,
    this.originX = 0,
    this.originY = 0,
    this.onOriginDrag,
  });

  final List<List<int>> grid;
  final List<List<int>> collision;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final EditMode mode;

  final void Function(int tx, int ty, bool erase) onPaintTile;
  final void Function(int tx, int ty, bool block) onPaintCollision;

  final ui.Image? background;
  final double originX;
  final double originY;
  final void Function(double dx, double dy)? onOriginDrag;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  Offset _camera = const Offset(360, 60);
  double _scale = 0.6;

  bool _leftDown = false;
  bool _rightDown = false;
  bool _panning = false;
  Offset _lastPointer = Offset.zero;

  (int, int)? _cellAt(Offset localPos) {
    final halfW = widget.tileWidth / 2;
    final halfH = widget.tileHeight / 2;
    final world = (localPos - _camera) / _scale;
    final (tx, ty) =
        IsoCoord.screenToTile(Vector2(world.dx, world.dy), halfW, halfH);
    if (tx < 0 || tx >= widget.width || ty < 0 || ty >= widget.height) {
      return null;
    }
    return (tx, ty);
  }

  void _apply(Offset pos, {required bool left}) {
    switch (widget.mode) {
      case EditMode.tile:
        final cell = _cellAt(pos);
        if (cell != null) widget.onPaintTile(cell.$1, cell.$2, !left);
        break;
      case EditMode.collision:
        final cell = _cellAt(pos);
        if (cell != null) widget.onPaintCollision(cell.$1, cell.$2, left);
        break;
      case EditMode.align:
        break; // align 用拖曳處理
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    if (e.buttons == kMiddleMouseButton) {
      _panning = true;
      _lastPointer = e.localPosition;
    } else if (e.buttons == kSecondaryMouseButton) {
      _rightDown = true;
      _apply(e.localPosition, left: false);
    } else {
      _leftDown = true;
      _lastPointer = e.localPosition;
      _apply(e.localPosition, left: true);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_panning) {
      setState(() => _camera += e.localPosition - _lastPointer);
      _lastPointer = e.localPosition;
    } else if (_leftDown && widget.mode == EditMode.align) {
      final d = (e.localPosition - _lastPointer) / _scale;
      widget.onOriginDrag?.call(d.dx, d.dy);
      _lastPointer = e.localPosition;
    } else if (_leftDown) {
      _apply(e.localPosition, left: true);
    } else if (_rightDown) {
      _apply(e.localPosition, left: false);
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _leftDown = false;
    _rightDown = false;
    _panning = false;
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      setState(() {
        final factor = e.scrollDelta.dy > 0 ? 0.9 : 1.1;
        final focal = e.localPosition;
        final before = (focal - _camera) / _scale;
        _scale = (_scale * factor).clamp(0.1, 4.0);
        _camera = focal - before * _scale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: ColoredBox(
        color: const Color(0xFF1B1B1F),
        child: CustomPaint(
          painter: _MapPainter(
            grid: widget.grid,
            collision: widget.collision,
            width: widget.width,
            height: widget.height,
            tileWidth: widget.tileWidth,
            tileHeight: widget.tileHeight,
            camera: _camera,
            scale: _scale,
            background: widget.background,
            originX: widget.originX,
            originY: widget.originY,
            collisionActive: widget.mode == EditMode.collision,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.grid,
    required this.collision,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.camera,
    required this.scale,
    required this.background,
    required this.originX,
    required this.originY,
    required this.collisionActive,
  });

  final List<List<int>> grid;
  final List<List<int>> collision;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final Offset camera;
  final double scale;
  final ui.Image? background;
  final double originX;
  final double originY;
  final bool collisionActive;

  static final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = const Color(0xAAFFD54F);
  static final _emptyStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..color = const Color(0x33FFFFFF);

  int _at(List<List<int>> g, int tx, int ty) =>
      ty < g.length && tx < g[ty].length ? g[ty][tx] : 0;

  Path _diamond(double topX, double topY, double halfW, double halfH) => Path()
    ..moveTo(topX, topY)
    ..lineTo(topX + halfW, topY + halfH)
    ..lineTo(topX, topY + halfH * 2)
    ..lineTo(topX - halfW, topY + halfH)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(camera.dx, camera.dy);
    canvas.scale(scale);

    final bg = background;
    if (bg != null) {
      canvas.drawImage(bg, Offset(originX, originY), Paint());
    }

    final halfW = tileWidth / 2;
    final halfH = tileHeight / 2;
    final hasBg = bg != null;
    final blockFill = Paint()
      ..color = collisionActive ? const Color(0x66FF3B30) : const Color(0x2EFF3B30);

    for (int ty = 0; ty < height; ty++) {
      for (int tx = 0; tx < width; tx++) {
        final id = _at(grid, tx, ty);
        final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);
        final path = _diamond(sp.x, sp.y, halfW, halfH);

        if (hasBg) {
          canvas.drawPath(path, id > 0 ? _stroke : _emptyStroke);
        } else if (id <= 0) {
          canvas.drawPath(path, _emptyStroke);
        } else {
          canvas.drawPath(path, Paint()..color = IsoTilePalette.colorFor(id));
          canvas.drawPath(path, _stroke);
        }

        if (_at(collision, tx, ty) == 1) {
          canvas.drawPath(path, blockFill);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
