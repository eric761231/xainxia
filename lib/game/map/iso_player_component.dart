import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'floating_weapon_component.dart';
import 'iso_map_data.dart';
import 'iso_object_component.dart';
import 'l1_sprite_sheet.dart';
import 'scene_asset_loader.dart';

/// 面向定義（0-7，對應畫面方向順時針）：
/// 0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N
///
/// Tile 位移 → facing：
///   dy-1        → 0 (NE)
///   dx+1, dy-1  → 1 (E)
///   dx+1        → 2 (SE)
///   dx+1, dy+1  → 3 (S)
///   dy+1        → 4 (SW)
///   dx-1, dy+1  → 5 (W)
///   dx-1        → 6 (NW)
///   dx-1, dy-1  → 7 (N)
class IsoPlayerComponent extends PositionComponent {
  IsoPlayerComponent({
    required int initialTileX,
    required int initialTileY,
    required this.mapData,
    int initialFacing = 2,
    this.onStep,
    this.onFace,
    this.spriteSet,
    this.weaponVisual = WeaponVisual.none,
    this.displayName = '',
    this.vitalHp = 0,
    this.vitalHpMax = 0,
    this.vitalMp = 0,
    this.vitalMpMax = 0,
  }) : tileX = initialTileX.clamp(mapData.minMapCoord, mapData.maxMapCoordX),
       tileY = initialTileY.clamp(mapData.minMapCoord, mapData.maxMapCoordY),
       facing = initialFacing.clamp(0, 7),
       super(anchor: Anchor.center, size: Vector2.zero());

  final IsoMapData mapData;

  /// 人物 8 向 sprite（null 時回退為 canvas 手繪火柴人）。
  final CharacterSpriteSet? spriteSet;

  /// 前端武器視覺。裝備封包完成前，靈珠是第一個正式的預設原型。
  final WeaponVisual weaponVisual;

  /// 顯示在角色頭上的名稱；空字串表示不顯示。
  final String displayName;

  /// 頭頂小型狀態條的即時數值。max 為 0 時不顯示該條。
  int vitalHp;
  int vitalHpMax;
  int vitalMp;
  int vitalMpMax;

  /// sprite 動畫組（spriteSet 存在時使用）。
  SpriteAnimationGroupComponent<int>? _group;

  /// 用 L1 圖集時走這條（逐幀 offset），與 [_group] 二擇一。
  L1SpriteComponent? _l1;
  int _currentAnimKey = -1;
  CharacterAnimationState? _transientState;
  double _transientRemaining = 0;
  bool _dead = false;
  FloatingSwordComponent? _flyingSword;
  FloatingPearlComponent? _floatingPearl;

  /// 名牌文字高度（fontSize 11 的一行）。狀態條要疊在名牌上方，得先讓出這段。
  static const double _nameLabelHeight = 15.0;

  /// 名牌頂端與 MP 條底邊之間的間距。
  static const double _nameToBarsGap = 3.0;

  /// 每走一格回呼：(newX, newY, facing)，用於送出 C_MOVE 封包。
  final void Function(int x, int y, int facing)? onStep;

  /// 僅轉向回呼：(facing)，用於送出 C_FACE 封包。
  final void Function(int facing)? onFace;

  int tileX;
  int tileY;
  int facing; // 面向 0-7（預設 2=SE，由 initialFacing 設定）

  // ── 目標 tile（點選移動）─────────────────────────────────────
  int? _targetTileX;
  int? _targetTileY;

  /// 走向目標的逐格路徑（地圖座標，不含目前所在格），由 [moveTo] 尋路算出。
  final List<(int, int)> _path = [];

  /// 這一步出發的格子（地圖座標）。走動中判斷與家具的前後要同時看出發格與目的格。
  int _fromTileX = 0;
  int _fromTileY = 0;

  // ── 逐格動畫 ──────────────────────────────────────────────
  Vector2 _moveFrom = Vector2.zero();
  Vector2 _moveTo = Vector2.zero();
  double _moveProgress = 1.0; // 1.0 = 停止
  /// 走一格的時間（秒）。
  static const double stepDuration = 0.40;

  /// 這個角色實際走一格用的時間（秒）。玩家固定用 [stepDuration]；
  /// 怪物覆寫成伺服器實際的移動節奏，否則走完一格會停下來等下一包。
  double get stepSeconds => stepDuration;

