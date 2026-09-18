import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum CharacterAnimationState { idle, walk, attack, hurt, death }

/// 單一動畫狀態的影格配置。
class CharacterStateSpec {
  const CharacterStateSpec({
    this.image,
    this.frameWidth,
    this.frameHeight,
    required this.startColumn,
    required this.frameCount,
    required this.stepTime,
    this.offsetY = 0,
  });

  /// 空值時沿用 sheet 的主 image；可讓 action 使用獨立 atlas。
  final String? image;
  final int? frameWidth;
  final int? frameHeight;
  final int startColumn;
  final int frameCount;
  final double stepTime;

  /// 這個 state 額外的垂直位移（px），疊在 sheet 的 [footOffsetY] 之上。
  ///
  /// 為什麼需要逐 state 的位移：sprite 是 [Anchor.bottomCenter]，格底會被釘在
  /// tile 中心。站姿沒問題，但**倒下的身體會往畫面下方長** —— 朝 S/SE/SW 倒下
  /// 時，格底以下就是格外，畫多少切多少。所以死亡的錨點必須放在格子內部
  /// （DrawPng 用 208 高的格、錨點在 y=138），再由這裡把整張圖往下推回來。
  ///
  /// 只有一個 sheet 級 [footOffsetY] 是不夠的：死亡需要的 +70px 會把
  /// idle/walk/attack 一起下移。預設 0，既有 sheet 的行為完全不變。
  final double offsetY;

  factory CharacterStateSpec.fromJson(Map<String, dynamic> j) =>
      CharacterStateSpec(
        image: j['image'] as String?,
        frameWidth: (j['frameWidth'] as num?)?.toInt(),
        frameHeight: (j['frameHeight'] as num?)?.toInt(),
        startColumn: (j['startColumn'] as num?)?.toInt() ?? 0,
        frameCount: (j['frameCount'] as num?)?.toInt() ?? 1,
        stepTime: (j['stepTime'] as num?)?.toDouble() ?? 0.15,
        offsetY: (j['offsetY'] as num?)?.toDouble() ?? 0,
      );
}

/// 人物 sprite sheet 描述（character_sprites.json 內單一 key 的設定）。
class CharacterSpriteData {
  const CharacterSpriteData({
    required this.image,
    required this.frameWidth,
    required this.frameHeight,
    required this.footOffsetY,
    required this.renderScale,
    required this.states,
  });

  final String image;
  final int frameWidth;
  final int frameHeight;
  final double footOffsetY;
  final double renderScale;
  final Map<CharacterAnimationState, CharacterStateSpec> states;

  CharacterStateSpec state(CharacterAnimationState value) =>
      states[value] ?? states[CharacterAnimationState.idle]!;

  factory CharacterSpriteData.fromJson(Map<String, dynamic> j) {
    final states = j['states'] as Map<String, dynamic>? ?? const {};
    CharacterStateSpec state(String k, CharacterStateSpec fallback) {
      final v = states[k];
      return v is Map<String, dynamic>
          ? CharacterStateSpec.fromJson(v)
          : fallback;
    }

    final parsed = <CharacterAnimationState, CharacterStateSpec>{
      CharacterAnimationState.idle: state(
        'idle',
        const CharacterStateSpec(startColumn: 0, frameCount: 1, stepTime: 0.2),
      ),
      CharacterAnimationState.walk: state(
        'walk',
        const CharacterStateSpec(startColumn: 0, frameCount: 1, stepTime: 0.1),
      ),
    };
    for (final value in const [
      CharacterAnimationState.attack,
      CharacterAnimationState.hurt,
      CharacterAnimationState.death,
    ]) {
      final raw = states[value.name];
      if (raw is Map<String, dynamic>) {
        parsed[value] = CharacterStateSpec.fromJson(raw);
      }
    }

    return CharacterSpriteData(
      image: j['image'] as String? ?? '',
      frameWidth: (j['frameWidth'] as num?)?.toInt() ?? 64,
      frameHeight: (j['frameHeight'] as num?)?.toInt() ?? 96,
      footOffsetY: (j['footOffsetY'] as num?)?.toDouble() ?? 0,
      renderScale: (j['renderScale'] as num?)?.toDouble() ?? 1.0,
      states: parsed,
    );
  }
}

