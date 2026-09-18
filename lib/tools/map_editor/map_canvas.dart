import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../game/map/iso_coord.dart';
import '../../game/map/iso_map_data.dart';
import '../../game/map/iso_object_catalog.dart';
import '../../game/map/iso_object_graphic.dart';
import '../../game/map/iso_tile_palette.dart';

/// 編輯模式。
enum EditMode { tile, collision, exit, object, align, pan }

/// 等距地圖編輯畫布。
///
/// - tile：左鍵塗選定 tile、右鍵擦除。
/// - collision：左鍵擋(1)、右鍵可走(0)。
/// - exit：左鍵放/選出口、右鍵移除。
/// - align：左鍵拖曳移動背景圖 origin。
/// - 通用：中鍵拖曳平移、滾輪縮放。被擋格永遠淡紅，出口青色。
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
    this.exits = const [],
    this.selectedExit,
    this.onExitTap,
    this.onExitRemove,
    this.objects = const [],
    this.objectDefs = const {},
    this.objectGraphics = const {},
    this.activeLayer = 1,
    this.selectedObject,
    this.ghostObjectId,
    this.onObjectTap,
    this.onObjectRemove,
    this.onObjectSelect,
    this.background,
    this.originX = 0,
    this.originY = 0,
    this.onOriginDrag,
    this.bgDim = 0,
    this.tileset,
    this.tilesetImage,
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

  final List<MapExit> exits;
  final MapExit? selectedExit;
  final void Function(int tx, int ty)? onExitTap;
  final void Function(int tx, int ty)? onExitRemove;

  /// 布置物件清單與其定義/圖集（供 object 模式預覽與擺放）。
  final List<MapObject> objects;
  final Map<int, ObjectDef> objectDefs;
  final Map<int, ObjectGraphic?> objectGraphics;

  /// 作用中圖層：放置/選取/擦除都針對此層（跨層可同格疊放）。
  final int activeLayer;

  /// 目前選取的物件（腳底格白框高亮）。
  final MapObject? selectedObject;

  /// object 模式下 palette 選定的「待放置」物件 id（供游標 ghost 預覽）；其他模式為 null。
  final int? ghostObjectId;
  final void Function(int tx, int ty)? onObjectTap;
  final void Function(int tx, int ty)? onObjectRemove;

  /// 點到已有物件的格 → 選取（不覆蓋）。
  final void Function(int tx, int ty)? onObjectSelect;

  final ui.Image? background;
  final double originX;
  final double originY;
  final void Function(double dx, double dy)? onOriginDrag;

  /// 背景圖調暗程度（0＝原圖、1＝全黑），讓格線/碰撞在畫面上更清楚。
  final double bgDim;

  /// 地形圖塊集定義與其 sheet 圖；有值時「地形」格改用 sheet 真圖渲染。
  final IsoTileset? tileset;
  final ui.Image? tilesetImage;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  static const double _barSize = 14; // 卷軸粗細

  Offset _camera = const Offset(360, 60);
  double _scale = 0.6;
  Size _viewport = Size.zero; // 由 LayoutBuilder 更新，供卷軸與 gutter 判斷

  bool _leftDown = false;
  bool _rightDown = false;
  bool _panning = false;
  Offset _lastPointer = Offset.zero;

  /// 是否落在左側/下方卷軸溝槽（該處點擊交給卷軸，主畫布不處理）。
  bool _inGutter(Offset p) =>
      p.dx < _barSize || p.dy > _viewport.height - _barSize;

  // hover 提示（物件模式）：停留約 350ms 後顯示座標/檔名 tooltip。
  MapObject? _hoverObject;
  Offset _hoverPos = Offset.zero;
  Timer? _hoverTimer;

  // 游標所在格（object 模式，供待放置 ghost 預覽）。
  (int, int)? _hoverCell;

  // object 模式筆刷：本次拖曳最後處理過的格（避免同格重複蓋章/擦除）。
  (int, int)? _paintedCell;

  bool get _isPaintMode =>
      widget.mode == EditMode.tile || widget.mode == EditMode.collision;

  /// 作用中圖層在該格的物件（放置/選取判斷用；跨層不算占用）。
  MapObject? _objectAt(int tx, int ty) {
    for (final o in widget.objects) {
      if (o.x == tx && o.y == ty && o.layer == widget.activeLayer) return o;
    }
    return null;
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent e) {
    if (widget.mode != EditMode.object) {
      if (_hoverObject != null || _hoverCell != null) {
        setState(() {
          _hoverObject = null;
          _hoverCell = null;
        });
      }
      return;
    }
    final cell = _cellAt(e.localPosition);

    // 游標所在格：換格才重繪（驅動 ghost 預覽跟隨）。
    if (cell?.$1 != _hoverCell?.$1 || cell?.$2 != _hoverCell?.$2) {
      setState(() => _hoverCell = cell);
    }

    final obj = cell == null ? null : _objectAt(cell.$1, cell.$2);
    if (obj == null) {
      _hoverTimer?.cancel();
      if (_hoverObject != null) setState(() => _hoverObject = null);
      return;
    }
    // 換格/換物件才重啟計時；同物件持續 hover 不重複觸發。
    final sameObject = _hoverObject != null &&
        _hoverObject!.x == obj.x &&
        _hoverObject!.y == obj.y;
    _hoverPos = e.localPosition;
    if (sameObject) return;
    _hoverTimer?.cancel();
    setState(() => _hoverObject = null);
    _hoverTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _hoverObject = obj);
    });
  }

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

  /// 單擊行為（tile/collision/exit）。
  void _apply(Offset pos, {required bool left}) {
    final cell = _cellAt(pos);
    if (cell == null) return;
    switch (widget.mode) {
      case EditMode.tile:
        widget.onPaintTile(cell.$1, cell.$2, !left);
        break;
      case EditMode.collision:
        widget.onPaintCollision(cell.$1, cell.$2, left);
        break;
      case EditMode.exit:
        (left ? widget.onExitTap : widget.onExitRemove)?.call(cell.$1, cell.$2);
        break;
      case EditMode.object:
        if (!left) {
          widget.onObjectRemove?.call(cell.$1, cell.$2);
        } else if (_objectAt(cell.$1, cell.$2) != null) {
          // 點到已有物件 → 選取（不覆蓋）。
          widget.onObjectSelect?.call(cell.$1, cell.$2);
        } else {
          widget.onObjectTap?.call(cell.$1, cell.$2);
        }
        break;
      case EditMode.align:
      case EditMode.pan:
        break;
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    // 落在卷軸溝槽的按下交給卷軸處理，主畫布不動作（避免誤塗/誤選）。
    if (_inGutter(e.localPosition)) return;
    // 平移模式：主鍵拖曳即平移整張地圖（等同中鍵）。
    if (widget.mode == EditMode.pan && e.buttons == kPrimaryMouseButton) {
      _panning = true;
      _lastPointer = e.localPosition;
      return;
    }
    if (e.buttons == kMiddleMouseButton) {
      _panning = true;
      _lastPointer = e.localPosition;
    } else if (e.buttons == kSecondaryMouseButton) {
      _rightDown = true;
      _apply(e.localPosition, left: false);
      _paintedCell = _cellAt(e.localPosition);
    } else {
      _leftDown = true;
      _lastPointer = e.localPosition;
      _apply(e.localPosition, left: true);
      _paintedCell = _cellAt(e.localPosition);
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
    } else if (_leftDown && _isPaintMode) {
      _apply(e.localPosition, left: true);
    } else if (_rightDown && _isPaintMode) {
      _apply(e.localPosition, left: false);
    } else if (widget.mode == EditMode.object && (_leftDown || _rightDown)) {
      // 物件筆刷/印章：按住拖曳，換格才觸發（左=連續放置、右=連續擦除）。
      final cell = _cellAt(e.localPosition);
      if (cell != null &&
          (cell.$1 != _paintedCell?.$1 || cell.$2 != _paintedCell?.$2)) {
        if (_leftDown) {
          widget.onObjectTap?.call(cell.$1, cell.$2); // 同格覆蓋＝蓋章
        } else {
          widget.onObjectRemove?.call(cell.$1, cell.$2);
        }
        _paintedCell = cell;
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _leftDown = false;
    _rightDown = false;
    _panning = false;
    _paintedCell = null;
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
    return MouseRegion(
      cursor: widget.mode == EditMode.pan
          ? SystemMouseCursors.grab
          : MouseCursor.defer,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerHover: _onPointerHover,
        onPointerUp: _onPointerUp,
        onPointerSignal: _onPointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewport = Size(constraints.maxWidth, constraints.maxHeight);
            return ColoredBox(
              color: const Color(0xFF1B1B1F),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                painter: _MapPainter(
                  grid: widget.grid,
                  collision: widget.collision,
                  exits: widget.exits,
                  selectedExit: widget.selectedExit,
                  objects: widget.objects,
                  objectDefs: widget.objectDefs,
                  objectGraphics: widget.objectGraphics,
                  selectedObject: widget.selectedObject,
                  hoverObject: _hoverObject,
                  ghostCell: _hoverCell,
                  ghostObjectId: widget.ghostObjectId,
                  width: widget.width,
                  height: widget.height,
                  tileWidth: widget.tileWidth,
                  tileHeight: widget.tileHeight,
                  camera: _camera,
                  scale: _scale,
                  background: widget.background,
                  originX: widget.originX,
                  originY: widget.originY,
                  bgDim: widget.bgDim,
                  tileset: widget.tileset,
                  tilesetImage: widget.tilesetImage,
                  collisionActive: widget.mode == EditMode.collision,
                ),
                      size: Size.infinite,
                    ),
                  ),
                  if (_hoverObject != null) _hoverTooltip(_hoverObject!),
                  ..._scrollbars(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 內容世界邊界（world 座標，與 painter 的 translate(camera).scale(scale) 同系）。
  Rect _contentBounds() {
    final halfW = widget.tileWidth / 2;
    final halfH = widget.tileHeight / 2;
    final w = widget.width, h = widget.height;
    double left = -(h - 1) * halfW - halfW;
    double right = (w - 1) * halfW + halfW;
    double top = 0;
    double bottom = (w - 1 + h - 1) * halfH + 2 * halfH;
    final bg = widget.background;
    if (bg != null) {
      left = math.min(left, widget.originX);
      top = math.min(top, widget.originY);
      right = math.max(right, widget.originX + bg.width);
      bottom = math.max(bottom, widget.originY + bg.height);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 左側（垂直）與下方（水平）卷軸，依 camera/scale 反映可見窗、拖曳捲動地圖。
  List<Widget> _scrollbars() {
    final vw = _viewport.width, vh = _viewport.height;
    if (vw <= 0 || vh <= 0) return const [];
    final c = _contentBounds();
    final visLeft = -_camera.dx / _scale, visW = vw / _scale;
    final visTop = -_camera.dy / _scale, visH = vh / _scale;
    final rangeLeft = math.min(c.left, visLeft);
    final rangeRight = math.max(c.right, visLeft + visW);
    final rangeTop = math.min(c.top, visTop);
    final rangeBottom = math.max(c.bottom, visTop + visH);
    return [
      Positioned(
        left: _barSize,
        right: 0,
        bottom: 0,
        height: _barSize,
        child: _MapScrollbar(
          axis: Axis.horizontal,
          rangeStart: rangeLeft,
          rangeSize: rangeRight - rangeLeft,
          viewStart: visLeft,
          viewSize: visW,
          onScrollTo: (s) =>
              setState(() => _camera = Offset(-s * _scale, _camera.dy)),
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        bottom: _barSize,
        width: _barSize,
        child: _MapScrollbar(
          axis: Axis.vertical,
          rangeStart: rangeTop,
          rangeSize: rangeBottom - rangeTop,
          viewStart: visTop,
          viewSize: visH,
          onScrollTo: (s) =>
              setState(() => _camera = Offset(_camera.dx, -s * _scale)),
        ),
      ),
    ];
  }

  /// hover 資訊框：顯示物件座標、檔名、label（游標右下方）。
  Widget _hoverTooltip(MapObject o) {
    final def = widget.objectDefs[o.id];
    final file = def?.image ?? '(缺定義)';
    final label = (def?.label.isNotEmpty ?? false) ? '　${def!.label}' : '';
    final lines = <String>[
      'id ${o.id}$label',
      '格 (${o.x}, ${o.y})',
      file,
      if (o.offsetX != 0 || o.offsetY != 0)
        'offset (${o.offsetX.toStringAsFixed(0)}, ${o.offsetY.toStringAsFixed(0)})',
    ];
    return Positioned(
      left: _hoverPos.dx + 14,
      top: _hoverPos.dy + 14,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xF01B1B1F),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFFC107), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in lines)
                Text(t,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.grid,
    required this.collision,
    required this.exits,
    required this.selectedExit,
    required this.objects,
    required this.objectDefs,
    required this.objectGraphics,
    required this.selectedObject,
    required this.hoverObject,
    required this.ghostCell,
    required this.ghostObjectId,
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.camera,
    required this.scale,
    required this.background,
    required this.originX,
    required this.originY,
    required this.bgDim,
    required this.tileset,
    required this.tilesetImage,
    required this.collisionActive,
  });

  final List<List<int>> grid;
  final List<List<int>> collision;
  final List<MapExit> exits;
  final MapExit? selectedExit;
  final List<MapObject> objects;
  final Map<int, ObjectDef> objectDefs;
  final Map<int, ObjectGraphic?> objectGraphics;
  final MapObject? selectedObject;
  final MapObject? hoverObject;
  final (int, int)? ghostCell;
  final int? ghostObjectId;
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final Offset camera;
  final double scale;
  final ui.Image? background;
  final double originX;
  final double originY;
  final double bgDim;
  final IsoTileset? tileset;
  final ui.Image? tilesetImage;
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
      if (bgDim > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
              originX, originY, bg.width.toDouble(), bg.height.toDouble()),
          Paint()..color = Color.fromRGBO(0, 0, 0, bgDim.clamp(0, 1)),
        );
      }
    }

    final halfW = tileWidth / 2;
    final halfH = tileHeight / 2;
    final hasBg = bg != null;
    final blockFill = Paint()
      ..color =
          collisionActive ? const Color(0x66FF3B30) : const Color(0x2EFF3B30);

    for (int ty = 0; ty < height; ty++) {
      for (int tx = 0; tx < width; tx++) {
        final id = _at(grid, tx, ty);
        final sp = IsoCoord.tileToScreen(tx, ty, halfW, halfH);
        final path = _diamond(sp.x, sp.y, halfW, halfH);

        final hasSprite = id > 0 && tilesetImage != null && tileset != null;
        if (hasSprite) {
          _drawTileSprite(canvas, id, sp.x, sp.y, halfW, halfH);
          canvas.drawPath(path, _stroke);
        } else if (hasBg) {
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

    _paintObjects(canvas, halfW, halfH);
    _paintGhost(canvas, halfW, halfH);
    _paintExits(canvas, halfW, halfH);
    canvas.restore();
  }

  /// 游標放置預覽：在游標所在「空格」畫待放置物件圖的 30% 半透明 ghost + 落點框。
  void _paintGhost(Canvas canvas, double halfW, double halfH) {
    final cell = ghostCell;
    final id = ghostObjectId;
    if (cell == null || id == null) return;
    // 已有物件的格不畫（該格左鍵是「選取」而非放置）。
    if (objects.any((o) => o.x == cell.$1 && o.y == cell.$2)) return;
    final def = objectDefs[id];
    final g = objectGraphics[id];

    final sp = IsoCoord.tileToScreen(cell.$1, cell.$2, halfW, halfH);
    // 落點格淡框，標示會放在哪一格。
    canvas.drawPath(
      _diamond(sp.x, sp.y, halfW, halfH),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xCC64B5F6),
    );

    if (def == null || g == null) return;
    final footX = sp.x;
    final footY = sp.y + halfH;
    final w = g.width, h = g.height;
    final (ax, ay) = def.resolveAnchor(w, h, mapHalfTileHeight: halfH);
    final s = def.scale;
    // 30% 半透明 ghost（點陣/SVG 皆由 graphic.paint 處理）。
    g.paint(canvas, Rect.fromLTWH(footX - ax * s, footY - ay * s, w * s, h * s),
        opacity: 0.3);
  }

  /// 布置物件：依腳底 (x+y) 由後往前排序後畫，重疊時前方蓋後方（近似遊戲內深度）。
  /// 每個物件腳底格畫半透明彩色填滿；選取/hover 者加強高亮，方便對位。
  void _paintObjects(Canvas canvas, double halfW, double halfH) {
    if (objects.isEmpty) return;
    final sorted = [...objects]
      ..sort((a, b) => a.layer != b.layer
          ? a.layer.compareTo(b.layer)
          : (a.x + a.y).compareTo(b.x + b.y));

    // 先鋪所有腳底格底色（在物件圖之下，才不會被大圖蓋住看不到）。
    for (final o in sorted) {
      final sp = IsoCoord.tileToScreen(o.x, o.y, halfW, halfH);
      canvas.drawPath(
        _diamond(sp.x, sp.y, halfW, halfH),
        Paint()..color = const Color(0x4DFFC107), // 半透明琥珀填滿
      );
    }

    for (final o in sorted) {
      final sp = IsoCoord.tileToScreen(o.x, o.y, halfW, halfH);
      final footX = sp.x;
      final footY = sp.y + halfH; // 腳底＝格中心
      final def = objectDefs[o.id];
      final g = objectGraphics[o.id];
      if (def != null && g != null) {
        final w0 = g.width, h0 = g.height;
        final (ax0, ay0) = def.resolveAnchor(w0, h0, mapHalfTileHeight: halfH);
        final s = (o.tilesW > 0 && w0 > 0 ? o.tilesW * tileWidth / w0 : 1.0) *
            def.scale;
        final w = w0 * s, h = h0 * s, ax = ax0 * s, ay = ay0 * s;
        g.paint(canvas,
            Rect.fromLTWH(footX - ax + o.offsetX, footY - ay + o.offsetY, w, h));
      } else {
        // 缺圖：畫色塊標記 + id，仍可定位/搬移。
        final w = halfW * 1.1;
        final h = halfH * 3.2;
        final rect =
            Rect.fromLTWH(footX - w / 2 + o.offsetX, footY - h + o.offsetY, w, h);
        canvas.drawRect(rect, Paint()..color = const Color(0x9955C36B));
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFF1E5631)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      // 腳底格外框：一般琥珀；hover 加亮；選取中用白色粗框。
      final isSel = selectedObject != null &&
          selectedObject!.x == o.x &&
          selectedObject!.y == o.y;
      final isHover =
          hoverObject != null && hoverObject!.x == o.x && hoverObject!.y == o.y;
      canvas.drawPath(
        _diamond(sp.x, sp.y, halfW, halfH),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2.5 : (isHover ? 2.0 : 1.0)
          ..color = isSel
              ? const Color(0xFFFFFFFF)
              : (isHover ? const Color(0xFFFFE082) : const Color(0xAAFFC107)),
      );
    }
  }

  /// 地形格：從 tileset sheet 取出第 (id-firstId) 格，畫進該格菱形的外接矩形。
  void _drawTileSprite(
      Canvas canvas, int id, double topX, double topY, double halfW, double halfH) {
    final ts = tileset!;
    if (id - ts.firstId < 0) return;
    final src = ts.srcRectForId(id);
    final dst = Rect.fromLTWH(topX - halfW, topY, halfW * 2, halfH * 2);
    canvas.drawImageRect(tilesetImage!, src, dst, Paint());
  }

  void _paintExits(Canvas canvas, double halfW, double halfH) {
    if (exits.isEmpty) return;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final e in exits) {
      final sp = IsoCoord.tileToScreen(e.x, e.y, halfW, halfH);
      final path = _diamond(sp.x, sp.y, halfW, halfH);
      canvas.drawPath(path, Paint()..color = const Color(0x8800E5FF));
      final sel = selectedExit != null &&
          selectedExit!.x == e.x &&
          selectedExit!.y == e.y;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sel ? 2.0 : 1.0
          ..color = sel ? const Color(0xFFFFFFFF) : const Color(0xFF00E5FF),
      );
      tp.text = TextSpan(
        text: '→${e.toMap}',
        style: TextStyle(
          color: Colors.white,
          fontSize: halfH * 0.55,
          fontWeight: FontWeight.bold,
        ),
      );
      tp.layout();
      tp.paint(
          canvas, Offset(sp.x - tp.width / 2, sp.y + halfH - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}

/// 地圖捲軸：thumb 反映可見窗在內容範圍中的位置/比例，拖曳把螢幕位移換算成
/// world 位移回呼 [onScrollTo]（傳回新的可見窗起點世界座標）。
class _MapScrollbar extends StatelessWidget {
  const _MapScrollbar({
    required this.axis,
    required this.rangeStart,
    required this.rangeSize,
    required this.viewStart,
    required this.viewSize,
    required this.onScrollTo,
  });

  final Axis axis;
  final double rangeStart;
  final double rangeSize;
  final double viewStart;
  final double viewSize;
  final void Function(double worldStart) onScrollTo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final horizontal = axis == Axis.horizontal;
        final track = horizontal ? c.maxWidth : c.maxHeight;
        final range = rangeSize <= 0 ? 1.0 : rangeSize;
        final frac = (viewSize / range).clamp(0.05, 1.0);
        final thumb = (track * frac).clamp(18.0, track);
        final maxOffset = track - thumb;
        final scrollable = range - viewSize;
        final startFrac = scrollable <= 0
            ? 0.0
            : ((viewStart - rangeStart) / scrollable).clamp(0.0, 1.0);
        final offset = maxOffset * startFrac;

        void onDrag(double dPix) {
          if (maxOffset <= 0 || scrollable <= 0) return;
          final newStartFrac = (startFrac + dPix / maxOffset).clamp(0.0, 1.0);
          onScrollTo(rangeStart + newStartFrac * scrollable);
        }

        final thumbWidget = Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0x99B9C4CF),
            borderRadius: BorderRadius.circular(6),
          ),
        );

        return GestureDetector(
          onPanUpdate: (d) => onDrag(horizontal ? d.delta.dx : d.delta.dy),
          child: Container(
            color: const Color(0x33000000),
            child: Stack(
              children: [
                Positioned(
                  left: horizontal ? offset : 0,
                  top: horizontal ? 0 : offset,
                  width: horizontal ? thumb : null,
                  height: horizontal ? null : thumb,
                  bottom: horizontal ? 0 : null,
                  right: horizontal ? null : 0,
                  child: thumbWidget,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
