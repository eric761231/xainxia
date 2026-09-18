import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'iso_map_data.dart';
import 'iso_player_component.dart';
import 'l1_sprite_sheet.dart';

/// 場上的怪物。
///
/// 有美術的怪（見 [_sheetByName]）用 8 方向 sprite 動畫；其餘的仍用畫布畫的
/// 佔位圖形 —— 一格寬、比角色矮一截的深色身形，加上名字與血條。
///
/// 圖集的格子大小與錨點來自與 PNG 同名的 `.json`（由 DrawPng 的
/// `l1_sprite_to_sheet.py` 量出來），不寫死在這裡。
///
/// 位置一律由伺服器推動（S_MONSTER_PACK 的名單、S_NPC_MOVE 的每一步）。
class IsoMonsterComponent extends IsoPlayerComponent {
  IsoMonsterComponent({
    required this.objId,
    required this.monsterName,
    required this.maxHp,
    required this.currentHp,
    required super.initialTileX,
    required super.initialTileY,
    required super.mapData,
    super.initialFacing,
    this.showHpBar = true,
  });

  /// 是否畫血條。NPC（可對話、商店）沿用這個元件畫，但不打架也就不需要血條。
  final bool showHpBar;

  /// 頭上對話泡泡停留的秒數。
  static const double bubbleSeconds = 4.0;

  TextComponent? _bubble;
  double _bubbleLeft = 0;

  /// 目前頭上的對話（沒有回 null）。測試與除錯用。
  String? get bubbleText => _bubble?.text;

