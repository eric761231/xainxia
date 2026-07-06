import 'package:flame/components.dart' show Vector2;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../game/map/iso_coord.dart';
import '../../game/map/iso_tile_palette.dart';

/// 等距地圖編輯畫布：左鍵塗選定 tile、右鍵擦除、中鍵平移、滾輪縮放。
///
/// grid 由父層持有；本元件只負責顯示 + 命中格子回呼 [onPaint]。
class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.grid,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.onPaint,
  });

  final List<List<int>> grid;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;

  /// 命中格子回呼：(tx, ty, erase)。erase=true 表示清為 0。
  final void Function(int tx, int ty, bool erase) onPaint;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  Offset _camera = const Offset(320, 80);
  double _scale = 1.0;

  bool _painting = false;
  bool _erasing = false;
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

  void _paintAt(Offset pos, {required bool erase}) {
    final cell = _cellAt(pos);
    if (cell != null) widget.onPaint(cell.$1, cell.$2, erase);
  }

  void _onPointerDown(PointerDownEvent e) {
    if (e.buttons == kMiddleMouseButton) {
      _panning = true;
      _lastPointer = e.localPosition;
    } else if (e.buttons == kSecondaryMouseButton) {
      _erasing = true;
      _paintAt(e.localPosition, erase: true);
    } else {
      _painting = true;
      _paintAt(e.localPosition, erase: false);
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_panning) {
      setState(() => _camera += e.localPosition - _lastPointer);
      _lastPointer = e.localPosition;
    } else if (_erasing) {
      _paintAt(e.localPosition, erase: true);
    } else if (_painting) {
      _paintAt(e.localPosition, erase: false);
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _painting = false;
    _erasing = false;
    _panning = false;
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      setState(() {
        final factor = e.scrollDelta.dy > 0 ? 0.9 : 1.1;
        final focal = e.localPosition;
        final before = (focal - _camera) / _scale;
        _scale = (_scale * factor).clamp(0.25, 4.0);
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
            width: widget.width,
            height: widget.height,
            tileWidth: widget.tileWidth,
            tileHeight: widget.tileHeight,
            camera: _camera,
            scale: _scale,
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
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.camera,
    required this.scale,
  });

  final List<List<int>> grid;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final Offset camera;
  final double scale;

  static final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7
    ..color = const Color(0x55FFFFFF);
  static final _emptyStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..color = const Color(0x22FFFFFF);

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

    final halfW = tileWidth / 2;
    final halfH = tileHeight / 2;

    for (int ty = 0; ty < height; ty++) {
      for (int tx = 0; tx < width; tx++) {
        final id = ty < grid.length && tx < grid[ty].length ? grid[ty][tx] : 0;
        final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);
        final path = _diamond(sp.x, sp.y, halfW, halfH);
        if (id <= 0) {
          canvas.drawPath(path, _emptyStroke);
        } else {
          canvas.drawPath(path, Paint()..color = IsoTilePalette.colorFor(id));
          canvas.drawPath(path, _stroke);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
