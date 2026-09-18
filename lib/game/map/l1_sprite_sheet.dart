import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 由 DrawPng 的 `l1_sprite_to_sheet.py` 產生的圖集（一張 PNG + 一個 JSON）。
///
/// 與 Flame 內建的 [SpriteAnimationData.sequenced] 最大的差別：**這不是等格的**。
/// 每一幀各自記自己在圖集裡的 `rect`，以及相對角色原點的 `offset`。
///
/// 為什麼要這樣：等格圖集的格子必須容得下所有方向與所有幀，倒地的死亡動作
/// 會把格子撐到很大，整張圖絕大多數是透明（實測人物的死亡圖 2200×912）。
/// 而且一個錨點服務所有幀，格子開小一點就裁到圖。改成逐幀 rect + offset 之後，
/// 同一隻怪的六個動作全部塞在 1024×539 裡，還比原本只有走路那張小。
///
/// `offset` 的語意與 `L1SprTool/output/240` 相同：把這一幀畫在
/// `角色原點 + offset`。原點就是腳底著地點，也就是元件自己的位置。
@immutable
class L1Frame {
  const L1Frame({required this.src, required this.offset});

  /// 這一幀在圖集裡的位置與大小。
  final ui.Rect src;

  /// 相對角色原點的左上角位移。
  final Vector2 offset;
}

/// 一組動畫（某個動作的某個方向）。
@immutable
class L1Animation {
  const L1Animation(this.frames);

  final List<L1Frame> frames;

  bool get isEmpty => frames.isEmpty;
}

/// 一整份圖集。
class L1SpriteSheet {
  L1SpriteSheet({
    required this.image,
    required this.animations,
    required this.actions,
    required this.tileWidth,
    this.facingMap = _identityFacingMap,
  });

  final ui.Image image;

  /// key = `<動作>-<facing>`，例如 `walk-3`。
  final Map<String, L1Animation> animations;

  /// 這份圖集有哪些動作，依 L1 的動作編號排序。
  final List<String> actions;

  /// 產生這份圖集時的格寬。與目前的格寬不同就代表素材該重產了。
  final int tileWidth;

  /// 遊戲 facing (0..7) 對應到素材內的方向編號。
  final List<int> facingMap;

  static const List<int> _identityFacingMap = [0, 1, 2, 3, 4, 5, 6, 7];

  bool has(String action) => animations.containsKey('$action-0');

  /// 取某個動作某個方向的動畫；沒有就回 null。
  L1Animation? get(String action, int facing) {
    final gameFacing = facing.clamp(0, 7);
    return animations['$action-${facingMap[gameFacing]}'];
  }

  static const Map<String, (int, int)> _actionIndexRanges = {
    'walk': (0, 7),
    'idle': (8, 15),
    'attack': (16, 23),
    'hurt': (24, 31),
    'death': (96, 103),
  };

