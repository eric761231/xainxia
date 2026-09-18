import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../game/map/iso_map_data.dart';
import '../../game/map/iso_map_loader.dart';
import '../../game/map/iso_object_catalog.dart';
import '../../game/map/iso_object_graphic.dart';
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
  // 地形圖塊集（tileset sheet）：以均勻網格切片，firstId 固定 1。
  IsoTileset? _tileset;
  ui.Image? _tilesetImg;
  List<String> _tileSheetFiles = const [];
  late List<List<int>> _grid;
  late List<List<int>> _collision;
  List<MapExit> _exits = [];
  MapExit? _selectedExit;

  // 布置物件（prop）
  List<MapObject> _objects = [];
  int _selectedObjectId = 0; // palette 選中的「要放置」的物件 id
  MapObject? _selectedObject; // 場上選中（可微調）的物件
  Map<int, ObjectDef> _objectDefs = const {};
  final Map<int, ObjectGraphic?> _objectGraphics = {};

  // sence 背景可選清單（assets/sences/ 內的檔名）
  List<String> _sceneFiles = const [];

  // 圖層
  int _objectLayers = 1; // 地圖圖層數
  int _characterLayer = 1; // 玩家所在層
  int _activeLayer = 1; // 作用中圖層（放置/選取/擦除目標）

  // 背景圖
  String _background = '';
  double _originX = 0;
  double _originY = 0;
  ui.Image? _bg;
  double _bgDim = 0.4; // 背景調暗，讓格線/碰撞更清楚
  final bool _lock2to1 = true; // 鎖定 tileH = tileW/2，維持 2:1 等距角度
  int _assetRev = 0; // 重載計數，用來讓 Image.file 縮圖失效重讀

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
    _tileset = data.tilesets.isNotEmpty ? data.tilesets.first : null;
    _tilesetImg = (_tileset == null || _tileset!.image.isEmpty)
        ? null
        : await _loadImage('assets/tiles/${_tileset!.image}');
    await _loadTileSheets();
    _background = data.background;
    _originX = data.originX;
    _originY = data.originY;
    _exits = List.of(data.exits);
    _selectedExit = null;
    _objects = List.of(data.objects);
    _selectedObject = null;
    _objectLayers = data.objectLayers < 1 ? 1 : data.objectLayers;
    _characterLayer = data.characterLayer.clamp(1, _objectLayers);
    _activeLayer = _activeLayer.clamp(1, _objectLayers);
    await _loadCatalog();
    await _loadSceneFiles();
    _grid = List.generate(
      _height,
      (y) => List.generate(_width, (x) => tileLayer?.tileAt(x, y) ?? 0),
    );
    _collision = List.generate(
      _height,
      (y) => List.generate(_width, (x) => coll?.tileAt(x, y) ?? 0),
    );
    _bg = _background.isEmpty
        ? null
        : await _loadImage('assets/sences/$_background');
    if (mounted) setState(() => _loading = false);
  }

  /// 重載素材：直接重讀磁碟上的 catalog／物件圖／場景清單／圖塊 sheet／背景／
  /// tileset 圖。編輯器一律走檔案系統，故新增/改檔**即時生效**（免 hot restart）。
  Future<void> _reloadAssets() async {
    _assetRev++;
    // 清 Flutter image cache，讓同名改檔的縮圖（Image.file）不顯示舊內容。
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await _loadCatalog();
    await _loadSceneFiles();
    await _loadTileSheets();
    _bg = _background.isEmpty
        ? null
        : await _loadImage('assets/sences/$_background');
    _tilesetImg = (_tileset == null || _tileset!.image.isEmpty)
        ? null
        : await _loadImage('assets/tiles/${_tileset!.image}');
    if (mounted) setState(() {});
    _toast('已重載素材（即時生效）');
  }

  /// 載入物件目錄與各物件的預覽圖（供 object palette 與畫布預覽）。
  ///
  /// 直接從檔案系統讀 `object_catalog.json` 與各物件圖；並**自動掃 assets/objects/**：
  /// 沒登記過的圖以預設值（腳底錨點、1×1、不擋）補登記，並寫回 catalog 給穩定 id，
  /// 讓「丟進資料夾就出現在選單、存進地圖後遊戲也認得」。找不到圖檔的登記則不列入選單。
  Future<void> _loadCatalog() async {
    Map<String, dynamic> root = {};
    Map<String, dynamic> objectsRaw = {};
    try {
      final file = File('assets/data/object_catalog.json');
      if (file.existsSync()) {
        root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        objectsRaw = (root['objects'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      debugPrint('地圖編輯器：讀取 object_catalog.json 失敗（$e）');
    }

    // 既有 objects 資料夾已登記的檔名 + 目前最大 id
    final registered = <String>{};
    var maxId = 0;
    objectsRaw.forEach((k, v) {
      final id = int.tryParse(k);
      if (id != null && id > maxId) maxId = id;
      if (v is Map<String, dynamic>) {
        final dir = (v['dir'] as String?) ?? 'objects';
        final img = (v['image'] as String?) ?? '';
        if (dir == 'objects' && img.isNotEmpty) {
          registered.add(img.toLowerCase());
        }
      }
    });

    // 該登記的圖檔是否實際存在（跨 dir：objects/sences/tiles）。
    bool fileExists(Map<String, dynamic> v) {
      final dir = (v['dir'] as String?) ?? 'objects';
      final img = (v['image'] as String?) ?? '';
      return img.isNotEmpty && File('assets/$dir/$img').existsSync();
    }

    // 1) 補登記 assets/objects/ 內沒登記過的圖（自動高號段 9000+，避免撞手編 id）。
    final scanned = _listImageDir(
        'assets/objects', const {'.png', '.jpg', '.jpeg', '.webp', '.svg'});
    var nextId = maxId < 8999 ? 9000 : maxId + 1;
    var added = 0;
    for (final name in scanned) {
      if (registered.contains(name.toLowerCase())) continue;
      objectsRaw['$nextId'] = <String, dynamic>{
        'image': name,
        'blocking': false,
        'label': name.split('.').first,
      };
      registered.add(name.toLowerCase());
      nextId++;
      added++;
    }

    // 2) 移除找不到圖檔的登記（讓 catalog 對齊實際檔案）。
    final removeKeys = <String>[];
    objectsRaw.forEach((k, v) {
      if (v is! Map<String, dynamic> || !fileExists(v)) removeKeys.add(k);
    });
    for (final k in removeKeys) {
      objectsRaw.remove(k);
    }
    final removed = removeKeys.length;

    // 3) 有增減才寫回（保留 _comment/_fields 與既有項 id）。
    if (added > 0 || removed > 0) {
      try {
        root['objects'] = objectsRaw;
        await File('assets/data/object_catalog.json').writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(root)}\n');
        debugPrint('地圖編輯器：catalog 同步資料夾（新增 $added、移除 $removed）');
      } catch (e) {
        debugPrint('地圖編輯器：寫回 object_catalog.json 失敗（$e）');
      }
    }

    // 建 defs，載圖（此時登記均有對應檔；仍防解碼失敗）。
    final defs = <int, ObjectDef>{};
    objectsRaw.forEach((k, v) {
      final id = int.tryParse(k);
      if (id != null && v is Map<String, dynamic>) {
        defs[id] = ObjectDef.fromJson(id, v);
      }
    });
    final loaded = <int, ObjectDef>{};
    _objectGraphics.clear();
    for (final def in defs.values) {
      final g = await ObjectGraphic.loadFile('assets/${def.dir}/${def.image}');
      if (g == null) continue;
      loaded[def.id] = def;
      _objectGraphics[def.id] = g;
    }
    _objectDefs = loaded;
    final sorted = loaded.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    if (_objectDefs[_selectedObjectId] == null && sorted.isNotEmpty) {
      _selectedObjectId = sorted.first.id;
    }
  }

  /// 直接列出磁碟上某素材目錄的圖檔名（桌面編輯器用，新增即時反映）。
  List<String> _listImageDir(String dir, Set<String> exts) {
    try {
      final d = Directory(dir);
      if (!d.existsSync()) return const [];
      final files = <String>[];
      for (final e in d.listSync(followLinks: false)) {
        if (e is! File) continue;
        final name = e.uri.pathSegments.last;
        final dot = name.lastIndexOf('.');
        if (dot < 0) continue;
        if (exts.contains(name.substring(dot).toLowerCase())) files.add(name);
      }
      files.sort();
      return files;
    } catch (e) {
      debugPrint('地圖編輯器：列舉 $dir 失敗（$e）');
      return const [];
    }
  }

  /// 列出 assets/sences/ 內可用的場景圖檔名（供背景縮圖挑選）。
  Future<void> _loadSceneFiles() async {
    _sceneFiles =
        _listImageDir('assets/sences', const {'.png', '.jpg', '.jpeg', '.webp'});
  }

  /// 列出 assets/tiles/ 內可用的圖塊 sheet 檔名（供地形 tileset 挑選）。
  Future<void> _loadTileSheets() async {
    _tileSheetFiles =
        _listImageDir('assets/tiles', const {'.png', '.jpg', '.jpeg'});
  }

  /// 設定/更新地形 tileset（firstId 固定 1），並載入 sheet 圖。
  ///
  /// columns 未指定時，依 sheet 寬 + 來源格寬 + marginX/spacing **自動估算**
  /// （使用者仍可用欄數欄位覆寫）。
  Future<void> _applyTileset({
    String? image,
    int? tileW,
    int? tileH,
    int? columns,
    int? marginX,
    int? marginY,
    int? spacing,
  }) async {
    final cur = _tileset;
    final img = (image ?? cur?.image ?? '').trim();
    final tw = tileW ?? cur?.tileWidth ?? 64;
    final th = tileH ?? cur?.tileHeight ?? 32;
    final mx = marginX ?? cur?.marginX ?? 0;
    final my = marginY ?? cur?.marginY ?? 0;
    final sp = spacing ?? cur?.spacing ?? 0;

    // 換圖才重載 sheet 圖；否則沿用目前的。
    final uiImg = img.isEmpty
        ? null
        : (image != null || _tilesetImg == null)
            ? await _loadImage('assets/tiles/$img')
            : _tilesetImg;

    int cols;
    if (columns != null) {
      cols = columns < 1 ? 1 : columns;
    } else if (uiImg != null && tw > 0) {
      final est = (uiImg.width - mx + sp) ~/ (tw + sp);
      cols = est < 1 ? 1 : est;
    } else {
      cols = cur?.columns ?? 1;
    }

    _tileset = IsoTileset(
      firstId: 1,
      image: img,
      tileWidth: tw,
      tileHeight: th,
      columns: cols,
      marginX: mx,
      marginY: my,
      spacing: sp,
    );
    _tilesets = [_tileset!];
    _tilesetImg = uiImg;
    if (mounted) setState(() {});
  }

  /// 目前 tileset 的可選格數（columns × 由圖高推得的列數）。
  int _tilesetCount() {
    final ts = _tileset;
    final img = _tilesetImg;
    if (ts == null || img == null || ts.tileHeight < 1 || ts.columns < 1) {
      return 0;
    }
    final rows = (img.height - ts.marginY + ts.spacing) ~/
        (ts.tileHeight + ts.spacing);
    return ts.columns * (rows < 0 ? 0 : rows);
  }

  /// 載入圖片：優先讀檔案系統（桌面編輯器，改檔即時反映），
  /// 找不到檔才回退 asset 快照。
  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final file = File(assetPath);
      final bytes = file.existsSync()
          ? await file.readAsBytes()
          : (await rootBundle.load(assetPath)).buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } catch (e) {
      _toast('圖片載入失敗：$assetPath（$e）');
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

  void _placeObject(int tx, int ty) {
    if (_objectDefs[_selectedObjectId] == null) {
      _toast('尚未選取物件（object palette 為空？檢查 object_catalog.json）');
      return;
    }
    setState(() {
      // 同格同層已有物件則覆蓋（跨層可疊）。
      _objects.removeWhere(
          (o) => o.x == tx && o.y == ty && o.layer == _activeLayer);
      final obj =
          MapObject(id: _selectedObjectId, x: tx, y: ty, layer: _activeLayer);
      _objects.add(obj);
      _selectedObject = obj; // 放完即選取，方便接著微調
    });
  }

  /// 點到作用中圖層在該格的物件 → 選取（供右側面板微調）。
  void _selectObjectAt(int tx, int ty) {
    final obj = _objects.firstWhere(
      (o) => o.x == tx && o.y == ty && o.layer == _activeLayer,
      orElse: () => const MapObject(id: -1, x: -1, y: -1),
    );
    setState(() => _selectedObject = obj.id < 0 ? null : obj);
  }

  void _removeObject(int tx, int ty) {
    setState(() {
      _objects.removeWhere(
          (o) => o.x == tx && o.y == ty && o.layer == _activeLayer);
      if (_selectedObject != null &&
          _selectedObject!.x == tx &&
          _selectedObject!.y == ty &&
          _selectedObject!.layer == _activeLayer) {
        _selectedObject = null;
      }
    });
  }

  /// 微調選取物件的像素偏移（±dx/dy），就地更新清單與選取狀態。
  void _nudgeSelectedObject(double dx, double dy) {
    final sel = _selectedObject;
    if (sel == null) return;
    final i = _objects
        .indexWhere((o) => o.x == sel.x && o.y == sel.y && o.layer == sel.layer);
    if (i < 0) return;
    final ne =
        sel.copyWith(offsetX: sel.offsetX + dx, offsetY: sel.offsetY + dy);
    setState(() {
      _objects[i] = ne;
      _selectedObject = ne;
    });
  }

  void _resetSelectedOffset() {
    final sel = _selectedObject;
    if (sel == null) return;
    final i = _objects
        .indexWhere((o) => o.x == sel.x && o.y == sel.y && o.layer == sel.layer);
    if (i < 0) return;
    final ne = sel.copyWith(offsetX: 0, offsetY: 0);
    setState(() {
      _objects[i] = ne;
      _selectedObject = ne;
    });
  }

  /// 目前選取物件的原圖寬（px），供尺寸換算；缺圖回 0。
  double _selectedNaturalWidth() {
    final sel = _selectedObject;
    if (sel == null) return 0;
    return _objectGraphics[sel.id]?.width ?? 0;
  }

  /// 調整選取物件寬度格數（每次半格，最小 0.5 格）。
  void _resizeSelectedObject(double delta) {
    final sel = _selectedObject;
    if (sel == null) return;
    final i = _objects
        .indexWhere((o) => o.x == sel.x && o.y == sel.y && o.layer == sel.layer);
    if (i < 0) return;
    final w0 = _selectedNaturalWidth();
    final base = sel.tilesW > 0
        ? sel.tilesW
        : (w0 > 0
            ? ((w0 / _tileWidth * 2).round() / 2).clamp(0.5, 999.0)
            : 1.0);
    final ne = sel.copyWith(tilesW: (base + delta).clamp(0.5, 999.0));
    setState(() {
      _objects[i] = ne;
      _selectedObject = ne;
    });
  }

  void _resetSelectedSize() {
    final sel = _selectedObject;
    if (sel == null) return;
    final i = _objects
        .indexWhere((o) => o.x == sel.x && o.y == sel.y && o.layer == sel.layer);
    if (i < 0) return;
    final ne = sel.copyWith(tilesW: 0);
    setState(() {
      _objects[i] = ne;
      _selectedObject = ne;
    });
  }

  /// 把選取物件移到第 newLayer 層（1.._objectLayers）；作用中圖層一併切過去。
  void _setSelectedLayer(int newLayer) {
    final sel = _selectedObject;
    if (sel == null) return;
    newLayer = newLayer.clamp(1, _objectLayers);
    final i = _objects
        .indexWhere((o) => o.x == sel.x && o.y == sel.y && o.layer == sel.layer);
    if (i < 0) return;
    final ne = sel.copyWith(layer: newLayer);
    setState(() {
      _objects[i] = ne;
      _selectedObject = ne;
      _activeLayer = newLayer; // 跟著切到該層，之後選取/放置一致
    });
  }

  void _nudgeOrigin(double dx, double dy) => setState(() {
    _originX += dx;
    _originY += dy;
  });

  List<List<int>> _resized(List<List<int>> g, int w, int h) => List.generate(
    h,
    (y) => List.generate(
      w,
      (x) => (y < g.length && x < g[y].length) ? g[y][x] : 0,
    ),
  );

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

  /// 設定格子寬；鎖 2:1 時同步 tileH = tileW/2，維持等距角度。
  void _setTileWidth(int w) {
    w = w.clamp(8, 160);
    setState(() {
      _tileWidth = w;
      if (_lock2to1) _tileHeight = (w / 2).round();
    });
  }

  void _setTileHeight(int h) => setState(() => _tileHeight = h < 1 ? 1 : h);

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
      objects: _objects,
      objectLayers: _objectLayers,
      characterLayer: _characterLayer,
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
            tooltip: '重新載入地圖',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            tooltip: '重載素材（catalog/圖檔）',
            onPressed: _loading ? null : _reloadAssets,
            icon: const Icon(Icons.refresh),
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
          ? const Center(child: Text('載入中…'))
          : Row(
              children: [
                Expanded(
                  child: MapCanvas(
                    grid: _grid,
                    collision: _collision,
                    exits: _exits,
                    selectedExit: _selectedExit,
                    objects: _objects,
                    objectDefs: _objectDefs,
                    objectGraphics: _objectGraphics,
                    activeLayer: _activeLayer,
                    selectedObject: _selectedObject,
                    ghostObjectId:
                        _mode == EditMode.object ? _selectedObjectId : null,
                    onObjectTap: _placeObject,
                    onObjectRemove: _removeObject,
                    onObjectSelect: _selectObjectAt,
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
                    bgDim: _bgDim,
                    tileset: _tileset,
                    tilesetImage: _tilesetImg,
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
      style: ButtonStyle(
        // 作用中的模式鈕：明顯藍底白字；未選取回預設色（切鈕自動還原）。
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF3D5AFE)
              : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : null,
        ),
      ),
      segments: const [
        ButtonSegment(
            value: EditMode.tile,
            icon: Icon(Icons.grid_on),
            label: Text('地形')),
        ButtonSegment(
            value: EditMode.collision,
            icon: Icon(Icons.block),
            label: Text('碰撞')),
        ButtonSegment(
            value: EditMode.exit,
            icon: Icon(Icons.meeting_room),
            label: Text('出口')),
        ButtonSegment(
            value: EditMode.object,
            icon: Icon(Icons.park),
            label: Text('物件')),
        ButtonSegment(
            value: EditMode.align,
            icon: Icon(Icons.open_with),
            label: Text('對齊')),
        ButtonSegment(
            value: EditMode.pan,
            icon: Icon(Icons.back_hand),
            label: Text('平移')),
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

  /// 地形選色盤（嵌入右側面板）：tileset 設定 + 切格調色盤；無 tileset 時回退純色。
  Widget _tilePaletteSection() {
    final ts = _tileset;
    final img = _tilesetImg;
    final count = _tilesetCount();
    final hasTileset = ts != null && img != null && count > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tilesetConfig(),
        const SizedBox(height: 8),
        if (hasTileset)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tileSwatch(0, '橡皮'),
              for (int i = 0; i < count; i++) _tileCellSwatch(ts, img, i),
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tileSwatch(0, '橡皮'),
              for (final id in IsoTilePalette.tileIds) _tileSwatch(id, '$id'),
            ],
          ),
      ],
    );
  }

  /// tileset 設定：挑 sheet、設來源格 px（tileW/tileH）與欄數。
  Widget _tilesetConfig() {
    final ts = _tileset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('圖塊集 sheet (assets/tiles/)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            if (ts != null && ts.image.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  _tileset = null;
                  _tilesetImg = null;
                  _tilesets = const [];
                }),
                icon: const Icon(Icons.clear, size: 15),
                label: const Text('清除', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        if (_tileSheetFiles.isEmpty)
          const Text('assets/tiles/ 無圖',
              style: TextStyle(color: Colors.white54, fontSize: 11))
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final name in _tileSheetFiles)
                GestureDetector(
                  onTap: () => _applyTileset(image: name),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A40),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ts?.image == name
                            ? const Color(0xFFFFC107)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        if (ts != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _intField('來源格寬 px', ts.tileWidth,
                    (v) => _applyTileset(tileW: v < 1 ? 1 : v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _intField('來源格高 px', ts.tileHeight,
                    (v) => _applyTileset(tileH: v < 1 ? 1 : v)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _intField('起點 X px', ts.marginX,
                    (v) => _applyTileset(marginX: v < 0 ? 0 : v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _intField('起點 Y px', ts.marginY,
                    (v) => _applyTileset(marginY: v < 0 ? 0 : v)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _intField('欄數 columns', ts.columns,
                    (v) => _applyTileset(columns: v < 1 ? 1 : v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _intField('間距 spacing px', ts.spacing,
                    (v) => _applyTileset(spacing: v < 0 ? 0 : v)),
              ),
            ],
          ),
          Text('可用格數：${_tilesetCount()}（起點跳過上方物件列/邊距，間距填格縫）',
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 6),
          _sheetGridPreview(ts),
        ],
      ],
    );
  }

  /// 切割網格即時預覽：sheet 縮放後疊上紅色格框，讓使用者對齊 margin/格寬/間距。
  Widget _sheetGridPreview(IsoTileset ts) {
    final img = _tilesetImg;
    if (img == null || img.width <= 0 || img.height <= 0) {
      return const SizedBox.shrink();
    }
    const maxW = 224.0, maxH = 240.0;
    final s = (maxW / img.width) < (maxH / img.height)
        ? maxW / img.width
        : maxH / img.height;
    final w = img.width * s, h = img.height * s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('切割預覽（紅框＝每一格）',
            style: TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 4),
        Container(
          color: const Color(0xFF15151A),
          child: SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              painter: _SheetGridPainter(img, ts, _tilesetCount()),
            ),
          ),
        ),
      ],
    );
  }

  /// tileset 單格縮圖 swatch（點選＝設為要塗的 tile id）。
  Widget _tileCellSwatch(IsoTileset ts, ui.Image img, int index) {
    final id = ts.firstId + index;
    final selected = _selectedTile == id;
    final src = ts.srcRect(index);
    final h = (44 * ts.tileHeight / ts.tileWidth).clamp(20.0, 60.0);
    return GestureDetector(
      onTap: () => setState(() => _selectedTile = id),
      child: Container(
        width: 44,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: CustomPaint(painter: _TileCellPainter(img, src)),
      ),
    );
  }

  Widget _tileSwatch(int id, String label) {
    final selected = _selectedTile == id;
    final color =
        id == 0 ? const Color(0xFF3A3A40) : IsoTilePalette.colorFor(id);
    return GestureDetector(
      onTap: () => setState(() => _selectedTile = id),
      child: Container(
        width: 44,
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
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)),
      ),
    );
  }

  /// 物件欄（嵌入右側面板）：列出 object_catalog.json 每個物件（縮圖＋id/label）。
  Widget _objectPaletteSection() {
    final defs = _objectDefs.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (defs.isEmpty) {
      return const Text('無物件（檢查 object_catalog.json）',
          style: TextStyle(color: Colors.white54, fontSize: 11));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [for (final d in defs) SizedBox(width: 82, child: _objectPaletteItem(d))],
    );
  }

  Widget _objectPaletteItem(ObjectDef d) {
    final selected = _selectedObjectId == d.id;
    final g = _objectGraphics[d.id];
    return GestureDetector(
      onTap: () => setState(() => _selectedObjectId = d.id),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A40),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFFE53935) : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              width: double.infinity,
              child: g == null
                  ? const Icon(Icons.image_not_supported,
                      color: Colors.white38)
                  : CustomPaint(painter: _GraphicThumbPainter(g)),
            ),
            Text(
              d.label.isEmpty ? '${d.id}' : '${d.id} ${d.label}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _setActiveLayer(int v) =>
      setState(() => _activeLayer = v.clamp(1, _objectLayers));

  /// 圖層區：地圖圖層數 / 角色圖層 / 作用中圖層 / 選取物件的圖層。
  Widget _layerSection() {
    final sel = _selectedObject;
    Widget stepRow(String label, int value, ValueChanged<int> onSet) => Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: () => onSet(value - 1),
            ),
            Text('$value',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: () => onSet(value + 1),
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('圖層', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _intField('圖層數', _objectLayers, (v) {
                setState(() {
                  _objectLayers = v.clamp(1, 99);
                  _activeLayer = _activeLayer.clamp(1, _objectLayers);
                  _characterLayer = _characterLayer.clamp(1, _objectLayers);
                });
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _intField('角色層', _characterLayer,
                  (v) => setState(() => _characterLayer = v.clamp(1, _objectLayers))),
            ),
          ],
        ),
        stepRow('作用中圖層', _activeLayer, _setActiveLayer),
        if (sel != null) stepRow('選取物件的層', sel.layer, _setSelectedLayer),
        const Text('（第1層最底；放置/選取以作用中圖層為準）',
            style: TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _settingsPanel() {
    return Container(
      width: 248,
      color: const Color(0xFF26262B),
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          if (_mode == EditMode.tile) ...[
            const Text('地形選色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _tilePaletteSection(),
            const Divider(height: 24),
          ],
          if (_mode == EditMode.object) ...[
            const Text('物件', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _objectPaletteSection(),
            const Divider(height: 16),
            _layerSection(),
            const Divider(height: 16),
            const Text('物件微調', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _objectAdjustPanel(),
            const Divider(height: 24),
          ],
          if (_mode == EditMode.exit) ...[
            const Text('出口設定', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (_selectedExit == null)
              const Text(
                '點格子新增/選取出口\n右鍵移除',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              )
            else ...[
              Text('出口格 (${_selectedExit!.x}, ${_selectedExit!.y})'),
              _intField(
                '目標地圖 toMap',
                _selectedExit!.toMap,
                (v) => _updateSelectedExit(toMap: v),
              ),
              Row(
                children: [
                  Expanded(
                    child: _intField(
                      'toX',
                      _selectedExit!.toX,
                      (v) => _updateSelectedExit(toX: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _intField(
                      'toY',
                      _selectedExit!.toY,
                      (v) => _updateSelectedExit(toY: v),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
          ],
          Row(
            children: [
              const Expanded(
                child: Text('背景圖（sences）',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (_background.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _background = '';
                    _bg = null;
                  }),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('清除', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          Text('目前：${_background.isEmpty ? '無背景' : _background}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          _scenePicker(),
          const SizedBox(height: 8),
          _textField('檔名 (assets/sences/)', _background, (v) async {
            _background = v.trim();
            _bg = _background.isEmpty
                ? null
                : await _loadImage('assets/sences/$_background');
            if (mounted) setState(() {});
          }),
          const SizedBox(height: 8),
          Text(
            '背景調暗 ${(_bgDim * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
          Slider(
            value: _bgDim,
            max: 0.85,
            divisions: 17,
            onChanged: (v) => setState(() => _bgDim = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'origin（對齊模式拖曳或微調）',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'x: ${_originX.toStringAsFixed(1)}   y: ${_originY.toStringAsFixed(1)}',
          ),
          _nudgePad(),
          const SizedBox(height: 12),
          const Text('格線', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: _intField('寬(格)', _width, (v) => _resize(v, _height)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _intField('高(格)', _height, (v) => _resize(_width, v)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _intField('tileW', _tileWidth, _setTileWidth),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _intField('tileH', _tileHeight, _setTileHeight),
              ),
            ],
          ),
          Text('格子大小 ${_tileWidth}px（鎖 2:1 等距角度）',
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
          Slider(
            value: _tileWidth.toDouble().clamp(16, 96),
            min: 16,
            max: 96,
            divisions: 80,
            label: '$_tileWidth',
            onChanged: (v) => _setTileWidth(v.round()),
          ),
        ],
      ),
    );
  }

  /// object 模式：選取物件的資訊 + 方向鍵微調 offset + 歸零。
  Widget _objectAdjustPanel() {
    final sel = _selectedObject;
    if (sel == null) {
      return const Text(
        '左鍵點空格放置、點已放置的物件可選取\n右鍵移除\n選取後用方向鍵微調對位',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      );
    }
    final def = _objectDefs[sel.id];
    Widget nudgeBtn(IconData ic, double dx, double dy) => IconButton(
          icon: Icon(ic),
          iconSize: 20,
          onPressed: () => _nudgeSelectedObject(dx, dy),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('id ${sel.id}${def != null && def.label.isNotEmpty ? '　${def.label}' : ''}'),
        Text('格 (${sel.x}, ${sel.y})',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text('檔名 ${def?.image ?? '(缺定義)'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          'offset (${sel.offsetX.toStringAsFixed(0)}, ${sel.offsetY.toStringAsFixed(0)})',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Column(
          children: [
            nudgeBtn(Icons.keyboard_arrow_up, 0, -2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                nudgeBtn(Icons.keyboard_arrow_left, -2, 0),
                nudgeBtn(Icons.keyboard_arrow_right, 2, 0),
              ],
            ),
            nudgeBtn(Icons.keyboard_arrow_down, 0, 2),
          ],
        ),
        Center(
          child: TextButton.icon(
            onPressed: _resetSelectedOffset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('offset 歸零'),
          ),
        ),
        const Divider(height: 16),
        Text(
          sel.tilesW > 0
              ? '尺寸 寬 ${sel.tilesW.toStringAsFixed(1)} 格'
              : '尺寸 原尺寸',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 22,
              tooltip: '寬 -0.5 格',
              onPressed: () => _resizeSelectedObject(-0.5),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 22,
              tooltip: '寬 +0.5 格',
              onPressed: () => _resizeSelectedObject(0.5),
            ),
          ],
        ),
        Center(
          child: TextButton.icon(
            onPressed: _resetSelectedSize,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('尺寸原尺寸'),
          ),
        ),
      ],
    );
  }

  /// 背景圖 sence 縮圖挑選：點一下即套用該場景圖。
  Widget _scenePicker() {
    if (_sceneFiles.isEmpty) {
      return const Text('assets/sences/ 無圖',
          style: TextStyle(color: Colors.white54, fontSize: 11));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _background = '';
            _bg = null;
          }),
          child: Container(
            width: 60,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A40),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _background.isEmpty
                    ? const Color(0xFFFFC107)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: const Text('無',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        for (final name in _sceneFiles)
          GestureDetector(
            onTap: () async {
              _background = name;
              _bg = await _loadImage('assets/sences/$name');
              if (mounted) setState(() {});
            },
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _background == name
                      ? const Color(0xFFFFC107)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.file(
                      File('assets/sences/$name'),
                      key: ValueKey('scene-$name-$_assetRev'),
                      width: 56,
                      height: 40,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stack) => const SizedBox(
                        width: 56,
                        height: 40,
                        child: Icon(Icons.broken_image,
                            size: 18, color: Colors.white38),
                      ),
                    ),
                  ),
                  Text(name,
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _nudgePad() {
    Widget btn(IconData ic, double dx, double dy) =>
        IconButton(icon: Icon(ic), onPressed: () => _nudgeOrigin(dx, dy));
    return Column(
      children: [
        btn(Icons.keyboard_arrow_up, 0, -8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.keyboard_arrow_left, -8, 0),
            btn(Icons.keyboard_arrow_right, 8, 0),
          ],
        ),
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
      EditMode.collision => '碰撞模式　左鍵：擋(紅)　右鍵：可走　中鍵拖曳：平移　滾輪：縮放',
      EditMode.exit => '出口模式　左鍵：放/選出口(青)　右鍵：移除　右側設定 toMap/toX/toY',
      EditMode.object => '物件模式　左鍵：放置/點物件選取　按住左鍵拖曳：連續放置(印章)　右鍵/拖曳：擦除　hover 顯示資訊',
      EditMode.align => '對齊模式　左鍵拖曳：移動背景圖　中鍵拖曳：平移　滾輪：縮放',
      EditMode.pan => '平移模式　左鍵拖曳：移動整張地圖　滾輪：縮放　（或用左側/下方卷軸）',
    };
    return Container(
      height: 28,
      color: const Color(0xFF15151A),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}

/// 切割網格預覽：把整張 sheet 等比縮放畫進 [size]，再依 tileset 參數疊紅色格框。
class _SheetGridPainter extends CustomPainter {
  _SheetGridPainter(this.image, this.tileset, this.count);

  final ui.Image image;
  final IsoTileset tileset;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / image.width;
    final sy = size.height / image.height;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFF3B30);
    for (int i = 0; i < count; i++) {
      final r = tileset.srcRect(i);
      canvas.drawRect(
        Rect.fromLTWH(r.left * sx, r.top * sy, r.width * sx, r.height * sy),
        grid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SheetGridPainter old) =>
      old.image != image ||
      old.count != count ||
      old.tileset.marginX != tileset.marginX ||
      old.tileset.marginY != tileset.marginY ||
      old.tileset.spacing != tileset.spacing ||
      old.tileset.tileWidth != tileset.tileWidth ||
      old.tileset.tileHeight != tileset.tileHeight ||
      old.tileset.columns != tileset.columns;
}

/// tileset 單格縮圖：把 sheet 的來源矩形拉伸畫滿 swatch。
class _TileCellPainter extends CustomPainter {
  _TileCellPainter(this.image, this.src);

  final ui.Image image;
  final Rect src;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
        image, src, Rect.fromLTWH(0, 0, size.width, size.height), Paint());
  }

  @override
  bool shouldRepaint(covariant _TileCellPainter old) =>
      old.image != image || old.src != src;
}

/// palette 縮圖：把 ObjectGraphic（點陣或 SVG）等比縮放置中畫進格子。
class _GraphicThumbPainter extends CustomPainter {
  _GraphicThumbPainter(this.graphic);

  final ObjectGraphic graphic;

  @override
  void paint(Canvas canvas, Size size) {
    final w0 = graphic.width, h0 = graphic.height;
    if (w0 <= 0 || h0 <= 0) return;
    final s = (size.width / w0).clamp(0.0, size.height / h0);
    final w = w0 * s, h = h0 * s;
    final dx = (size.width - w) / 2, dy = (size.height - h) / 2;
    graphic.paint(canvas, Rect.fromLTWH(dx, dy, w, h));
  }

  @override
  bool shouldRepaint(covariant _GraphicThumbPainter old) =>
      old.graphic != graphic;
}
