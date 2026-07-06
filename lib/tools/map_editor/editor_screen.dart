import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../game/map/iso_map_data.dart';
import '../../game/map/iso_map_loader.dart';
import '../../game/map/iso_tile_palette.dart';
import 'map_canvas.dart';

/// 地圖編輯器主畫面：載入 → 塗地形／刷碰撞／設出口／對齊背景 → 存回 assets/maps/{id}.json。
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int _mapId = 1;
  int _selectedTile = 1; // 0 = 橡皮擦
  bool _loading = true;
  EditMode _mode = EditMode.collision;

  // 地圖 meta + 可變格子
  String _name = '';
  int _width = 16;
  int _height = 16;
  int _tileWidth = 64;
  int _tileHeight = 32;
  List<IsoTileset> _tilesets = const [];
  late List<List<int>> _grid;
  late List<List<int>> _collision;
  List<MapExit> _exits = [];
  MapExit? _selectedExit;

  // 背景圖
  String _background = '';
  double _originX = 0;
  double _originY = 0;
  ui.Image? _bg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await IsoMapLoader.load(_mapId);

    IsoTileLayer? tileLayer;
    for (final l in data.layers) {
      if (l.type == 'tiles') {
        tileLayer = l;
        break;
      }
    }
    tileLayer ??= data.layers.isNotEmpty ? data.layers.first : null;
    final coll = data.collisionLayer;

    _name = data.name;
    _width = data.width > 0 ? data.width : 16;
    _height = data.height > 0 ? data.height : 16;
    _tileWidth = data.tileWidth;
    _tileHeight = data.tileHeight;
    _tilesets = data.tilesets;
    _background = data.background;
    _originX = data.originX;
    _originY = data.originY;
    _exits = List.of(data.exits);
    _selectedExit = null;
    _grid = List.generate(_height,
        (y) => List.generate(_width, (x) => tileLayer?.tileAt(x, y) ?? 0));
    _collision = List.generate(_height,
        (y) => List.generate(_width, (x) => coll?.tileAt(x, y) ?? 0));
    _bg = _background.isEmpty
        ? null
        : await _loadImage('assets/tiles/$_background');
    if (mounted) setState(() => _loading = false);
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (e) {
      _toast('背景圖載入失敗：$assetPath（$e）');
      return null;
    }
  }

  void _paintTile(int tx, int ty, bool erase) {
    final id = erase ? 0 : _selectedTile;
    if (_grid[ty][tx] == id) return;
    setState(() => _grid[ty][tx] = id);
  }

  void _paintCollision(int tx, int ty, bool block) {
    final v = block ? 1 : 0;
    if (_collision[ty][tx] == v) return;
    setState(() => _collision[ty][tx] = v);
  }

  void _exitTap(int tx, int ty) {
    final existing = _exits.indexWhere((e) => e.x == tx && e.y == ty);
    setState(() {
      if (existing >= 0) {
        _selectedExit = _exits[existing];
      } else {
        final e = MapExit(x: tx, y: ty, toMap: 0, toX: 0, toY: 0);
        _exits.add(e);
        _selectedExit = e;
      }
    });
  }

  void _exitRemove(int tx, int ty) {
    setState(() {
      _exits.removeWhere((e) => e.x == tx && e.y == ty);
      if (_selectedExit != null &&
          _selectedExit!.x == tx &&
          _selectedExit!.y == ty) {
        _selectedExit = null;
      }
    });
  }

  void _updateSelectedExit({int? toMap, int? toX, int? toY}) {
    final e = _selectedExit;
    if (e == null) return;
    final i = _exits.indexWhere((x) => x.x == e.x && x.y == e.y);
    if (i < 0) return;
    final ne = e.copyWith(toMap: toMap, toX: toX, toY: toY);
    setState(() {
      _exits[i] = ne;
      _selectedExit = ne;
    });
  }

  void _nudgeOrigin(double dx, double dy) => setState(() {
        _originX += dx;
        _originY += dy;
      });

  List<List<int>> _resized(List<List<int>> g, int w, int h) => List.generate(h,
      (y) => List.generate(
          w, (x) => (y < g.length && x < g[y].length) ? g[y][x] : 0));

  void _resize(int w, int h) {
    if (w < 1) w = 1;
    if (h < 1) h = 1;
    setState(() {
      _grid = _resized(_grid, w, h);
      _collision = _resized(_collision, w, h);
      _width = w;
      _height = h;
    });
  }

  Future<void> _save() async {
    final map = IsoMapData(
      id: '$_mapId',
      name: _name,
      width: _width,
      height: _height,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      tilesets: _tilesets,
      layers: [
        IsoTileLayer(name: 'ground', data: _grid),
        IsoTileLayer(name: 'collision', type: 'collision', data: _collision),
      ],
      background: _background,
      originX: _originX,
      originY: _originY,
      exits: _exits,
    );
    final jsonStr = const JsonEncoder.withIndent('  ').convert(map.toJson());
    final file = File('assets/maps/$_mapId.json');
    try {
      await file.writeAsString('$jsonStr\n');
      _toast('已存檔：${file.absolute.path}');
    } catch (e) {
      _toast('存檔失敗：$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('地圖編輯器　map $_mapId　$_name　($_width×$_height)'),
        actions: [
          _modeSelector(),
          const SizedBox(width: 12),
          _mapIdField(),
          IconButton(
            tooltip: '重新載入',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.folder_open),
          ),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('存檔'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (_mode == EditMode.tile) _palette(),
                if (_mode == EditMode.tile) const VerticalDivider(width: 1),
                Expanded(
                  child: MapCanvas(
                    grid: _grid,
                    collision: _collision,
                    exits: _exits,
                    selectedExit: _selectedExit,
                    width: _width,
                    height: _height,
                    tileWidth: _tileWidth,
                    tileHeight: _tileHeight,
                    mode: _mode,
                    onPaintTile: _paintTile,
                    onPaintCollision: _paintCollision,
                    onExitTap: _exitTap,
                    onExitRemove: _exitRemove,
                    background: _bg,
                    originX: _originX,
                    originY: _originY,
                    onOriginDrag: _nudgeOrigin,
                  ),
                ),
                const VerticalDivider(width: 1),
                _settingsPanel(),
              ],
            ),
      bottomNavigationBar: _HelpBar(mode: _mode),
    );
  }

  Widget _modeSelector() {
    return SegmentedButton<EditMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: EditMode.tile, icon: Icon(Icons.grid_on)),
        ButtonSegment(value: EditMode.collision, icon: Icon(Icons.block)),
        ButtonSegment(value: EditMode.exit, icon: Icon(Icons.meeting_room)),
        ButtonSegment(value: EditMode.align, icon: Icon(Icons.open_with)),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    );
  }

  Widget _mapIdField() {
    return SizedBox(
      width: 72,
      child: TextField(
        decoration: const InputDecoration(labelText: 'map id', isDense: true),
        keyboardType: TextInputType.number,
        controller: TextEditingController(text: '$_mapId'),
        onSubmitted: (v) {
          final id = int.tryParse(v);
          if (id != null) {
            _mapId = id;
            _load();
          }
        },
      ),
    );
  }

  Widget _palette() {
    return Container(
      width: 88,
      color: const Color(0xFF26262B),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _paletteItem(0, '橡皮擦', const Color(0xFF3A3A40)),
          const Divider(),
          for (final id in IsoTilePalette.tileIds)
            _paletteItem(id, '$id', IsoTilePalette.colorFor(id)),
        ],
      ),
    );
  }

  Widget _paletteItem(int id, String label, Color color) {
    final selected = _selectedTile == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTile = id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _settingsPanel() {
    return Container(
      width: 220,
      color: const Color(0xFF26262B),
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          if (_mode == EditMode.exit) ...[
            const Text('出口設定', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (_selectedExit == null)
              const Text('點格子新增/選取出口\n右鍵移除',
                  style: TextStyle(color: Colors.white70, fontSize: 12))
            else ...[
              Text('出口格 (${_selectedExit!.x}, ${_selectedExit!.y})'),
              _intField('目標地圖 toMap', _selectedExit!.toMap,
                  (v) => _updateSelectedExit(toMap: v)),
              Row(children: [
                Expanded(
                    child: _intField('toX', _selectedExit!.toX,
                        (v) => _updateSelectedExit(toX: v))),
                const SizedBox(width: 8),
                Expanded(
                    child: _intField('toY', _selectedExit!.toY,
                        (v) => _updateSelectedExit(toY: v))),
              ]),
            ],
            const Divider(height: 24),
          ],
          const Text('背景圖', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _textField('檔名 (assets/tiles/)', _background, (v) async {
            _background = v.trim();
            _bg = _background.isEmpty
                ? null
                : await _loadImage('assets/tiles/$_background');
            if (mounted) setState(() {});
          }),
          const SizedBox(height: 12),
          const Text('origin（對齊模式拖曳或微調）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
              'x: ${_originX.toStringAsFixed(1)}   y: ${_originY.toStringAsFixed(1)}'),
          _nudgePad(),
          const SizedBox(height: 12),
          const Text('格線', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Expanded(
                child: _intField('寬(格)', _width, (v) => _resize(v, _height))),
            const SizedBox(width: 8),
            Expanded(
                child: _intField('高(格)', _height, (v) => _resize(_width, v))),
          ]),
          Row(children: [
            Expanded(
                child: _intField('tileW', _tileWidth,
                    (v) => setState(() => _tileWidth = v < 1 ? 1 : v))),
            const SizedBox(width: 8),
            Expanded(
                child: _intField('tileH', _tileHeight,
                    (v) => setState(() => _tileHeight = v < 1 ? 1 : v))),
          ]),
        ],
      ),
    );
  }

  Widget _nudgePad() {
    Widget btn(IconData ic, double dx, double dy) =>
        IconButton(icon: Icon(ic), onPressed: () => _nudgeOrigin(dx, dy));
    return Column(
      children: [
        btn(Icons.keyboard_arrow_up, 0, -8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          btn(Icons.keyboard_arrow_left, -8, 0),
          btn(Icons.keyboard_arrow_right, 8, 0),
        ]),
        btn(Icons.keyboard_arrow_down, 0, 8),
      ],
    );
  }

  Widget _textField(String label, String value, ValueChanged<String> onDone) {
    return TextField(
      decoration: InputDecoration(labelText: label, isDense: true),
      controller: TextEditingController(text: value),
      onSubmitted: onDone,
    );
  }

  Widget _intField(String label, int value, ValueChanged<int> onDone) {
    return TextField(
      key: ValueKey('$label-$value'),
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: '$value'),
      onSubmitted: (v) {
        final n = int.tryParse(v);
        if (n != null) onDone(n);
      },
    );
  }
}

class _HelpBar extends StatelessWidget {
  const _HelpBar({required this.mode});
  final EditMode mode;

  @override
  Widget build(BuildContext context) {
    final text = switch (mode) {
      EditMode.tile => '地形模式　左鍵：塗　右鍵：擦　中鍵拖曳：平移　滾輪：縮放',
      EditMode.collision =>
        '碰撞模式　左鍵：擋(紅)　右鍵：可走　中鍵拖曳：平移　滾輪：縮放',
      EditMode.exit =>
        '出口模式　左鍵：放/選出口(青)　右鍵：移除　右側設定 toMap/toX/toY',
      EditMode.align => '對齊模式　左鍵拖曳：移動背景圖　中鍵拖曳：平移　滾輪：縮放',
    };
    return Container(
      height: 28,
      color: const Color(0xFF15151A),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text,
          style: const TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }
}