  static L1SpriteSheet? parse(ui.Image image, Map<String, dynamic> j) {
    final raw = j['animations'] as Map<String, dynamic>?;
    if (raw == null) return null;
    final anchorMode = j['anchor_mode']?.toString();
    final anims = <String, L1Animation>{};
    L1Animation parseAnim(Map<String, dynamic> value) {
      final frames = (value['frames'] as List?) ?? const [];
      return L1Animation(
        frames
            .whereType<Map<String, dynamic>>()
            .map((f) {
              final r = (f['rect'] as List).cast<num>();
              final o = (f['offset'] as List).cast<num>();
              final offset = anchorMode == 'frame_bottom_center'
                  ? Vector2(-r[2].toDouble() / 2, -r[3].toDouble())
                  : Vector2(o[0].toDouble(), o[1].toDouble());
              return L1Frame(
                src: ui.Rect.fromLTWH(
                  r[0].toDouble(),
                  r[1].toDouble(),
                  r[2].toDouble(),
                  r[3].toDouble(),
                ),
                offset: offset,
              );
            })
            .toList(growable: false),
      );
    }

    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        anims[key] = parseAnim(value);
      }
    });

    // 支援以數字編號命名的動畫格式（例如 3221.json 的 3221-0 ~ 3221-103）
    // 自動對接：
    //   0..7   -> walk
    //   8..15  -> idle
    //   16..23 -> attack
    //   24..31 -> hurt
    //   96..103-> death
    final charId = j['character_id']?.toString();
    final prefix = charId != null ? '$charId-' : null;
    final detectedActions = <String>{};

    for (final entry in _actionIndexRanges.entries) {
      final actionName = entry.key;
      final start = entry.value.$1;
      final end = entry.value.$2;
      for (var i = start; i <= end; i++) {
        final facing = i - start;
        final candidateKey = prefix != null ? '$prefix$i' : null;
        if (candidateKey != null && anims.containsKey(candidateKey)) {
          anims['$actionName-$facing'] = anims[candidateKey]!;
          detectedActions.add(actionName);
        } else if (anims.containsKey('$i')) {
          anims['$actionName-$facing'] = anims['$i']!;
          detectedActions.add(actionName);
        }
      }
    }

    final tile = (j['tile'] as List?)?.cast<num>();
    final rawFacingMap = (j['facing_map'] as List?)?.cast<num>();
    final facingMap =
        rawFacingMap != null &&
            rawFacingMap.length == 8 &&
            rawFacingMap.every((f) => f >= 0 && f <= 7)
        ? List<int>.unmodifiable(rawFacingMap.map((f) => f.toInt()))
        : _identityFacingMap;
    final parsedActions = ((j['actions'] as List?) ?? const [])
        .cast<String>()
        .toList();
    for (final act in detectedActions) {
      if (!parsedActions.contains(act)) {
        parsedActions.add(act);
      }
    }

    return L1SpriteSheet(
      image: image,
      animations: anims,
      actions: parsedActions,
      tileWidth: tile != null && tile.isNotEmpty ? tile[0].toInt() : 48,
      facingMap: facingMap,
    );
  }
}

/// 讀取並快取圖集。`path` 是相對 `assets/` 的 PNG 路徑。
class L1SpriteSheetCache {
  L1SpriteSheetCache._();

  static final Map<String, L1SpriteSheet?> _cache = {};

  static Future<L1SpriteSheet?> load(String pngPath) async {
    if (_cache.containsKey(pngPath)) return _cache[pngPath];
    try {
      final jsonPath = pngPath.replaceAll(RegExp(r'\.png$'), '.json');
      final meta =
          jsonDecode(await rootBundle.loadString(jsonPath))
              as Map<String, dynamic>;
      final bytes = await rootBundle.load(pngPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      return _cache[pngPath] = L1SpriteSheet.parse(frame.image, meta);
    } catch (e) {
      debugPrint('L1SpriteSheet: 載入失敗 $pngPath（$e）');
      return _cache[pngPath] = null;
    }
  }
}

/// 播放 [L1SpriteSheet] 的元件。
///
/// 自己畫而不是用 [SpriteAnimationComponent]：Flame 的動畫元件假設每一幀
/// 對齊同一個 anchor，這裡每一幀有自己的 `offset`，那才是這個格式的重點。
/// 元件的原點 (0,0) 就是角色的著地點，所以掛上去不需要再算任何錨點。
class L1SpriteComponent extends PositionComponent {
  L1SpriteComponent({
    required this.sheet,
    required String action,
    required int facing,
    this.stepTime = 0.12,
    this.filterQuality = FilterQuality.none,
    // 私有欄位不能直接當具名參數，只能在初始化列表指派
    // ignore: prefer_initializing_formals
  }) : _action = action,
       // ignore: prefer_initializing_formals
       _facing = facing,
       super(position: Vector2.zero());

  final L1SpriteSheet sheet;
  final double stepTime;

  /// 放大時的取樣方式。
  ///
  /// 整數倍請用 [FilterQuality.none]：一個來源像素剛好對應 N×N，點陣圖最銳利。
  /// 非整數倍（例如 1.5）用 none 會讓有些來源像素變 1px、有些變 2px，邊緣呈
  /// 不規則階梯；那種情況改用平滑取樣比較好看。選擇邏輯在
  /// [IsoPlayerComponent] —— 它知道實際倍率。
  final FilterQuality filterQuality;