/// 人物 sprite 成品：8 向 × idle/walk 的動畫組。
class CharacterSpriteSet {
  const CharacterSpriteSet({
    required this.animations,
    required this.frameSize,
    required this.stateFrameSizes,
    required this.stateOffsets,
    required this.footOffsetY,
    required this.renderScale,
    this.l1Path,
  });

  /// 若設定了 `"l1"`，人物改用 DrawPng 的緊密打包圖集（逐幀 offset），
  /// 上面那些等格欄位就不適用 —— 那套圖集每一幀有自己的尺寸與位移。
  /// 手繪素材維持原本的等格路徑，兩者並存。
  final String? l1Path;

  /// key = [keyFor]：state * 8 + facing(0..7)。
  final Map<int, SpriteAnimation> animations;
  final Vector2 frameSize;
  final Map<CharacterAnimationState, Vector2> stateFrameSizes;
  final Map<CharacterAnimationState, double> stateOffsets;
  final double footOffsetY;
  final double renderScale;

  Vector2 frameSizeFor(CharacterAnimationState state) =>
      stateFrameSizes[state] ?? frameSize;

  /// 這個 state 的 sprite 相對 tile 中心的垂直位移（含 sheet 級的 footOffsetY）。
  double offsetYFor(CharacterAnimationState state) =>
      footOffsetY + (stateOffsets[state] ?? 0);

  static int keyFor({
    CharacterAnimationState? state,
    bool moving = false,
    required int facing,
  }) =>
      (state ??
                  (moving
                      ? CharacterAnimationState.walk
                      : CharacterAnimationState.idle))
              .index *
          8 +
      facing.clamp(0, 7);

  bool has(CharacterAnimationState state) =>
      animations.containsKey(keyFor(state: state, facing: 0));
}

/// 地圖場景資產讀取器：tile 圖集 + 人物 8 向 sprite。
///
/// 皆含快取；載入失敗一律回 `null`，由呼叫端沿用既有 fallback
/// （tile → 色塊菱形；人物 → canvas 火柴人），不讓缺圖造成崩潰。
class SceneAssetLoader {
  SceneAssetLoader._();

  static final Images _tiles = Images(prefix: 'assets/tiles/');
  static final Images _scenes = Images(prefix: 'assets/sences/');
  static final Images _mapBgs = Images(prefix: 'assets/maps/');
  static final Images _objects = Images(prefix: 'assets/objects/');
  static final Images _chars = Images(prefix: 'assets/characters/');
  static final Images _weapons = Images(prefix: 'assets/weapons/');
  static final Images _monsters = Images(prefix: 'assets/monsters/');

  static const _spriteDescriptorPath = 'assets/data/character_sprites.json';

  static final Map<String, ui.Image?> _tileCache = {};
  static final Map<String, ui.Image?> _sceneCache = {};
  static final Map<String, ui.Image?> _mapBgCache = {};
  static final Map<String, ui.Image?> _objectCache = {};
  static final Map<String, CharacterSpriteSet?> _charCache = {};
  static final Map<String, ui.Image?> _weaponCache = {};
  static final Map<String, ui.Image?> _monsterCache = {};
  static Map<String, dynamic>? _descriptor;
  static bool _descriptorLoaded = false;

  /// 載入 tile 圖集（前綴 `assets/tiles/`）；失敗回 null。
  static Future<ui.Image?> loadTileAtlas(String image) async {
    if (image.isEmpty) return null;
    if (_tileCache.containsKey(image)) return _tileCache[image];
    try {
      final img = await _tiles.load(image);
      _tileCache[image] = img;
      return img;
    } catch (e) {
      debugPrint('SceneAssetLoader: tile 圖集載入失敗 $image（$e），改用 fallback');
      _tileCache[image] = null;
      return null;
    }
  }

  /// 載入單張場景背景圖（前綴 `assets/sences/`）；失敗回 null。
  static Future<ui.Image?> loadSceneImage(String image) async {
    if (image.isEmpty) return null;
    if (_sceneCache.containsKey(image)) return _sceneCache[image];
    try {
      final img = await _scenes.load(image);
      _sceneCache[image] = img;
      return img;
    } catch (e) {
      debugPrint('SceneAssetLoader: 場景背景載入失敗 $image（$e），改用 fallback');
      _sceneCache[image] = null;
      return null;
    }
  }