  /// 一輪 walk 動畫（左右腳各跨一次）橫跨幾格。
  ///
  /// 以前一格就播完整輪 8 幀，每幀只有 0.04 秒，腳像在碎步。
  /// 改成兩格播一輪、每格半輪，步伐與位移才對得上。
  static const int stepsPerWalkCycle = 2;

  /// 目前這一步是 walk 循環裡的第幾步（0..stepsPerWalkCycle-1）。
  int _strideStep = 0;

  /// 停下來（沒在走）多久了。超過半格時間就當作真的停了，下次出發從第一步開始。
  /// 不在「路徑走完」當下歸零 —— 遠端玩家的移動封包之間本來就有一點空檔。
  double _idleTime = double.infinity;

  /// 走路動畫的循環進度 0..1（跨 [stepsPerWalkCycle] 格）。
  double get walkCycleProgress =>
      ((_strideStep + _moveProgress) / stepsPerWalkCycle).clamp(0.0, 1.0);

  bool get _isMoving => _moveProgress < 1.0;

  /// 是否正在移動動畫中。
  bool get isMoving => _isMoving;
  double get movementProgress => _moveProgress;
  bool get isDead => _dead;

  /// 是否還有待走的目標格。
  bool get hasTarget => _targetTileX != null;

  /// 停止且無待走目標（供互動框架判斷「已走到定位」）。
  bool get isIdle => !_isMoving && _targetTileX == null;