  /// 頭上顯示一句話（S_BUBBLE_DIALOG），[seconds] 秒後消失；新的一句會取代舊的。
  void say(String text, {double seconds = bubbleSeconds}) {
    if (text.isEmpty || _corpse) return;
    _bubble?.removeFromParent();
    _bubble = TextComponent(
      text: text,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -bodyHeightPx - 22),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFFFF4D6),
          shadows: [
            Shadow(blurRadius: 3, color: Color(0xE6000000), offset: Offset(1, 1)),
          ],
        ),
      ),
    );
    add(_bubble!);
    _bubbleLeft = seconds;
  }

  /// 角色 sprite 的一幀是 64×128 px（`character_sprites.json`）。
  /// 怪物矮一截，一眼就分得出誰是誰。
  static const double bodyHeightPx = 96;

  /// 身寬。一格是 64 px，留一點邊，避免視覺上溢出自己那一格。
  static const double bodyWidthPx = 52;

  /// 有美術的怪物 sprite 放大倍率（相對圖集原尺寸）。
  static const double spriteScale = 1.5;

  /// 屍體：死亡動畫播完、淡成半透明之後，停留這麼久再消失。
  static const double corpseSeconds = 3.0;

  /// 屍體的透明度。
  static const double corpseOpacity = 0.5;

  final int objId;
  final String monsterName;

  /// 血量。由 S_HP_UPDATE 更新（伺服器是廣播的，含怪物）。
  int maxHp;
  int currentHp;

  /// 走路時的上下起伏（px）。只有佔位圖形用得到。
  double _bob = 0;

  /// 有美術的怪用 L1 圖集；其餘的走底下畫布畫的佔位圖形。
  L1SpriteComponent? _sprite;
  TextComponent? _nameLabel;

  bool get hasVisibleName => _nameLabel != null;
  int? get spriteFacing => _sprite?.currentFacing;
  int? get spriteFrame => _sprite?.currentFrameIndex;

  /// 哪一種怪用哪一張圖。之後應該改成讀 npc 表的欄位 ——
  /// 現在只有一隻有美術，先用名字對照，不值得為此加一輪資料庫欄位。
  static const Map<String, String> _sheetByName = {
    '山野狼': 'assets/monsters/black_forest/mountain_wolf.png',
    // Mixamo 轉出來的怪（tools/sprites/mixamo_to_l1.py）。名稱是暫定的，
    // 要與伺服器 npc 表的名字一致才會套用；圖集還沒產生時載入失敗，照舊畫佔位圖形。
    '食人魔': 'assets/monsters/warrok.png',
    '哥布林': 'assets/monsters/goblin.png',
    '惡魔': 'assets/monsters/demon.png',
    '骷髏殭屍': 'assets/monsters/skeletonzombie.png',
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _nameLabel = TextComponent(
      text: monsterName,
      anchor: Anchor.bottomCenter,
      position: Vector2(0, -bodyHeightPx - 9),
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFFE0D6C2),
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 3)],
        ),
      ),
    );
    add(_nameLabel!);

    final path = _sheetByName[monsterName];
    if (path == null) return;
    final sheet = await L1SpriteSheetCache.load(path);
    if (sheet == null) return;
    _sprite = L1SpriteComponent(
      sheet: sheet,
      action: sheet.has('idle') ? 'idle' : 'walk',
      facing: facing,
      // 非整數倍放大，用平滑取樣，避免邊緣呈不規則階梯
      filterQuality: FilterQuality.medium,
    )..scale = Vector2.all(spriteScale);
    add(_sprite!);
  }

  /// 伺服器已經驗過牠的每一步，本地碰撞圖不該擋別人。
  @override
  bool canEnter(int tx, int ty) => true;

  @override
  bool get showsFacingArrow => false;

  // ── 移動節奏 ──────────────────────────────────────────────────────
  //
  // 伺服器走一格的間隔（目前 800ms，之後每隻怪各自不同）比玩家的 0.4 秒慢。
  // 用固定 0.4 秒播一格的話，怪物半路就走到定位、切回待機動作（低頭），
  // 等下一包到了再起步 —— 看起來就是「走一格、停一下、再走一格」。
  // 所以改成量測相鄰兩包 S_NPC_MOVE 的實際間隔，用那個時間播完一格。

  /// 還沒量到節奏前的預設（與伺服器目前的預設節奏一致）。
  static const double _defaultStepSeconds = 0.8;

  /// 量到的間隔只接受這個範圍；更長代表中間停過，不是移動節奏。
  static const double _minStepSeconds = 0.25;
  static const double _maxStepSeconds = 1.2;

  /// 到達格子後仍維持走路動作的寬限時間，吸收網路抖動造成的小空檔。
  static const double _walkLingerSeconds = 0.2;

  double _stepSecondsMeasured = _defaultStepSeconds;
  double _clock = 0;
  double? _lastServerStepAt;
  double _sinceArrived = double.infinity;

  @override
  double get stepSeconds => _stepSecondsMeasured;

  /// 目前的移動節奏（秒／格），測試與除錯用。
  double get measuredStepSeconds => _stepSecondsMeasured;

  /// 是否播放走路動作：移動中，或剛走到定位還在寬限時間內。
  /// 下一包通常馬上就到，這時切回待機動作會閃一下低頭。
  bool get walkAnimationActive =>
      isMoving || _sinceArrived < _walkLingerSeconds;

  /// 伺服器最後一次告知的位置。判斷「是不是一格」要跟它比，不能跟動畫目前的格子比：
  /// 封包比動畫快一點時動畫還在上一格，跟動畫比會誤判成兩格而瞬移。
  int? _serverX;
  int? _serverY;

  /// 動畫落後伺服器超過這麼多格就直接瞬移追上，不要一直補走。
  static const int _maxAnimationLag = 2;

  /// 伺服器說牠現在在這裡（S_NPC_MOVE 一次一格，所以幾乎都是走過去）。
  void applyServerPosition(int x, int y, {int? facing}) {
    final dx = x - (_serverX ?? tileX);
    final dy = y - (_serverY ?? tileY);
    _serverX = x;
    _serverY = y;
    final lagging = (x - tileX).abs() > _maxAnimationLag ||
        (y - tileY).abs() > _maxAnimationLag;
    if (dx.abs() > 1 || dy.abs() > 1 || lagging) {
      _lastServerStepAt = null; // 瞬移不是移動節奏
      snapTo(x, y, facing: facing);
      return;
    }
    if (dx != 0 || dy != 0) {
      _recordServerStep();
      this.facing = IsoPlayerComponent.facingFromDelta(dx, dy);
    } else if (facing != null) {
      this.facing = facing.clamp(0, 7);
    }
    moveTo(x, y);
  }

  /// 依相鄰兩次走格的間隔更新節奏；平滑處理，避免單一延遲的封包讓速度忽快忽慢。
  void _recordServerStep() {
    final last = _lastServerStepAt;
    _lastServerStepAt = _clock;
    if (last == null) return;
    final interval = _clock - last;
    if (interval < _minStepSeconds || interval > _maxStepSeconds * 1.5) return;
    final clamped = interval.clamp(_minStepSeconds, _maxStepSeconds);
    _stepSecondsMeasured = _stepSecondsMeasured * 0.6 + clamped * 0.4;
  }

  void applyHp(int hp, int max) {
    final wasAlive = currentHp > 0;
    currentHp = hp;
    if (max > 0) maxHp = max;
    // 血量歸零就先倒下；S_OBJECT_REMOVE 隨後才到，屍體由 [beginCorpse] 接手
    if (wasAlive && hp <= 0) playDeath();
  }

  // ── 屍體 ──────────────────────────────────────────────────────────

  bool _corpse = false;
  double _corpseElapsed = 0;
  double _fade = 0;
  void Function()? _onCorpseGone;

  /// 整隻怪（sprite、名字、血條）的透明度。
  double opacity = 1.0;

  bool get isCorpse => _corpse;

  /// 伺服器已移除這隻怪（死亡）：倒地 → 淡成半透明 → 停留 [corpseSeconds] 秒 → [onGone]。
  ///
  /// 伺服器在怪物死亡當下就送 S_OBJECT_REMOVE（重生用新的 objId），
  /// 所以屍體純粹是前端的表演，不牽涉任何狀態。
  void beginCorpse(void Function() onGone) {
    if (_corpse) return;
    _corpse = true;
    _onCorpseGone = onGone;
    _nameLabel?.removeFromParent();
    _nameLabel = null;
    if (!(_sprite?.holdLastFrame ?? false)) playDeath();
  }

  void _updateCorpse(double dt) {
    // 等死亡動畫播完才開始淡出；沒有 sprite 的佔位怪直接淡出
    final sprite = _sprite;
    if (sprite != null && !sprite.finished) return;
    const fadeSeconds = 0.25;
    if (_fade < fadeSeconds) {
      _fade = math.min(fadeSeconds, _fade + dt);
      opacity = 1 - (1 - corpseOpacity) * (_fade / fadeSeconds);
      return;
    }
    opacity = corpseOpacity;
    _corpseElapsed += dt;
    if (_corpseElapsed >= corpseSeconds) {
      final gone = _onCorpseGone;
      _onCorpseGone = null;
      gone?.call();
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (opacity >= 1) {
      super.renderTree(canvas);
      return;
    }
    // sprite、名字、血條是不同的子元件，整棵一起套透明度才不會各淡各的
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    super.renderTree(canvas);
    canvas.restore();
  }

  /// 轉向 (tx, ty)（地圖座標）。攻擊時要面向目標，否則會對著空氣揮爪。
  void faceToward(int tx, int ty) {
    final dx = (tx - tileX).clamp(-1, 1);
    final dy = (ty - tileY).clamp(-1, 1);
    if (dx == 0 && dy == 0) return;
    facing = IsoPlayerComponent.facingFromDelta(dx, dy);
  }

  @override
  void update(double dt) {
    _clock += dt;
    final wasMoving = isMoving;
    super.update(dt);
    _bob += dt;
    if (_corpse) {
      _updateCorpse(dt);
      return;
    }
    // 這一幀才剛走到的話，dt 大部分其實還在走；從下一幀起才開始算停了多久
    _sinceArrived = isMoving || wasMoving ? 0 : _sinceArrived + dt;
    final walking = walkAnimationActive;
    // 死亡動畫播完就停在最後一幀，不要被走／站蓋掉
    final sprite = _sprite;
    if (sprite != null && !sprite.holdLastFrame) {
      if (walking) {
        sprite.freeze = false;
        sprite.setState('walk', facing);
        sprite.setCycleProgress(movementProgress);
      } else if (sprite.sheet.has('idle')) {
        sprite.setCycleProgress(null);
        sprite.freeze = false;
        sprite.setState('idle', facing);
      } else {
        sprite.setCycleProgress(null);
        // 沒有待機動作就停在走路第 0 幀，不要原地踏步
        sprite.stand('walk', facing);
      }
    }

    final frameTop = sprite?.currentFrameBounds?.top;
    final visualTop = frameTop == null ? -bodyHeightPx : frameTop * spriteScale;
    _nameLabel?.position = Vector2(0, visualTop - 9);

    final bubble = _bubble;
    if (bubble != null) {
      bubble.position = Vector2(0, visualTop - 22);
      _bubbleLeft -= dt;
      if (_bubbleLeft <= 0) {
        bubble.removeFromParent();
        _bubble = null;
      }
    }
  }

  // 父類的這三個掛點是為角色的 CharacterSpriteSet 寫的（它靠
  // _transientState 計時）。怪物走的是 L1 圖集，動畫由 L1SpriteComponent
  // 自己推進，所以整個覆寫掉，不呼叫 super。
  @override
  void playAttack() {
    if (_corpse || currentHp <= 0) return;
    _sprite?.play('attack', facing);
  }

  /// 受傷不能打斷死亡 —— 最後一擊的 S_ATTACK 比血量歸零早到。
  @override
  void playHurt() {
    if (_corpse || currentHp <= 0) return;
    _sprite?.play('hurt', facing);
  }

  /// 倒下並停在最後一幀 —— 屍體不該站起來再倒一次。
  @override
  void playDeath() => _sprite?.play('death', facing, hold: true);

  @override
  void render(Canvas canvas) {
    final halfW = mapData.halfTileWidth;
    final halfH = mapData.halfTileHeight;

    // 接地陰影。與家具一樣是置中的環境遮蔽，不是有方向的投影 ——
    // 場上的光源約定是「從上方來」（見 stone_floor.dart）。
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 2),
        width: halfW * 1.1 * (_sprite != null ? spriteScale : 1),
        height: halfH * 0.55 * (_sprite != null ? spriteScale : 1),
      ),
      Paint()..color = const Color(0x66000000),
    );

    // 有 sprite 的怪只補血條與名字，身體交給 sprite 畫。
    // 名字與血條要浮在頭上，所以用「這一幀往上長多少」當高度。
    if (_sprite != null) {
      if (_corpse) return; // 屍體不畫血條
      final frameTop = _sprite!.currentFrameBounds?.top;
      final visualTop =
          frameTop == null ? -40.0 * spriteScale : frameTop * spriteScale;
      _drawHpBarAt(canvas, bodyWidthPx * 0.62 * spriteScale, visualTop - 6);
      return;
    }

    // 走路時輕微上下浮動；站著不動就完全靜止，才分得出有沒有在移動。
    final moving = isMoving;
    final bob = moving ? math.sin(_bob * 12) * 2.0 : 0.0;

    final w = bodyWidthPx;
    final h = bodyHeightPx;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(-w / 2, -h + bob, w, h),
      const Radius.circular(10),
    );

    canvas.drawRRect(body, Paint()..color = const Color(0xFF4A2E2A));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF1A0F0D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 上緣受光。與地磚同一個約定：光從上方來，只有朝上的邊會亮。
    canvas.drawLine(
      Offset(-w / 2 + 6, -h + bob + 2),
      Offset(w / 2 - 6, -h + bob + 2),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.4,
    );

    // 面向：一顆偏向前方的眼點，用來確認轉向有沒有跟著走
    final ang = _screenAngleOf(facing, halfW, halfH);
    canvas.drawCircle(
      Offset(math.cos(ang) * w * 0.22, -h * 0.72 + bob + math.sin(ang) * 4),
      3.2,
      Paint()..color = const Color(0xFFE8C86A),
    );

    final visualTop = -h + bob;
    if (!_corpse) _drawHpBarAt(canvas, w * 0.72, visualTop - 6);
  }

  void _drawHpBarAt(Canvas canvas, double w, double top) {
    if (!showHpBar || maxHp <= 0) return;
    const barH = 3.0;
    final barW = w;
    final rect = Rect.fromLTWH(-barW / 2, top, barW, barH);

    canvas.drawRect(rect, Paint()..color = const Color(0xCC1A1210));
    final frac = (currentHp / maxHp).clamp(0.0, 1.0);
    if (frac > 0) {
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2, top, barW * frac, barH),
        Paint()..color = const Color(0xFFC0392B),
      );
    }
  }

  /// facing(0-7) → 畫面角度。與等距投影一致：方向在螢幕上是壓扁的。
  static double _screenAngleOf(int facing, double halfW, double halfH) {
    // 0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N，對應 tile 位移
    const dx = [0, 1, 1, 1, 0, -1, -1, -1];
    const dy = [-1, -1, 0, 1, 1, 1, 0, -1];
    final f = facing.clamp(0, 7);
    final sx = (dx[f] - dy[f]) * halfW;
    final sy = (dx[f] + dy[f]) * halfH;
    return math.atan2(sy, sx);
  }
}

/// 建立一個怪物元件。
///
/// 沒有 sprite 要載，所以不必 async —— 但保留與 [createRemotePlayer] 相同的
/// 呼叫形狀，等美術到位改成載圖時，呼叫端不用跟著改。
IsoMonsterComponent createMonster({
  required int objId,
  required String name,
  required int x,
  required int y,
  required int facing,
  required int maxHp,
  required int currentHp,
  required IsoMapData mapData,
  bool showHpBar = true,
}) => IsoMonsterComponent(
  objId: objId,
  monsterName: name,
  maxHp: maxHp,
  currentHp: currentHp,
  initialTileX: x,
  initialTileY: y,
  initialFacing: facing,
  mapData: mapData,
  showHpBar: showHpBar,
);
