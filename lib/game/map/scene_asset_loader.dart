import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 單一動畫狀態（idle / walk）的影格配置。
class CharacterStateSpec {
  const CharacterStateSpec({
    required this.startColumn,
    required this.frameCount,
    required this.stepTime,
  });

  final int startColumn;
  final int frameCount;
  final double stepTime;

  factory CharacterStateSpec.fromJson(Map<String, dynamic> j) => CharacterStateSpec(
        startColumn: (j['startColumn'] as num?)?.toInt() ?? 0,
        frameCount: (j['frameCount'] as num?)?.toInt() ?? 1,
        stepTime: (j['stepTime'] as num?)?.toDouble() ?? 0.15,
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
    required this.idle,
    required this.walk,
  });

  final String image;
  final int frameWidth;
  final int frameHeight;
  final double footOffsetY;
  final double renderScale;
  final CharacterStateSpec idle;
  final CharacterStateSpec walk;

  factory CharacterSpriteData.fromJson(Map<String, dynamic> j) {
    final states = j['states'] as Map<String, dynamic>? ?? const {};
    CharacterStateSpec state(String k, CharacterStateSpec fallback) {
      final v = states[k];
      return v is Map<String, dynamic> ? CharacterStateSpec.fromJson(v) : fallback;
    }

    return CharacterSpriteData(
      image: j['image'] as String? ?? '',
      frameWidth: (j['frameWidth'] as num?)?.toInt() ?? 64,
      frameHeight: (j['frameHeight'] as num?)?.toInt() ?? 96,
      footOffsetY: (j['footOffsetY'] as num?)?.toDouble() ?? 0,
      renderScale: (j['renderScale'] as num?)?.toDouble() ?? 1.0,
      idle: state('idle',
          const CharacterStateSpec(startColumn: 0, frameCount: 1, stepTime: 0.2)),
      walk: state('walk',
          const CharacterStateSpec(startColumn: 0, frameCount: 1, stepTime: 0.1)),
    );
  }
}

/// 人物 sprite 成品：8 向 × idle/walk 的動畫組。
class CharacterSpriteSet {
  const CharacterSpriteSet({
    required this.animations,
    required this.frameSize,
    required this.footOffsetY,
    required this.renderScale,
  });

  /// key = [keyFor]：state(0=idle,1=walk) * 8 + facing(0..7)。
  final Map<int, SpriteAnimation> animations;
  final Vector2 frameSize;
  final double footOffsetY;
  final double renderScale;

  /// 依「是否移動 + 面向」算出 [animations] 的 key。
  static int keyFor({required bool moving, required int facing}) =>
      (moving ? 1 : 0) * 8 + facing.clamp(0, 7);
}

/// 地圖場景資產讀取器：tile 圖集 + 人物 8 向 sprite。
///
/// 皆含快取；載入失敗一律回 `null`，由呼叫端沿用既有 fallback
/// （tile → 色塊菱形；人物 → canvas 火柴人），不讓缺圖造成崩潰。
class SceneAssetLoader {
  SceneAssetLoader._();

  static final Images _tiles = Images(prefix: 'assets/tiles/');
  static final Images _chars = Images(prefix: 'assets/characters/');

  static const _spriteDescriptorPath = 'assets/data/character_sprites.json';

  static final Map<String, ui.Image?> _tileCache = {};
  static final Map<String, CharacterSpriteSet?> _charCache = {};
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

  /// 載入人物 8 向 idle/walk sprite；缺 descriptor/圖檔時回 null。
  static Future<CharacterSpriteSet?> loadCharacterSprites(String key) async {
    if (_charCache.containsKey(key)) return _charCache[key];

    final descriptor = await _loadDescriptor();
    final rawSpec = _resolveSheetSpec(descriptor, key);
    if (rawSpec == null) {
      return _charCache[key] = null;
    }

    final data = CharacterSpriteData.fromJson(rawSpec);
    if (data.image.isEmpty) {
      return _charCache[key] = null;
    }

    try {
      final img = await _chars.load(data.image);
      final frameSize =
          Vector2(data.frameWidth.toDouble(), data.frameHeight.toDouble());
      final sheet = SpriteSheet(image: img, srcSize: frameSize);

      final animations = <int, SpriteAnimation>{};
      for (var dir = 0; dir < 8; dir++) {
        animations[CharacterSpriteSet.keyFor(moving: false, facing: dir)] =
            sheet.createAnimation(
          row: dir,
          stepTime: data.idle.stepTime,
          from: data.idle.startColumn,
          to: data.idle.startColumn + data.idle.frameCount,
        );
        animations[CharacterSpriteSet.keyFor(moving: true, facing: dir)] =
            sheet.createAnimation(
          row: dir,
          stepTime: data.walk.stepTime,
          from: data.walk.startColumn,
          to: data.walk.startColumn + data.walk.frameCount,
        );
      }

      final set = CharacterSpriteSet(
        animations: animations,
        frameSize: frameSize,
        footOffsetY: data.footOffsetY,
        renderScale: data.renderScale,
      );
      return _charCache[key] = set;
    } catch (e) {
      debugPrint(
          'SceneAssetLoader: 人物 sprite 載入失敗 $key/${data.image}（$e），改用 fallback');
      return _charCache[key] = null;
    }
  }

  static Map<String, dynamic>? _resolveSheetSpec(
      Map<String, dynamic>? descriptor, String key) {
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