  @override
  Future<void> onLoad() async {
    _snapToTile();

    final set = spriteSet;
    final l1Path = set?.l1Path;
    if (l1Path != null) {
      // L1 圖集：每一幀自己帶 offset，元件原點就是著地點，所以不需要 anchor。
      // footOffsetY（顯示像素，正值往下）只做整體微調，讓腳踩進地板一點。
      final sheet = await L1SpriteSheetCache.load(l1Path);
      if (sheet != null) {
        _l1 = L1SpriteComponent(
          sheet: sheet,
          action: 'walk',
          facing: facing,
          // 整數倍：一個來源像素對應 N×N，點陣圖最銳利。非整數倍（1.5）用
          // nearest 會讓有些來源像素變 1px、有些變 2px，邊緣呈不規則階梯，
          // 所以改用平滑取樣。
          filterQuality: _isIntegerScale(_l1Scale)
              ? FilterQuality.none
              : FilterQuality.medium,
        )
          // L1 圖集原本忽略 renderScale，人物因此永遠是來源尺寸。
          // L1SpriteComponent.render 畫在區域座標，所以直接套元件的 scale 即可。
          ..scale = Vector2.all(_l1Scale)
          ..position = Vector2(0, set!.footOffsetY);
        add(_l1!);
      }
    } else if (set != null) {
      final size = set.frameSize * set.renderScale;
      _group = SpriteAnimationGroupComponent<int>(
        animations: set.animations,
        current: CharacterSpriteSet.keyFor(moving: false, facing: facing),
        size: size,
        anchor: Anchor.bottomCenter,
        // 站位：sprite 底部落在 tile 中心，footOffsetY 微調。
        // 位移是**逐 state** 的（見 offsetYFor）—— 倒下的身體會往畫面下方長，
        // 死亡的錨點必須放在格子內部，再由這裡推回來。
        position: Vector2(0, set.offsetYFor(CharacterAnimationState.idle)),
      );
      _currentAnimKey = CharacterSpriteSet.keyFor(
        moving: false,
        facing: facing,
      );
      add(_group!);
      switch (weaponVisual) {
        case WeaponVisual.none:
          break;
        case WeaponVisual.pearl:
          _floatingPearl = FloatingPearlComponent(
            facingProvider: () => facing,
            isMovingProvider: () => _isMoving,
          );
          add(_floatingPearl!);
        case WeaponVisual.flyingSword:
          _flyingSword = FloatingSwordComponent(
            facingProvider: () => facing,
            halfTileWidth: mapData.halfTileWidth,
            halfTileHeight: mapData.halfTileHeight,
          );
          add(_flyingSword!);
      }
    }

    if (displayName.trim().isNotEmpty) {
      add(
        TextComponent(
          text: displayName,
          anchor: Anchor.bottomCenter,
          position: Vector2(0, _nameBottomY),
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFE8E2D0),
              shadows: [Shadow(color: Color(0xFF000000), blurRadius: 3)],
            ),
          ),
        ),
      );
    }
  }

  /// 伺服器確認的攻擊演出。缺 action 圖時安全回退為原本 idle/walk。
  void playAttack() {
    if (_dead) return;
    if (_l1 == null && spriteSet?.has(CharacterAnimationState.attack) != true) {
      return;
    }
    _transientState = CharacterAnimationState.attack;
    _transientRemaining = 0.72;
    _flyingSword?.attack();
  }

  void playHurt() {
    if (_dead) return;
    if (_l1 == null && spriteSet?.has(CharacterAnimationState.hurt) != true) {
      return;
    }
    _transientState = CharacterAnimationState.hurt;
    _transientRemaining = 0.36;
  }

  /// 死亡永久鎖在最後一格，直到地圖／重生流程移除或重建元件。
  void playDeath() {
    if (_dead) return;
    _dead = true;
    _targetTileX = null;
    _targetTileY = null;
    _moveProgress = 1.0;
    _transientState = CharacterAnimationState.death;
    _flyingSword?.drop();
  }

  void _snapToTile() {
    position = _tileCenter(tileX, tileY);
    priority = mapData.characterLayer * kLayerStride + position.y.round();
    _moveFrom = position.clone();
    _moveTo = position.clone();
    _moveProgress = 1.0;
    _targetTileX = null;
    _targetTileY = null;
  }

  /// 地圖座標 → 該格中心的 local 螢幕座標。
  ///
  /// 投影一律在<b>陣列索引空間</b>進行（座標先減 coordOffset），
  /// 這樣不論伺服器的地圖邊界從 1 還是 31 開始，菱形都畫在同一個位置，
  /// 不必連動調整 hitbox 與底圖原點。
  Vector2 _tileCenter(int tx, int ty) {
    final sp = mapData.tileToScreen(mapData.toIndex(tx), mapData.toIndex(ty));
    return sp + Vector2(0, mapData.halfTileHeight);
  }

  /// 外部呼叫：設定目標 tile，角色沿尋路結果逐格行走。
  ///
  /// 目標被擋或走不到時，改走到「走得到的格子中離目標最近」的一格停下 ——
  /// 點到家具、牆邊時應該走過去停在旁邊，而不是原地沒反應。
  /// 連一步都走不了（被圍住）就只轉向目標。
  void moveTo(int tx, int ty) {
    if (_dead) return;
    final clampedTX = tx.clamp(mapData.minMapCoord, mapData.maxMapCoordX);
    final clampedTY = ty.clamp(mapData.minMapCoord, mapData.maxMapCoordY);
    _path.clear();
    if (clampedTX == tileX && clampedTY == tileY) {
      _targetTileX = null;
      _targetTileY = null;
      return;
    }
    _path.addAll(findPath(tileX, tileY, clampedTX, clampedTY));
    if (_path.isEmpty) {
      _targetTileX = null;
      _targetTileY = null;
      setFacing(_facingFromDelta(
        (clampedTX - tileX).clamp(-1, 1),
        (clampedTY - tileY).clamp(-1, 1),
      ));
      return;
    }
    _targetTileX = clampedTX;
    _targetTileY = clampedTY;
  }

  static const List<(int, int)> _neighbours = [
    (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1),
  ];

  /// 8 方向 BFS 尋路（地圖座標）。回傳不含起點的逐格路徑。
  ///
  /// 終點走不到時，回傳到「可到達格中離終點最近」那一格的路徑；起點本身
  /// 就是最近的則回空陣列。斜走不切角：兩側任一格被擋就不能斜穿，否則人會
  /// 從兩件家具之間的縫「擠」過去。
  List<(int, int)> findPath(int sx, int sy, int gx, int gy) {
    final minX = mapData.minMapCoord;
    final minY = mapData.minMapCoord;
    final maxX = mapData.maxMapCoordX;
    final maxY = mapData.maxMapCoordY;
    final w = maxX - minX + 1;
    final h = maxY - minY + 1;
    bool inside(int x, int y) =>
        x >= minX && x <= maxX && y >= minY && y <= maxY;
    if (!inside(sx, sy)) return const [];
    int dist2(int x, int y) => (x - gx) * (x - gx) + (y - gy) * (y - gy);

    final start = (sy - minY) * w + (sx - minX);
    final prev = List<int>.filled(w * h, -2); // -2 = 未拜訪
    prev[start] = -1;
    final queue = <int>[start];
    var best = start;
    var bestDist = dist2(sx, sy);
    final order = List.of(_neighbours);
    for (var head = 0; head < queue.length; head++) {
      final k = queue[head];
      final x = k % w + minX;
      final y = k ~/ w + minY;
      if (x == gx && y == gy) {
        best = k;
        break;
      }
      final d = dist2(x, y);
      if (d < bestDist) {
        bestDist = d;
        best = k;
      }
      // 先試朝終點的方向：等長路徑中挑看起來最直的那條
      order.sort((a, b) =>
          dist2(x + a.$1, y + a.$2).compareTo(dist2(x + b.$1, y + b.$2)));
      for (final (dx, dy) in order) {
        final nx = x + dx;
        final ny = y + dy;
        if (!inside(nx, ny)) continue;
        final nk = (ny - minY) * w + (nx - minX);
        if (prev[nk] != -2 || !canEnter(nx, ny)) continue;
        if (dx != 0 && dy != 0 &&
            (!canEnter(x + dx, y) || !canEnter(x, y + dy))) {
          continue;
        }
        prev[nk] = k;
        queue.add(nk);
      }
    }

    final path = <(int, int)>[];
    for (var k = best; k != start; k = prev[k]) {
      path.add((k % w + minX, k ~/ w + minY));
    }
    return path.reversed.toList();
  }

  /// 多格家具的前後修正：把 [base] 夾在「人在它前面的家具」與「人在它後面的家具」之間。
  ///
  /// 家具的 priority 取 footprint 最前面那一格（錨點）的腳底 y。人站在長書櫃、
  /// 雙格櫃子的側面時，明明在它前方，自己腳底的 y 卻可能比錨點小，於是被整個蓋住。
  /// 只看附近的家具：離很遠的在畫面上本來就不重疊，拿來夾反而可能夾出矛盾。
  int _resolveDepth(int base) {
    final siblings = parent?.children;
    if (siblings == null) return base;
    final cells = <(int, int)>[
      (mapData.toIndex(tileX), mapData.toIndex(tileY)),
      if (_isMoving) (mapData.toIndex(_fromTileX), mapData.toIndex(_fromTileY)),
    ];
    int? lower;
    int? upper;
    for (final o in siblings.whereType<IsoObjectComponent>()) {
      if (o.layer != mapData.characterLayer || o.def.isFlat) continue;
      final rel = depthRelation(cells, (
        o.tileX - o.def.footprintW + 1,
        o.tileY - o.def.footprintH + 1,
        o.tileX,
        o.tileY,
      ));
      if (rel > 0) {
        lower = lower == null ? o.priority : math.max(lower, o.priority);
      } else if (rel < 0) {
        upper = upper == null ? o.priority : math.min(upper, o.priority);
      }
    }
    return clampDepth(base, lower: lower, upper: upper);
  }

  /// 超過這個格數的家具不參與前後修正。
  static const int depthNeighbourhood = 3;

  /// 人（站在 [cells] 其中之一）相對一件家具的前後：1＝前、-1＝後、0＝太遠不相干。
  ///
  /// [rect] = (minX, minY, maxX, maxY)，陣列索引。拿人所在格與「footprint 中離人
  /// 最近的那一格」比深度（x+y）：大於等於就在前面。任一格在前就算在前 ——
  /// 從家具後方走出來時，不要等踩到格子中心才突然跳到前面。
  static int depthRelation(List<(int, int)> cells, (int, int, int, int) rect) {
    final (minX, minY, maxX, maxY) = rect;
    var behind = false;
    for (final (cx, cy) in cells) {
      final nx = cx.clamp(minX, maxX);
      final ny = cy.clamp(minY, maxY);
      if ((cx - nx).abs() > depthNeighbourhood ||
          (cy - ny).abs() > depthNeighbourhood) {
        continue;
      }
      if (cx + cy >= nx + ny) return 1;
      behind = true;
    }
    return behind ? -1 : 0;
  }

  /// 把 [base] 夾進 (lower, upper) 之間；兩者矛盾時以「在前面」為準。
  static int clampDepth(int base, {int? lower, int? upper}) {
    var p = base;
    if (upper != null && p >= upper) p = upper - 1;
    if (lower != null && p <= lower) p = lower + 1;
    return p;
  }

  /// 從目前所在格踏到 [cell] 是否合法：相鄰、可進入、斜走不切角。
  bool _isValidStep((int, int) cell) {
    final dx = cell.$1 - tileX;
    final dy = cell.$2 - tileY;
    if (dx.abs() > 1 || dy.abs() > 1 || (dx == 0 && dy == 0)) return false;
    if (!canEnter(cell.$1, cell.$2)) return false;
    return dx == 0 ||
        dy == 0 ||
        (canEnter(tileX + dx, tileY) && canEnter(tileX, tileY + dy));
  }

  /// 外部呼叫：無視動畫與碰撞，直接把角色瞬移到指定格。
  ///
  /// 用於伺服器的移動修正 —— 前端是「先本地走再送 C_MOVE」，伺服器若判定
  /// 該步非法會回送正確座標，此時必須硬拉回去，否則兩邊會永久不同步。
  /// 刻意不觸發 [onStep]，避免修正又送出一次 C_MOVE 形成迴圈。
  void snapTo(int tx, int ty, {int? facing}) {
    tileX = tx.clamp(mapData.minMapCoord, mapData.maxMapCoordX);
    tileY = ty.clamp(mapData.minMapCoord, mapData.maxMapCoordY);
    if (facing != null) {
      this.facing = facing.clamp(0, 7);
    }
    _snapToTile();
    _dead = false;
    _transientState = null;
    _flyingSword?.reset();
    _syncAnimation();
  }

  /// 外部呼叫：僅轉向，不移動，並觸發 [onFace] 回呼送出 C_FACE 封包。
  void setFacing(int newFacing) {
    final f = newFacing.clamp(0, 7);
    if (f == facing) return;
    facing = f;
    onFace?.call(f);
  }

  /// facing 計算工具（tile 位移 → facing 值）。
  static int facingFromDelta(int dx, int dy) => _facingFromDelta(dx, dy);

  /// 這一格能不能走進去。
  ///
  /// 抽成方法是為了讓遠端玩家覆寫 —— 別人的移動已經由伺服器驗過，
  /// 本地碰撞圖只是自己的預測，拿它去擋別人只會讓對方卡在錯的格子上。
  bool canEnter(int tx, int ty) => !mapData.isBlocked(tx, ty);

  /// 是否畫出面向箭頭。箭頭是「這是我」的提示，遠端玩家不需要。
  bool get showsFacingArrow => true;

  /// 人物 sprite 的 L1 縮放倍率；沒有設定時維持 1.0（＝原本的行為）。
  double get _l1Scale => spriteSet?.renderScale ?? 1.0;

  static bool _isIntegerScale(double scale) => (scale - scale.roundToDouble()).abs() < 1e-6;

  /// 名牌底邊的 y（區域座標，負值往上）。HP/MP 條也掛在它下面。
  ///
  /// 必須避開人物本身：放大之後 sprite 會長到 180px 高，固定的 82px 會讓名牌與
  /// 血條直接壓在身上。所以取「固定下限」與「實際影格頂端再往上一點」的較高者。
  double get _nameBottomY {
    final base = math.max(82.0, mapData.halfTileWidth * 2.75);
    final bounds = _l1?.currentFrameBounds;
    // currentFrameBounds 是未縮放的區域座標，top 為負；乘上 scale 才是實際高度。
    final spriteTop = bounds == null
        ? 0.0
        : -(bounds.top * _l1Scale + (_l1?.position.y ?? 0));
    final group = _group;
    final groupTop = group == null ? 0.0 : group.size.y;
    // 名牌緊貼在頭頂上方，狀態條再疊在名牌之上（見 _drawVitalBars）
    return -math.max(base, math.max(spriteTop, groupTop) + 10);
  }

  void applyVitals({
    required int hp,
    required int hpMax,
    required int mp,
    required int mpMax,
  }) {
    vitalHp = hp;
    if (hpMax > 0) vitalHpMax = hpMax;
    vitalMp = mp;
    if (mpMax > 0) vitalMpMax = mpMax;
  }

  void applyCharacterHp(int hp, int hpMax) {
    vitalHp = hp;
    if (hpMax > 0) vitalHpMax = hpMax;
  }

  void applyCharacterMp(int mp, int mpMax) {
    vitalMp = mp;
    if (mpMax > 0) vitalMpMax = mpMax;
  }

  /// [mapLocalPoint] 是地圖元件座標；依目前實際影格判斷是否點到角色本體。
  bool hitTestVisualPoint(Vector2 mapLocalPoint) {
    final local = mapLocalPoint - position;
    final point = Offset(local.x, local.y);

    final l1Bounds = _l1?.currentFrameBounds;
    if (l1Bounds != null) {
      // bounds 是未縮放的；放大之後點擊範圍必須跟著放大，否則只點得到腳附近。
      final scaled = Rect.fromLTWH(
        l1Bounds.left * _l1Scale,
        l1Bounds.top * _l1Scale + (_l1?.position.y ?? 0),
        l1Bounds.width * _l1Scale,
        l1Bounds.height * _l1Scale,
      );
      return scaled.inflate(4).contains(point);
    }

    final group = _group;
    if (group != null) {
      final bounds = Rect.fromLTWH(
        group.position.x - group.size.x / 2,
        group.position.y - group.size.y,
        group.size.x,
        group.size.y,
      );
      return bounds.inflate(4).contains(point);
    }

    final r = mapData.halfTileWidth * 0.30;
    return Rect.fromLTRB(
      -r * 1.2,
      -r * 4.2,
      r * 1.2,
      r * 0.5,
    ).inflate(4).contains(point);
  }

  @override
  void update(double dt) {
    if (!_dead && _transientState != null) {
      _transientRemaining -= dt;
      if (_transientRemaining <= 0) _transientState = null;
    }
    _syncAnimation();

    _idleTime = _isMoving ? 0 : _idleTime + dt;

    // 動畫進度
    if (_isMoving) {
      _moveProgress = (_moveProgress + dt / stepSeconds).clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom.x + (_moveTo.x - _moveFrom.x) * _moveProgress,
        _moveFrom.y + (_moveTo.y - _moveFrom.y) * _moveProgress,
      );
      if (_dead == false && _transientState == null) {
        _l1?.setCycleProgress(walkCycleProgress);
      }
    }

    // 深度排序：characterLayer 分層 + 腳底(position.y)，與物件（IsoObjectComponent）同一
    // 基準，讓 Flame 自動決定玩家在物件前或後（樹在屋後、花在門前）。
    // 多格家具再依格座標修正一次，見 [_resolveDepth]。
    priority = _resolveDepth(
        mapData.characterLayer * kLayerStride + position.y.round());

    // 必須完整抵達格子中心才踏下一步，避免連走時從 85% 瞬移到終點。
    if (_moveProgress < 1.0) return;

    final tx = _targetTileX;
    final ty = _targetTileY;
    if (tx == null || ty == null) return;

    // 路徑上的下一格。出發後才被擋住（有人放了家具、GM 改了碰撞），或被伺服器
    // 修正拉到別格而不再相鄰時，從目前位置重新尋路一次；還是走不了就停下。
    if (_path.isNotEmpty && !_isValidStep(_path.first)) {
      _path
        ..clear()
        ..addAll(findPath(tileX, tileY, tx, ty));
    }
    if (_path.isEmpty || !_isValidStep(_path.first)) {
      _path.clear();
      _targetTileX = null;
      _targetTileY = null;
      return;
    }
    final (newTX, newTY) = _path.removeAt(0);
    final dx = newTX - tileX;
    final dy = newTY - tileY;

    // 更新面向
    facing = _facingFromDelta(dx, dy);

    // 啟動動畫
    _moveFrom = _tileCenter(tileX, tileY);
    _moveTo = _tileCenter(newTX, newTY);
    _moveProgress = 0;
    // 連續走路時左右腳交替；停頓超過半格時間後重新出發就從第一步開始
    _strideStep = _idleTime > stepSeconds / 2
        ? 0
        : (_strideStep + 1) % stepsPerWalkCycle;
    _l1?.setCycleProgress(walkCycleProgress);
    _fromTileX = tileX;
    _fromTileY = tileY;
    tileX = newTX;
    tileY = newTY;

    // 送出移動封包
    onStep?.call(tileX, tileY, facing);
  }

  /// L1 圖集的動作名。與 `l1_sprite_to_sheet.py --actions` 或 3221.json 的動作名一致。
  static const Map<CharacterAnimationState, String> _l1ActionName = {
    CharacterAnimationState.idle: 'idle',
    CharacterAnimationState.walk: 'walk',
    CharacterAnimationState.attack: 'attack',
    CharacterAnimationState.hurt: 'hurt',
    CharacterAnimationState.death: 'death',
  };

  /// 依「是否移動 + 面向」切換 sprite 動畫（僅在有 spriteSet 時）。
  void _syncAnimation() {
    final l1 = _l1;
    if (l1 != null) {
      final state = _dead
          ? CharacterAnimationState.death
          : (_transientState ??
                (_isMoving
                    ? CharacterAnimationState.walk
                    : CharacterAnimationState.idle));
      final action = _l1ActionName[state] ?? 'walk';
      if (state != CharacterAnimationState.walk) {
        l1.setCycleProgress(null);
      }
      if (state == CharacterAnimationState.death) {
        if (!l1.holdLastFrame) l1.play('death', facing, hold: true);
      } else if (state == CharacterAnimationState.idle) {
        if (l1.sheet.has('idle')) {
          l1.freeze = false;
          l1.setState('idle', facing);
        } else {
          // 沒有獨立待機動作時，用走路的第 0 幀當站姿並停住
          l1.stand('walk', facing);
        }
      } else {
        l1.freeze = false;
        if (l1.sheet.has(action)) {
          l1.setState(action, facing);
        } else {
          l1.setState('walk', facing);
        }
      }
      return;
    }

    final group = _group;
    if (group == null) return;
    var state = _dead
        ? CharacterAnimationState.death
        : (_transientState ??
              (_isMoving
                  ? CharacterAnimationState.walk
                  : CharacterAnimationState.idle));
    if (!spriteSet!.has(state)) {
      state = _isMoving
          ? CharacterAnimationState.walk
          : CharacterAnimationState.idle;
    }
    final key = CharacterSpriteSet.keyFor(state: state, facing: facing);
    if (key != _currentAnimKey) {
      _currentAnimKey = key;
      group.current = key;
      // death 等橫向 frame 不可壓回站姿的 64px 寬；bottomCenter anchor
      // 保持不變，所以腳底／倒地接地點仍對齊同一個 tile 中心。
      group.size = spriteSet!.frameSizeFor(state) * spriteSet!.renderScale;
      // 垂直位移也要跟著換。死亡的格子比站姿高、錨點在格內（不在格底），
      // 沒有這一行的話整具屍體會浮在正確位置上方 offsetY 那麼多。
      group.position = Vector2(0, spriteSet!.offsetYFor(state));
    }
  }

  /// 腳底橢圓陰影。暫時關閉：它畫在格子中心，會讓腳看起來浮在陰影上方。
  static const bool showFootShadow = false;

  // ── 渲染 ──────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final r = mapData.halfTileWidth * 0.30;
    if (showFootShadow) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, 2), width: r * 2.4, height: r * 0.85),
        Paint()..color = const Color(0x55000000),
      );
    }

    // 有 sprite 時人物由子元件繪製，這裡只畫狀態條。
    if (_group != null || _l1 != null) {
      _drawVitalBars(canvas);
      return;
    }

    // 下半身（腳部）
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -r * 0.5), width: r * 1.4, height: r),
      Paint()..color = const Color(0xFFB05C20),
    );

    // 上半身
    canvas.drawCircle(
      Offset(0, -r * 2.0),
      r * 0.95,
      Paint()..color = const Color(0xFFE8A020),
    );
    canvas.drawCircle(
      Offset(0, -r * 2.0),
      r * 0.95,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 頭部
    canvas.drawCircle(
      Offset(0, -r * 3.4),
      r * 0.65,
      Paint()..color = const Color(0xFFF5C887),
    );
    canvas.drawCircle(
      Offset(0, -r * 3.4),
      r * 0.65,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 面向指示箭頭（畫在腳部）
    if (showsFacingArrow) {
      _drawFacingArrow(canvas, r);
    }
    _drawVitalBars(canvas);
  }

  void _drawVitalBars(Canvas canvas) {
    if (displayName.trim().isEmpty) return;
    const width = 84.0;
    const height = 9.0;
    const gap = 2.0;
    // 由上而下：HP、MP、名牌、頭頂。MP 條底邊落在名牌頂端再往上一點。
    final mpBottom = _nameBottomY - _nameLabelHeight - _nameToBarsGap;
    final hpTop = mpBottom - height - gap - height;
    _drawVitalBar(
      canvas,
      label: 'HP',
      top: hpTop,
      width: width,
      height: height,
      value: vitalHp,
      maxValue: vitalHpMax,
      color: const Color(0xFFD4473B),
    );
    _drawVitalBar(
      canvas,
      label: 'MP',
      top: hpTop + height + gap,
      width: width,
      height: height,
      value: vitalMp,
      maxValue: vitalMpMax,
      color: const Color(0xFF3D78C5),
    );
  }

  static void _drawVitalBar(
    Canvas canvas, {
    required String label,
    required double top,
    required double width,
    required double height,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    if (maxValue <= 0) return;
    final background = Rect.fromLTWH(-width / 2, top, width, height);
    canvas.drawRect(background, Paint()..color = const Color(0xDD171717));
    final fraction = (value / maxValue).clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawRect(
        Rect.fromLTWH(-width / 2, top, width * fraction, height),
        Paint()..color = color,
      );
    }

    final shownValue = value.clamp(0, maxValue);
    final percent = (fraction * 100).round();
    final text = TextPainter(
      text: TextSpan(
        text: '$label $shownValue / $maxValue  $percent%',
        style: const TextStyle(
          color: Color(0xFFF4F4F4),
          fontSize: 6.5,
          height: 1,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 1)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: width - 4);
    text.paint(
      canvas,
      Offset(-text.width / 2, top + (height - text.height) / 2),
    );
  }

  void _drawFacingArrow(Canvas canvas, double r) {
    final angle = _facingAngle(
      facing,
      mapData.halfTileWidth,
      mapData.halfTileHeight,
    );
    final arrowLen = r * 1.3;
    final dx = math.cos(angle) * arrowLen;
    final dy = math.sin(angle) * arrowLen;

    final tip = Offset(dx, dy);
    final base = Offset(-math.cos(angle) * r * 0.3, -math.sin(angle) * r * 0.3);
    final perp = Offset(
      -math.sin(angle) * r * 0.35,
      math.cos(angle) * r * 0.35,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
      ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFCC));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xAA000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  // ── 靜態工具 ──────────────────────────────────────────────

  static int _facingFromDelta(int dx, int dy) {
    if (dx == 0 && dy == -1) return 0;
    if (dx == 1 && dy == -1) return 1;
    if (dx == 1 && dy == 0) return 2;
    if (dx == 1 && dy == 1) return 3;
    if (dx == 0 && dy == 1) return 4;
    if (dx == -1 && dy == 1) return 5;
    if (dx == -1 && dy == 0) return 6;
    if (dx == -1 && dy == -1) return 7;
    return 2;
  }

  /// facing → 畫面角度（弧度，0=右，順時針增加）。
  static double _facingAngle(int f, double halfW, double halfH) {
    const deltas = [
      (0, -1),
      (1, -1),
      (1, 0),
      (1, 1),
      (0, 1),
      (-1, 1),
      (-1, 0),
      (-1, -1),
    ];
    final (ddx, ddy) = deltas[f.clamp(0, 7)];
    final sx = (ddx - ddy) * halfW;
    final sy = (ddx + ddy) * halfH;
    return math.atan2(sy, sx);
  }
}

/// 獨立於人物本體的浮游飛劍層。它不參與碰撞；死亡時落到目前面向的前方。
class FloatingSwordComponent extends PositionComponent {
  FloatingSwordComponent({
    required this.facingProvider,
    required this.halfTileWidth,
    required this.halfTileHeight,
  }) : super(anchor: Anchor.center, size: Vector2(32, 32));

  final int Function() facingProvider;
  final double halfTileWidth;
  final double halfTileHeight;
  double _attack = 0;
  double _drop = -1;

  void attack() {
    _attack = 0.72;
  }

  void drop() {
    _drop = 0;
    _attack = 0;
  }

  void reset() {
    _attack = 0;
    _drop = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_attack > 0) _attack = math.max(0, _attack - dt);
    if (_drop >= 0) _drop = math.min(1, _drop + dt / 0.72);
    final f = facingProvider();
    const dx = [0, 1, 1, 1, 0, -1, -1, -1];
    const dy = [-1, -1, 0, 1, 1, 1, 0, -1];
    final sx = (dx[f] - dy[f]) * halfTileWidth;
    final sy = (dx[f] + dy[f]) * halfTileHeight;
    if (_drop >= 0) {
      position = Vector2(sx * .46, sy * .46 + 8 * _drop);
    } else if (_attack > 0) {
      final p = math.sin((1 - _attack / .72) * math.pi);
      position = Vector2(
        sx * (.25 + .55 * p),
        sy * (.25 + .55 * p) - 16 * (1 - p),
      );
    } else {
      position = Vector2(
        18,
        -40 + math.sin(DateTime.now().millisecondsSinceEpoch / 300) * 2,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE7F3FF);
    canvas.save();
    canvas.rotate(_drop >= 0 ? .55 : -.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, -14, 4, 22),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawCircle(
      const Offset(0, 9),
      3,
      Paint()..color = const Color(0xFF5FC7E8),
    );
    canvas.restore();
  }
}