  String _action;
  int _facing;
  int _frame = 0;
  double _elapsed = 0;
  double? _cycleProgress;

  /// 播完最後一幀後停住，不循環。死亡要用它 —— 屍體不該站起來再倒一次。
  bool holdLastFrame = false;

  /// 停在第 0 幀不動。
  ///
  /// 站著時用它。這組素材沒有獨立的待機動作，站姿是借走路的第 0 幀 ——
  /// 但如果讓走路循環繼續跑，人站在原地會一直甩手，看起來像在打拳。
  bool freeze = false;

  /// 這一輪動畫是否已經播到最後一幀（只在 [holdLastFrame] 時有意義）。
  bool get finished =>
      holdLastFrame && _frame >= (_current?.frames.length ?? 1) - 1;

  /// 目前影格索引，主要供移動同步測試與診斷使用。
  int get currentFrameIndex => _frame;

  String get currentAction => _action;
  int get currentFacing => _facing;

  L1Animation? get _current => sheet.get(_action, _facing);

  /// 目前影格相對角色腳底原點的可視範圍，供滑鼠命中判定使用。
  ui.Rect? get currentFrameBounds {
    final anim = _current;
    if (anim == null || anim.isEmpty) return null;
    final frame = anim.frames[_frame.clamp(0, anim.frames.length - 1)];
    return ui.Rect.fromLTWH(
      frame.offset.x,
      frame.offset.y,
      frame.src.width,
      frame.src.height,
    );
  }

  /// 切換動作或方向。同一個組合重複呼叫不會重播。
  void setState(String action, int facing, {bool restart = false}) {
    final f = facing.clamp(0, 7);
    if (!restart && action == _action && f == _facing) return;
    // 換動作才從頭播；只是轉向的話保留播放進度，否則走路一轉彎腳就會重踏
    final changedAction = action != _action;
    _action = action;
    _facing = f;
    if (restart || changedAction) {
      _frame = 0;
      _elapsed = 0;
      holdLastFrame = false;
    }
  }

  /// 切到「站著不動」：用 [action] 的第 0 幀當站姿並停住。
  void stand(String action, int facing) {
    setState(action, facing);
    freeze = true;
  }

  /// 從頭播一次某個動作（攻擊、受傷、死亡）。
  void play(String action, int facing, {bool hold = false}) {
    _action = action;
    _facing = facing.clamp(0, 7);
    _frame = 0;
    _elapsed = 0;
    _cycleProgress = null;
    holdLastFrame = hold;
    freeze = false;
  }

  /// 由人物的一格移動進度直接指定 walk 影格。
  ///
  /// 傳 null 恢復各動作原本的時間軸；0..1 則將整個動畫平均分配到一格。
  void setCycleProgress(double? progress) {
    _cycleProgress = progress?.clamp(0.0, 1.0);
    final anim = _current;
    if (_cycleProgress == null || anim == null || anim.isEmpty) return;
    final scaled = (_cycleProgress! * anim.frames.length).floor();
    _frame = scaled.clamp(0, anim.frames.length - 1);
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final anim = _current;
    if (anim == null || anim.frames.length <= 1) return;
    if (freeze) {
      _frame = 0;
      _elapsed = 0;
      return;
    }
    if (_cycleProgress != null) {
      setCycleProgress(_cycleProgress);
      return;
    }
    _elapsed += dt;
    while (_elapsed >= stepTime) {
      _elapsed -= stepTime;
      if (holdLastFrame && _frame >= anim.frames.length - 1) {
        _elapsed = 0;
        break;
      }
      _frame = (_frame + 1) % anim.frames.length;
    }
  }

  @override
  void render(Canvas canvas) {
    final anim = _current;
    if (anim == null || anim.isEmpty) return;
    final f = anim.frames[_frame.clamp(0, anim.frames.length - 1)];
    canvas.drawImageRect(
      sheet.image,
      f.src,
      ui.Rect.fromLTWH(f.offset.x, f.offset.y, f.src.width, f.src.height),
      Paint()..filterQuality = filterQuality,
    );
  }
}