  /// 載入地圖底圖（前綴 `assets/maps/`，檔名為 `{mapId}.png`）；失敗回 null。
  ///
  /// 這是「一張圖一張地圖」的慣例，與伺服器 map 表的 map_id 直接對應。
  /// 若該地圖在 map 表設了 gfxid，則改走 object_catalog 的編號查詢。
  static Future<ui.Image?> loadMapBackground(int mapId) async {
    final name = '$mapId.png';
    if (_mapBgCache.containsKey(name)) return _mapBgCache[name];
    try {
      final img = await _mapBgs.load(name);
      _mapBgCache[name] = img;
      return img;
    } catch (e) {
      debugPrint('SceneAssetLoader: 地圖底圖載入失敗 $name（$e），改用純格網');
      _mapBgCache[name] = null;
      return null;
    }
  }

  /// 載入物件（prop）圖集（前綴 `assets/objects/`）；失敗回 null。
  static Future<ui.Image?> loadObjectAtlas(String image) async {
    if (image.isEmpty) return null;
    if (_objectCache.containsKey(image)) return _objectCache[image];
    try {
      final img = await _objects.load(image);
      _objectCache[image] = img;
      return img;
    } catch (e) {
      debugPrint('SceneAssetLoader: 物件圖集載入失敗 $image（$e），改用 fallback');
      _objectCache[image] = null;
      return null;
    }
  }

  static Future<ui.Image?> loadMonsterImage(String image) async {
    if (image.isEmpty) return null;
    if (_monsterCache.containsKey(image)) return _monsterCache[image];
    try {
      return _monsterCache[image] = await _monsters.load(image);
    } catch (e) {
      debugPrint('SceneAssetLoader: 怪物圖載入失敗 $image（$e）');
      return _monsterCache[image] = null;
    }
  }

  /// 怪物圖集的規格（與 PNG 同名的 `.json`，由 DrawPng 的
  /// `l1_sprite_to_sheet.py` 產生）。失敗回 null。
  ///
  /// 格子大小與錨點**一定要讀檔**，不能寫死在元件裡：著地點不是圖形的中心
  /// 也不是底邊（實測那隻狼左 27／右 40／上 50／下 16 px，左右不對稱，
  /// 而且腳與尾有一截在著地點下方）。寫死的話換一隻怪就會錯位，
  /// 而且不會有任何錯誤訊息 —— 只是圖歪掉。
  static Future<MonsterSheetSpec?> loadMonsterSpec(String image) async {
    if (image.isEmpty) return null;
    if (_monsterSpecCache.containsKey(image)) return _monsterSpecCache[image];
    final path = 'assets/monsters/${image.replaceAll('.png', '.json')}';
    try {
      final raw = await rootBundle.loadString(path);
      return _monsterSpecCache[image] =
          MonsterSheetSpec.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('SceneAssetLoader: 怪物圖規格載入失敗 $path（$e）');
      return _monsterSpecCache[image] = null;
    }
  }

  static final Map<String, MonsterSheetSpec?> _monsterSpecCache = {};

  /// 載入可裝備的獨立武器圖（前綴 `assets/weapons/`）；失敗回 null。
  static Future<ui.Image?> loadWeaponImage(String image) async {
    if (image.isEmpty) return null;
    if (_weaponCache.containsKey(image)) return _weaponCache[image];
    try {
      return _weaponCache[image] = await _weapons.load(image);
    } catch (e) {
      debugPrint('SceneAssetLoader: 武器圖載入失敗 $image（$e）');
      return _weaponCache[image] = null;
    }
  }

