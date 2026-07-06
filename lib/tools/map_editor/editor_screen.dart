import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../game/map/iso_map_data.dart';
import '../../game/map/iso_map_loader.dart';
import '../../game/map/iso_tile_palette.dart';
import 'map_canvas.dart';

/// 地圖編輯器主畫面：載入 → 塗地形 → 存回 assets/maps/{id}.json。
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int _mapId = 0;
  int _selectedTile = 1; // 0 = 橡皮擦
  bool _loading = true;

  // 地圖 meta + 可變格子
  String _name = '';
  int _width = 16;
  int _height = 16;
  int _tileWidth = 64;
  int _tileHeight = 32;
  List<IsoTileset> _tilesets = const [];
  late List<List<int>> _grid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await IsoMapLoader.load(_mapId);
    final layer = data.layers.isNotEmpty ? data.layers.first : null;
    setState(() {
      _name = data.name;
      _width = data.width;
      _height = data.height;
      _tileWidth = data.tileWidth;
      _tileHeight = data.tileHeight;
      _tilesets = data.tilesets;
      _grid = List.generate(
        _height,
        (y) => List.generate(_width, (x) => layer?.tileAt(x, y) ?? 0),
      );
      _loading = false;
    });
  }

  void _paint(int tx, int ty, bool erase) {
    final id = erase ? 0 : _selectedTile;
    if (_grid[ty][tx] == id) return;
    setState(() => _grid[ty][tx] = id);
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
      layers: [IsoTileLayer(name: 'ground', data: _grid)],
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
                _palette(),
                const VerticalDivider(width: 1),
                Expanded(
                  child: MapCanvas(
                    grid: _grid,
                    width: _width,
                    height: _height,
                    tileWidth: _tileWidth,
                    tileHeight: _tileHeight,
                    onPaint: _paint,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const _HelpBar(),
    );
  }

  Widget _mapIdField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 80,
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
      ),
    );
  }

  Widget _palette() {
    return Container(
      width: 96,
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
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
      ),
    );
  }
}

class _HelpBar extends StatelessWidget {
  const _HelpBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: const Color(0xFF15151A),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Text(
        '左鍵：塗　右鍵：擦　中鍵拖曳：平移　滾輪：縮放',
        style: TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