  /// 載入人物 8 向 idle/walk sprite；缺 descriptor/圖檔時回 null。
  static Future<CharacterSpriteSet?> loadCharacterSprites(String key) async {
    if (_charCache.containsKey(key)) return _charCache[key];

    final descriptor = await _loadDescriptor();
    final rawSpec = _resolveSheetSpec(descriptor, key);
    if (rawSpec == null) {
      return _charCache[key] = null;
    }

    final l1 = rawSpec['l1'] as String?;
    if (l1 != null && l1.isNotEmpty) {
      return _charCache[key] = CharacterSpriteSet(
        animations: const {},
        frameSize: Vector2.zero(),
        stateFrameSizes: const {},
        stateOffsets: const {},
        // L1 圖集的每幀底邊就是著地點；這裡只是整體往下（正值）微調的像素數
        footOffsetY: (rawSpec['footOffsetY'] as num?)?.toDouble() ?? 0,
        renderScale: (rawSpec['renderScale'] as num?)?.toDouble() ?? 1.0,
        l1Path: l1,
      );
    }

    final data = CharacterSpriteData.fromJson(rawSpec);
    if (data.image.isEmpty) {
      return _charCache[key] = null;
    }

    try {
      final frameSize = Vector2(
        data.frameWidth.toDouble(),
        data.frameHeight.toDouble(),
      );
      final animations = <int, SpriteAnimation>{};
      for (final entry in data.states.entries) {
        final state = entry.key;
        final spec = entry.value;
        final img = await _chars.load(spec.image ?? data.image);
        final stateFrameSize = Vector2(
          (spec.frameWidth ?? data.frameWidth).toDouble(),
          (spec.frameHeight ?? data.frameHeight).toDouble(),
        );
        for (var dir = 0; dir < 8; dir++) {
          animations[CharacterSpriteSet.keyFor(
            state: state,
            facing: dir,
          )] = SpriteAnimation.fromFrameData(
            img,
            SpriteAnimationData.sequenced(
              textureSize: stateFrameSize,
              texturePosition: Vector2(
                spec.startColumn * stateFrameSize.x,
                dir * stateFrameSize.y,
              ),
              amount: spec.frameCount,
              stepTime: spec.stepTime,
              loop:
                  state == CharacterAnimationState.idle ||
                  state == CharacterAnimationState.walk,
            ),
          );
        }
      }

      final set = CharacterSpriteSet(
        animations: animations,
        frameSize: frameSize,
        footOffsetY: data.footOffsetY,
        renderScale: data.renderScale,
        stateFrameSizes: {
          for (final entry in data.states.entries)
            entry.key: Vector2(
              (entry.value.frameWidth ?? data.frameWidth).toDouble(),
              (entry.value.frameHeight ?? data.frameHeight).toDouble(),
            ),
        },
        stateOffsets: {
          for (final entry in data.states.entries)
            entry.key: entry.value.offsetY,
        },
      );
      return _charCache[key] = set;
    } catch (e) {
      debugPrint(
        'SceneAssetLoader: 人物 sprite 載入失敗 $key/${data.image}（$e），改用 fallback',
      );
      return _charCache[key] = null;
    }
  }

  static Map<String, dynamic>? _resolveSheetSpec(
    Map<String, dynamic>? descriptor,
    String key,
  ) {
    if (descriptor == null) return null;
    final sheets = descriptor['sheets'] as Map<String, dynamic>? ?? const {};
    final defaultKey = descriptor['defaultKey'] as String?;
    final raw = sheets[key] ?? (defaultKey != null ? sheets[defaultKey] : null);
    return raw is Map<String, dynamic> ? raw : null;
  }

  static Future<Map<String, dynamic>?> _loadDescriptor() async {
    if (_descriptorLoaded) return _descriptor;
    try {
      final raw = await rootBundle.loadString(_spriteDescriptorPath);
      _descriptor = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('SceneAssetLoader: 讀不到 $_spriteDescriptorPath（$e）');
      _descriptor = null;
    }
    _descriptorLoaded = true;
    return _descriptor;
  }
}

/// 怪物圖集的規格。一列一個 facing（0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N），
/// 一列裡由左到右是動畫的每一幀。
class MonsterSheetSpec {
  const MonsterSheetSpec({
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.anchorX,
    required this.anchorY,
  });

  final int frameWidth;
  final int frameHeight;
  final int frameCount;

  /// 著地點在格內的比例位置（0~1）。給 Flame 的 Anchor 用。
  final double anchorX;
  final double anchorY;

  factory MonsterSheetSpec.fromJson(Map<String, dynamic> j) => MonsterSheetSpec(
        frameWidth: (j['frameWidth'] as num?)?.toInt() ?? 64,
        frameHeight: (j['frameHeight'] as num?)?.toInt() ?? 96,
        frameCount: (j['frameCount'] as num?)?.toInt() ?? 1,
        anchorX: (j['anchorX'] as num?)?.toDouble() ?? 0.5,
        anchorY: (j['anchorY'] as num?)?.toDouble() ?? 1.0,
      );
}
