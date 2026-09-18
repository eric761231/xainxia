import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../network/packets/server/s_chat.dart';
import '../../network/packets/server/s_map_info.dart';
import '../../network/packets/server/s_game_over.dart';
import '../../network/packets/server/s_wave.dart';
import '../../game/party_member.dart';
import '../../models/game_character.dart';
import '../theme/game_panel_theme.dart';
import '../widgets/shared/character_stage.dart';
import '../widgets/shared/context_menu.dart';
import '../widgets/shared/notched_bar.dart';
import '../widgets/shared/tabbed_panel.dart';
import 'cultivation_panel.dart';
import 'decor_panel.dart';
import 'gm_panel.dart';
import 'inventory_panel.dart';
import 'social_panel.dart';

/// 遊戲世界 HUD（骨架版）。
///
/// 依修仙 MMORPG 版面規格排出 8 大區塊，資料先以假資料佔位，
/// 之後再接真系統（角色/隊伍/Buff/任務/聊天/貨幣/小地圖）。
///
/// 重要：根 [Material] 用 `MaterialType.transparency`，空白區不吸收點擊，
/// 讓地圖點擊能穿透到 GameWidget；中央大片區域保持淨空以利遊戲視野。
class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay(this.game, {super.key});
  final MyGame game;

  // 設計基準解析度（HUD 以此尺寸為 1.0 倍）。
  static const double _designW = 1920;
  static const double _designH = 1080;

  /// 面板與快捷鈕的額外放大倍率。
  ///
  /// `_Scaled` 就是 `Transform.scale`，所以乘一個係數就能同時放大
  /// 尺寸與文字，不必去改幾十個硬編碼的寬高與字級。
  /// **不套用在小地圖與貨幣列** —— 那兩者沒有要求放大，且小地圖還得縮。
  static const double _panelBoost = 1.1;

  /// 小地圖直徑的上下限。上限是原本的固定值。
  static const double _minimapMax = 220;
  static const double _minimapMin = 120;

  /// 血魔條與等級菱形往下位移的距離（px，設計基準）。要微調就改這裡。
  static const double _vitalBarDrop = 18;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1600 || constraints.maxHeight < 900) {
              return _CompactHud(game);
            }
            // 依視窗等比例縮放（取寬/高比較小值，不變形），並夾在合理範圍。
            final scale = math
                .min(
                  constraints.maxWidth / _designW,
                  constraints.maxHeight / _designH,
                )
                .clamp(0.45, 1.4);

            // 小地圖不得超出畫面下緣：由可用高度反推直徑。
            // 右下角那一欄由上而下是 貨幣列 + 小地圖 + 兩排快捷鈕，
            // 固定 220 的話，手機橫向（約 426 邏輯px 高）會整欄溢出。
            // 右下欄由上而下是 貨幣列 + 小地圖 + 最多兩排快捷鈕。
            // 扣掉其餘元件後剩多少高度，小地圖就畫多大 —— 寫死 220 的話，
            // 手機橫向（約 426 邏輯px 高）整欄會超出畫面下緣。
            final colScale = scale * _panelBoost;
            final reservedH = (34 + _cellGap * 3 + _cell * 2) * colScale;
            final minimapSize = ((constraints.maxHeight - reservedH) / colScale)
                .clamp(_minimapMin, _minimapMax);

            return Stack(
              children: [
                // 底部不透明 dock：聊天/快捷/小地圖以下不顯示遊戲畫面（以此為界）。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 300 * scale,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xEE152629),
                      border: Border(
                        top: BorderSide(color: Color(0x26C9A24B), width: 1),
                      ),
                    ),
                  ),
                ),
                // 左上：隊伍欄（可拖曳移動；寬高與任務一致）
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Scaled(
                    Alignment.topLeft,
                    scale * _panelBoost,
                    _DraggablePanel(child: _PartyPanel(game)),
                  ),
                ),
                // 右上：任務追蹤（可拖曳移動；寬高與隊伍一致）
                Positioned(
                  top: 12,
                  right: 12,
                  child: _Scaled(
                    Alignment.topRight,
                    scale * _panelBoost,
                    const _DraggablePanel(child: _QuestPanel()),
                  ),
                ),
                // 左下（貼底）：5×2 熱鍵格 + 左側快捷選單
                Positioned(
                  bottom: 0,
                  left: 12,
                  child: _Scaled(
                    Alignment.bottomLeft,
                    scale * _panelBoost,
                    _ActionBars(game),
                  ),
                ),
                // 中下（貼底）：中央生命條 + 聊天（無框、加寬）
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Scaled(
                      Alignment.bottomCenter,
                      scale * _panelBoost,
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 貨幣列坐在血魔條正上方 —— 那是視線焦點，
                          // 比擠在右下角小地圖上方好找。
                          Transform.translate(
                            offset: const Offset(0, _vitalBarDrop),
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: _CurrencyRow(),
                            ),
                          ),
                          // 往下位移一段，讓血魔條與等級菱形坐進底部 dock 裡，
                          // 而不是浮在遊戲畫面上。用 Transform 而非改 Column 間距，
                          // 是因為它不影響版面尺寸 —— 聊天面板的位置不會被推動。
                          Transform.translate(
                            offset: const Offset(0, _vitalBarDrop),
                            child: _VitalBarBinding(game),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -14),
                            child: _ChatPanel(game, width: 560),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 上方中央：波次指示（僅有波次的地圖顯示）
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Scaled(
                      Alignment.topCenter,
                      scale * _panelBoost,
                      _WaveBanner(game),
                    ),
                  ),
                ),
                // 洞府布置面板（浮動；僅開啟時顯示）
                Positioned(
                  top: 90,
                  right: 340,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.decorPanelOpenNotifier,
                    builder: (context, open, child) => !open
                        ? const SizedBox.shrink()
                        : _Scaled(Alignment.topRight, scale, DecorPanel(game)),
                  ),
                ),
                // GM 面板（浮動於中央；僅 GM 且開啟時顯示）
                Positioned(
                  top: 90,
                  left: 340,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.gmPanelOpenNotifier,
                    builder: (context, open, child) => !open
                        ? const SizedBox.shrink()
                        : _Scaled(Alignment.topLeft, scale, GmPanel(game)),
                  ),
                ),
                // 右下（貼底）：小地圖（在聊天界線下方）+ 右側快捷選單
                //
                // 整欄共用<b>一個</b> _Scaled。不能為了讓小地圖與快捷列有不同
                // 倍率而各包一個 —— _Scaled 是 Transform.scale，只改繪製、
                // 不改版面尺寸，兩個兄弟各自縮放會在中間留下大片空隙。
                // 小地圖不跟著放大的作法改為：直徑先除以 _panelBoost 抵銷。
                Positioned(
                  bottom: 0,
                  right: 12,
                  child: _Scaled(
                    Alignment.bottomRight,
                    scale * _panelBoost,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopRightPanel(
                          game.mapInfoNotifier,
                          game.playerMarkNotifier,
                          minimapSize: minimapSize / _panelBoost,
                        ),
                        const SizedBox(height: _cellGap),
                        // 布置按鈕已移到左側快捷列的「背包」旁邊。
                        // GM 入口已移除 —— 改為「右鍵自己的角色」跳選單。
                        // 那顆按鈕會擠掉右下角版面，而且一般玩家不該看到。
                        // 秘境放在商城旁邊。在洞府是「進去」，在秘境裡是「出來」——
                        // 同一個位置兩種語意，因為玩家在任何時刻都只可能想做其中一件。
                        // 「秘境」的圖示與動作要跟著所在地圖換，所以整列
                        // 掛在 mapInfo 上重建。
                        ValueListenableBuilder<SMapInfo?>(
                          valueListenable: game.mapInfoNotifier,
                          builder: (context, info, child) {
                            final inChallenge =
                                info != null &&
                                info.mapId == game.challengeMapId;
                            return _QuickMenu([
                              if (game.challengeMapId >= 0)
                                inChallenge
                                    ? (
                                        Icons.exit_to_app,
                                        '離開秘境',
                                        game.leaveChallenge,
                                      )
                                    : (
                                        Icons.local_fire_department_outlined,
                                        '秘境',
                                        game.enterChallenge,
                                      ),
                              (
                                Icons.storefront,
                                '商城',
                                () => debugPrint('[HUD] 商城'),
                              ),
                              (
                                Icons.settings,
                                '設定',
                                () => debugPrint('[HUD] 設定'),
                              ),
                              (
                                Icons.logout,
                                '離開',
                                () => unawaited(game.logoutToAccount()),
                              ),
                              (
                                Icons.self_improvement,
                                '修練',
                                () => game.cultivationPanelOpenNotifier.value =
                                    !game.cultivationPanelOpenNotifier.value,
                              ),
                            ]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 社交面板（浮動；僅開啟時顯示）
                // 與 GM 面板同在左側，錯開 40px —— 兩個都開時才不會完全重疊
                // （面板可拖曳，玩家仍能自行排開）
                Positioned(
                  top: 130,
                  left: 380,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.socialPanelOpenNotifier,
                    builder: (context, open, child) => !open
                        ? const SizedBox.shrink()
                        : _Scaled(
                            Alignment.topLeft,
                            scale * _panelBoost,
                            SocialPanel(game),
                          ),
                  ),
                ),
                // 背包面板（浮動；僅開啟時顯示）
                Positioned(
                  top: 130,
                  left: 90,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.inventoryPanelOpenNotifier,
                    builder: (context, open, child) => !open
                        ? const SizedBox.shrink()
                        : _Scaled(
                            Alignment.topLeft,
                            scale * _panelBoost,
                            InventoryPanel(game),
                          ),
                  ),
                ),
                // 修練面板（浮動；僅開啟時顯示）
                // 與布置面板同在右側，同樣錯開
                Positioned(
                  top: 130,
                  right: 380,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.cultivationPanelOpenNotifier,
                    builder: (context, open, child) => !open
                        ? const SizedBox.shrink()
                        : _Scaled(
                            Alignment.topRight,
                            scale * _panelBoost,
                            CultivationPanel(game),
                          ),
                  ),
                ),
                // 挑戰結算：蓋在 HUD 之上、但在右鍵選單之下。
                // 同樣必須是 Positioned（見下方那段註解）。
                Positioned.fill(child: _GameOverScreen(game)),
                // 右鍵／長按選單：疊在所有東西之上，否則會被面板蓋住。
                //
                // 這個 Positioned.fill 是必要的，不是排版偏好 ——
                // 本 Stack 的子元件<b>必須全部是 Positioned</b>。
                // RenderStack 的尺寸規則會因此分歧：沒有非 Positioned 子元件時
                // 取 constraints.biggest（撐滿），有的話則取「最大子元件」；
                // 而 Flame 是把 overlay 當非 Positioned 子元件塞進自己的 Stack，
                // HUD 拿到的是寬鬆約束（min 為 0）。兩者相乘的結果是：
                // 只要這裡放一個沒有選單時為 0×0 的裸元件，整個 HUD 就會
                // 塌陷成 0×0，再被預設的 Clip.hardEdge 裁光 —— 畫面全黑。
                // 這個 bug 發生過一次，回歸測試在 test/ui/hud_layout_test.dart。
                Positioned.fill(
                  child: ValueListenableBuilder<ContextMenuRequest?>(
                    valueListenable: game.contextMenuNotifier,
                    builder: (context, req, child) => req == null
                        ? const SizedBox.shrink()
                        : ContextMenuOverlay(
                            request: req,
                            onDismiss: game.dismissContextMenu,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 以設計基準比例縮放區塊：`Transform.scale` 只縮內容、不改版面錨點，
/// 配合 [alignment] 對齊貼的螢幕角，讓縮放後各區塊仍釘在原邊角。
class _Scaled extends StatelessWidget {
  const _Scaled(this.alignment, this.scale, this.child);

  final Alignment alignment;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(scale: scale.clamp(1.0, 1.4), alignment: alignment, child: child);
  }
}

/// Compact windows use disclosure, not miniature text and hit targets.
class _CompactHud extends StatefulWidget {
  const _CompactHud(this.game);
  final MyGame game;
  @override
  State<_CompactHud> createState() => _CompactHudState();
}

class _CompactHudState extends State<_CompactHud> {
  String? _section;
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return LayoutBuilder(builder: (context, c) => Stack(fit: StackFit.expand, children: [
      Positioned(top: 8, left: 8, right: 8, child: Align(alignment: Alignment.topCenter,
        child: _WaveBanner(game))),
      Positioned(left: 8, right: 8, bottom: 8, child: DecoratedBox(
        decoration: PanelTheme.panelDeco(), child: Column(mainAxisSize: MainAxisSize.min, children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: _VitalBarBinding(game)),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: Row(children: [
              for(final label in ['快捷', '聊天', '隊伍', '任務', '地圖'])
                GameAction(label, primary: _section == label,
                  onPressed: () => setState(() => _section = _section == label ? null : label)),
              GameAction('背包', onPressed: () => game.inventoryPanelOpenNotifier.value = !game.inventoryPanelOpenNotifier.value),
              GameAction('社交', onPressed: () => game.socialPanelOpenNotifier.value = !game.socialPanelOpenNotifier.value),
              GameAction('修練', onPressed: () => game.cultivationPanelOpenNotifier.value = !game.cultivationPanelOpenNotifier.value),
              GameAction('布置', onPressed: () => game.decorPanelOpenNotifier.value = !game.decorPanelOpenNotifier.value),
              if(game.challengeMapId >= 0) ValueListenableBuilder<SMapInfo?>(
                valueListenable: game.mapInfoNotifier, builder: (_, info, child) =>
                  GameAction(info?.mapId == game.challengeMapId ? '離開秘境' : '秘境',
                    onPressed: info?.mapId == game.challengeMapId ? game.leaveChallenge : game.enterChallenge)),
              GameAction('離開', onPressed: () => unawaited(game.logoutToAccount())),
            ])),
        ]))),
      if(_section != null) Positioned(top: 48, bottom: 138, left: 8, right: 8,
        child: Align(alignment: Alignment.bottomLeft, child: SingleChildScrollView(
          child: Container(decoration: PanelTheme.panelDeco(),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GameAction('收合', onPressed: () => setState(() => _section = null)),
              switch(_section) {
                '聊天' => _ChatPanel(game, width: math.min(560, c.maxWidth - 16)),
                '隊伍' => _PartyPanel(game),
                '任務' => const _QuestPanel(),
                '地圖' => _TopRightPanel(game.mapInfoNotifier, game.playerMarkNotifier, minimapSize: 180),
                _ => _ActionBars(game),
              },
            ]))))),
      for(final panel in <(ValueListenable<bool>, Widget)>[
        (game.inventoryPanelOpenNotifier, InventoryPanel(game)),
        (game.socialPanelOpenNotifier, SocialPanel(game)),
        (game.cultivationPanelOpenNotifier, CultivationPanel(game)),
        (game.decorPanelOpenNotifier, DecorPanel(game)),
        (game.gmPanelOpenNotifier, GmPanel(game)),
      ]) Positioned(top: 12, bottom: 138, left: 8, right: 8,
        child: ValueListenableBuilder<bool>(valueListenable: panel.$1,
          builder: (_, open, child) => !open ? const SizedBox.shrink() :
            Align(alignment: Alignment.topCenter, child: SingleChildScrollView(
              child: panel.$2)))),
      Positioned.fill(child: _GameOverScreen(game)),
      Positioned.fill(child: ValueListenableBuilder<ContextMenuRequest?>(
        valueListenable: game.contextMenuNotifier,
        builder: (_, req, child) => req == null ? const SizedBox.shrink() :
          ContextMenuOverlay(request: req, onDismiss: game.dismissContextMenu))),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 共用樣式
// ─────────────────────────────────────────────────────────────────────────

// 這四個是 PanelTheme 的別名。HUD 內有數百處引用，逐一改寫既冗長又容易
// 漏掉；保留名稱、把實作指向共用主題，等於一次讓整個 HUD 跟著扁平化。
const _gold = PanelTheme.gold;
const _goldBright = PanelTheme.goldBright;

BoxDecoration _panelDeco({double radius = PanelTheme.radius}) =>
    PanelTheme.panelDeco(r: radius);

TextStyle _ts({
  double size = 13,
  Color color = Colors.white,
  FontWeight weight = FontWeight.normal,
}) => PanelTheme.ts(size: size, color: color, weight: weight);

/// 可拖曳移動的面板包裝：長按拖曳改變位移（相對原錨點）。
class _DraggablePanel extends StatefulWidget {
  const _DraggablePanel({required this.child});
  final Widget child;

  @override
  State<_DraggablePanel> createState() => _DraggablePanelState();
}

class _DraggablePanelState extends State<_DraggablePanel> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (d) => setState(() => _offset += d.delta),
        child: widget.child,
      ),
    );
  }
}

/// 標準進度條（HP/MP/EXP）。
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color, this.height = 13});

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.75), color],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ① 人物資訊
// ─────────────────────────────────────────────────────────────────────────

/// 佔位圖：需要美術圖片的位置（頭像、小地圖底圖、圖示…）先用簡易扁平佔位。
/// 之後把真圖以相同尺寸放進來即可（尺寸見程式各處 width/height）。
class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder({
    required this.width,
    required this.height,
    this.circle = false,
  });

  final double width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final side = width < height ? width : height;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF17130D),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: _gold.withValues(alpha: 0.5),
        size: side * 0.42,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 隊伍欄
// ─────────────────────────────────────────────────────────────────────────

class _PartyPanel extends StatelessWidget {
  const _PartyPanel(this.game);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PartyMember>>(
      valueListenable: game.partyMembersNotifier,
      builder: (context, members, child) => Container(
        width: 300,
        height: 300,
        decoration: PanelTheme.panelDeco(),
        child: Column(
          // 有 Expanded 時主軸必須是 max（預設），不可用 min
          children: [
            Row(children: [_tab('隊友', true), _tab('靈寵', false)]),
            const Divider(height: 1, color: PanelTheme.divider),
            // 成員列表：吃「剩餘」空間，不能寫死高度 —— 那會擠掉同一個 Column
            // 裡的頁籤、分隔線與底部按鈕，造成 RenderFlex 溢出（黃黑條紋）。
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Text(
                        '目前沒有隊伍',
                        style: PanelTheme.ts(
                          size: 12,
                          color: PanelTheme.textFaint,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      itemCount: members.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _PartyMemberRow(game: game, member: members[i]),
                    ),
            ),
            // 底部：離開隊伍（原本這裡是寫死「1 / 2」的分頁列）
            if (members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: PanelButton(
                  label: '離開隊伍',
                  danger: true,
                  expand: true,
                  onTap: game.leaveParty,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? PanelTheme.cellBgActive : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: PanelTheme.ts(
            size: 13,
            color: active ? PanelTheme.goldBright : PanelTheme.textDim,
            weight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PartyMemberRow extends StatelessWidget {
  const _PartyMemberRow({required this.game, required this.member});

  final MyGame game;
  final PartyMember member;

  /// 右鍵（桌機）／長按（觸控）跳出隊伍操作選單。
  ///
  /// 自己那一列不給「驅逐」與「委任隊長」—— 對自己做這兩件事沒有意義，
  /// 離開隊伍走底部的按鈕。
  void _openMenu(Offset pos) {
    if (member.isSelf) return;
    game.showContextMenu(
      ContextMenuRequest(
        position: pos,
        title: member.name,
        items: [
          ContextMenuItem('委任隊長', () => game.promotePartyLeader(member.name)),
          ContextMenuItem(
            '驅逐隊員',
            () => game.kickPartyMember(member.name),
            danger: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (d) => _openMenu(d.globalPosition),
      onLongPressStart: (d) => _openMenu(d.globalPosition),
      child: Row(
        children: [
          // 頭像（佔位圖 40×40 圓形）+ 等級角標
          Stack(
            children: [
              const _ImgPlaceholder(width: 40, height: 40, circle: true),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC17130D),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${member.level}',
                    style: PanelTheme.ts(
                      size: 9,
                      color: PanelTheme.goldBright,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 隊長以皇冠標示，比在名字後面加文字省空間
                    if (member.isLeader) ...[
                      const Icon(
                        Icons.workspace_premium,
                        size: 12,
                        color: PanelTheme.goldBright,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PanelTheme.ts(size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _Bar(
                  fraction: member.hpFraction,
                  color: const Color(0xFFC0392B),
                  height: 7,
                ),
                const SizedBox(height: 2),
                _Bar(
                  fraction: member.mpFraction,
                  color: const Color(0xFF2E6FC0),
                  height: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(member.icon, size: 16, color: PanelTheme.goldBright),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────
// ③ 聊天視窗
// ─────────────────────────────────────────────────────────────────────────

/// 波次指示：第幾波、還剩幾隻、下一波倒數。
///
/// 沒有波次的地圖（waveNotifier 為 null 或 wave 為 0）完全不佔版面 ——
/// 洞府平時是家，不該一直掛著戰鬥資訊。
class _WaveBanner extends StatelessWidget {
  const _WaveBanner(this.game);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SWave?>(
      valueListenable: game.waveNotifier,
      builder: (context, w, child) {
        if (w == null || !w.isActive) return const SizedBox.shrink();

        // 休息中顯示倒數，戰鬥中顯示剩餘敵數 —— 同一塊位置兩種資訊，
        // 玩家在任何時刻都只需要知道其中一個
        final resting = w.isResting;
        final label = resting ? '下一波 ${w.breakLeft}' : '剩餘 ${w.alive}';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: PanelTheme.panelBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PanelTheme.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '第 ${w.wave} 波',
                style: PanelTheme.ts(
                  size: 15,
                  color: PanelTheme.goldBright,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 14, color: PanelTheme.divider),
              const SizedBox(width: 12),
              Text(
                label,
                style: PanelTheme.ts(
                  size: 13,
                  color: resting ? PanelTheme.textDim : const Color(0xFFE08A8A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 挑戰結算畫面。
///
/// 收到 S_GAME_OVER 時角色**已經**被伺服器送回洞府了 —— 這是成績單，
/// 不是「還在地圖上等復活」。所以底下透出來的是洞府，兩個按鈕也都
/// 只是「要不要再進去一次」，沒有任何一個是必選的。
class _GameOverScreen extends StatelessWidget {
  const _GameOverScreen(this.game);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SGameOver?>(
      valueListenable: game.gameOverNotifier,
      builder: (context, r, child) {
        if (r == null) return const SizedBox.shrink();

        return ColoredBox(
          color: const Color(0xCC000000),
          child: Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: PanelTheme.panelDeco(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '道消身殞',
                    style: PanelTheme.ts(
                      size: 24,
                      color: PanelTheme.goldBright,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已被送回洞府，可再入秘境',
                    style: PanelTheme.ts(size: 12, color: PanelTheme.textDim),
                  ),
                  const SizedBox(height: 20),
                  _row('抵達波次', '第 ${r.wave} 波'),
                  _row('擊殺', '${r.kills}'),
                  _row('存活', r.survivedText),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _button(
                          '再挑戰',
                          game.enterChallenge,
                          primary: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _button('留在洞府', game.dismissGameOver)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PanelTheme.ts(size: 13, color: PanelTheme.textDim)),
        Text(value, style: PanelTheme.ts(size: 15, weight: FontWeight.bold)),
      ],
    ),
  );

  static Widget _button(
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      alignment: Alignment.center,
      decoration: PanelTheme.cellDeco(active: primary),
      child: Text(
        label,
        style: PanelTheme.ts(
          size: 14,
          color: primary ? PanelTheme.goldBright : Colors.white,
          weight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// 把中央生命條接到伺服器的真實數值。
///
/// 資料來源是 `liveStatsNotifier` —— 進圖時由角色資料填入，之後由
/// S_HP_UPDATE／S_MP_UPDATE／升級／突破的處理各自回寫。
/// 尚未進圖（或還沒收到角色資料）時顯示空條，而不是假數字。
class _VitalBarBinding extends StatelessWidget {
  const _VitalBarBinding(this.game);

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    final service = game.gameWorldService;
    if (service == null) {
      return const _CenterVitalBar(
        level: 1,
        hpFraction: 0,
        mpFraction: 0,
        expFraction: 0,
        width: 560,
      );
    }
    return ValueListenableBuilder<GameCharacter?>(
      valueListenable: service.liveStatsNotifier,
      builder: (context, c, child) => _CenterVitalBar(
        level: c?.level ?? 1,
        hpFraction: c?.hpFraction ?? 0,
        mpFraction: c?.mpFraction ?? 0,
        expFraction: c?.expFraction ?? 0,
        width: 560,
      ),
    );
  }
}

/// 中央生命條：左 HP（紅）、右 MP（藍），中央菱形顯示等級與經驗%，菱形外框＝經驗條。
///
/// 三者**咬合成一條完整的橫幅**：HP 的右端與 MP 的左端各切出一個 V 形凹口，
/// 角度與菱形的斜邊完全相同，菱形正好嵌進去。
class _CenterVitalBar extends StatelessWidget {
  const _CenterVitalBar({
    this.level = 75,
    this.hpFraction = 1.0,
    this.mpFraction = 1.0,
    this.expFraction = 0.638,
    this.width = 460,
  });

  final int level;
  final double hpFraction;
  final double mpFraction;
  final double expFraction;
  final double width;

  static const _diamond = 60.0;

  /// 條高＝菱形高。兩者共用同一個常數，日後改尺寸不會分家。
  static const _barH = _diamond;

  /// 凹口深度＝菱形的半寬。菱形是 60×60 的正方形轉 45°，
  /// 所以左半部三角形的水平深度正好是 30 —— 與 `_barH / 2` 相等，
  /// 這也是凹口斜邊能與菱形斜邊完全貼合的原因。
  static const _notch = _diamond / 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _diamond,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 兩條之間<b>不留間隙</b>：各自的凹口合起來剛好是菱形的形狀，
          // 留了間隙反而會在接縫處露出背景。
          Row(
            children: [
              Expanded(
                child: _side(
                  'HP',
                  hpFraction,
                  const Color(0xFFC0392B),
                  AlignmentDirectional.centerStart,
                  notchOnRight: true,
                ),
              ),
              Expanded(
                child: _side(
                  'MP',
                  mpFraction,
                  const Color(0xFF2E6FC0),
                  AlignmentDirectional.centerEnd,
                  notchOnRight: false,
                ),
              ),
            ],
          ),
          // 中央菱形（等級 + 經驗%，外框＝經驗條）
          _LevelDiamond(level: level, expFraction: expFraction, size: _diamond),
        ],
      ),
    );
  }

  Widget _side(
    String label,
    double frac,
    Color color,
    AlignmentGeometry a, {
    required bool notchOnRight,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        NotchedBar(
          fraction: frac,
          color: color,
          height: _barH,
          notch: _notch,
          notchOnRight: notchOnRight,
        ),
        Align(
          alignment: a,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: _ts(size: 14, weight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

/// 三種貨幣。放在 HP/MP 條的正上方 —— 那是視線焦點所在，
/// 比擠在右下角小地圖上方好找。
class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: _panelDeco(),
      // FittedBox 是必要的：位數一多就會撐爆（金幣破億時必然發生）。
      // 用 scaleDown 而非 ellipsis —— 金額被截斷成「1,245,6…」會讓人誤讀，
      // 整體縮小仍看得到每一位數。放得下時它不做任何事。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _currency(
              Icons.monetization_on,
              const Color(0xFFE8C547),
              '1,245,678',
            ),
            const SizedBox(width: 12),
            _currency(Icons.diamond, const Color(0xFF56C0E0), '12,450'),
            const SizedBox(width: 12),
            _currency(Icons.auto_awesome, const Color(0xFFB06FE0), '8,860'),
          ],
        ),
      ),
    );
  }

  static Widget _currency(IconData icon, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(value, style: _ts(size: 13)),
      ],
    );
  }
}

/// 中央菱形：等級（大）＋ 經驗%（小），外框描邊依經驗比例填亮（＝經驗條）。
class _LevelDiamond extends StatelessWidget {
  const _LevelDiamond({
    required this.level,
    required this.expFraction,
    required this.size,
  });

  final int level;
  final double expFraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DiamondFramePainter(expFraction),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: _ts(
                  size: 20,
                  color: _goldBright,
                  weight: FontWeight.bold,
                ),
              ),
              Text(
                '${(expFraction * 100).toStringAsFixed(1)}%',
                style: _ts(size: 9, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiamondFramePainter extends CustomPainter {
  _DiamondFramePainter(this.expFraction);
  final double expFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // 由底部頂點起、順時針一圈的菱形路徑（經驗由底往上填）。
    final path = Path()
      ..moveTo(w / 2, h)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, 0)
      ..lineTo(0, h / 2)
      ..close();

    // 底色 + 暗框
    canvas.drawPath(path, Paint()..color = const Color(0xF01A1410));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _gold.withValues(alpha: 0.35),
    );

    // 經驗進度框（描邊比例）
    final frac = expFraction.clamp(0.0, 1.0);
    if (frac > 0) {
      final metric = path.computeMetrics().first;
      final exp = metric.extractPath(0, metric.length * frac);
      canvas.drawPath(
        exp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFE8C860),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondFramePainter old) =>
      old.expFraction != expFraction;
}

/// 聊天面板：頻道頁籤 + 訊息區 + 輸入列。
///
/// 訊息區顯示 [GameWorldService.systemMessagesNotifier] 的真實系統訊息
/// （含 GM 指令回饋）；在還沒有訊息時退回展示用假資料，避免一片空白。
/// 聊天面板：頻道頁籤 + 訊息區 + 輸入列。
///
/// 頁籤同時決定「發送頻道」與「檢視過濾」；綜合顯示全部但不可發送。
/// GM 指令不經過這裡 —— 那是 GM 面板的事，兩者已徹底分離。
class _ChatPanel extends StatefulWidget {
  const _ChatPanel(this.game, {this.width = 460});

  final MyGame game;
  final double width;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// 全部頻道。原本拆成左右兩組是為了在版面中央讓開等級菱形的尖角；
  /// 頻道改成由輸入框左側的按鈕向上展開之後，那個閃避就不需要了。
  static const _channels = [
    ChatChannel.general,
    ChatChannel.world,
    ChatChannel.party,
    ChatChannel.guild,
    ChatChannel.whisper,
    ChatChannel.system,
  ];

  /// 各頻道的顯示色。
  static const _channelColor = {
    ChatChannel.general: Color(0xFFBFBFBF),
    ChatChannel.world: Color(0xFF6FA8DC),
    ChatChannel.party: Color(0xFF76A5AF),
    ChatChannel.guild: Color(0xFF93C47D),
    ChatChannel.whisper: Color(0xFFD5A6BD),
    ChatChannel.system: Color(0xFFC9A24B),
  };

  ChatChannel _selected = ChatChannel.general;

  /// 頻道清單是否展開（向上蓋在訊息區之上）。
  bool _channelOpen = false;

  /// 私聊對象（以 /w 名稱 訊息 設定後記住，方便連續對話）。
  String _whisperTarget = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// 發送頻道：綜合與系統不可發言，退回世界。
  ChatChannel get _sendChannel =>
      _selected.sendable ? _selected : ChatChannel.world;

  void _submit(String raw) {
    final text = raw.trim();
    _controller.clear();
    if (text.isNotEmpty) {
      _send(text);
    }
    _focus.requestFocus(); // 保留焦點，方便連續發話
  }

  void _send(String text) {
    final service = widget.game.gameWorldService;
    if (service == null) return;

    // /w 名稱 訊息 → 私聊；記住對象，之後在私聊頁籤可直接續談
    if (text.startsWith('/w ')) {
      final rest = text.substring(3).trim();
      final sp = rest.indexOf(' ');
      if (sp <= 0) {
        setState(() => _selected = ChatChannel.whisper);
        return;
      }
      final target = rest.substring(0, sp);
      final body = rest.substring(sp + 1).trim();
      if (body.isEmpty) return;
      setState(() {
        _whisperTarget = target;
        _selected = ChatChannel.whisper;
      });
      service.sendChat(ChatChannel.whisper, body, target: target);
      return;
    }

    final channel = _sendChannel;
    if (channel == ChatChannel.whisper && _whisperTarget.isEmpty) {
      // 尚未指定對象時退回世界頻道，而不是讓訊息無聲消失
      service.sendChat(ChatChannel.world, text);
      return;
    }
    service.sendChat(channel, text, target: _whisperTarget);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.game.gameWorldService;
    return SizedBox(
      width: widget.width,
      height: 236,
      child: Stack(
        children: [
          // 訊息在下、輸入列貼齊面板底緣（不再有頂部頁籤列）
          Column(
            children: [
              Expanded(
                child: service == null
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<List<SChat>>(
                        valueListenable: service.chatMessagesNotifier,
                        builder: (context, all, child) =>
                            _buildMessageList(all),
                      ),
              ),
              _buildInputRow(),
            ],
          ),
          // 頻道清單：向上展開，蓋在訊息區之上。
          // 用面板內的 Stack 而非 showMenu —— 後者會推一個 route，
          // 疊在 Flame 的 GameWidget 上定位與關閉都不好控制。
          if (_channelOpen)
            Positioned(left: 8, bottom: 34, child: _buildChannelList()),
        ],
      ),
    );
  }

  /// 依選中頻道過濾；綜合顯示全部。
  Widget _buildMessageList(List<SChat> all) {
    final messages = _selected == ChatChannel.general
        ? all
        : all.where((m) => m.channel == _selected).toList();
    if (messages.isEmpty) {
      return Center(
        child: Text(
          _selected == ChatChannel.general
              ? '目前沒有訊息'
              : '「${_selected.label}」目前沒有訊息',
          style: _ts(size: 11, color: Colors.white24),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[messages.length - 1 - i];
        final color = _channelColor[m.channel] ?? Colors.white70;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '[${m.channel.label}] ',
                  style: _ts(size: 11, color: color),
                ),
                if (m.sender.isNotEmpty)
                  TextSpan(
                    text: '${m.sender}：',
                    style: _ts(size: 11, color: Colors.white70),
                  ),
                TextSpan(
                  text: m.text,
                  style: _ts(size: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _hint {
    if (_sendChannel == ChatChannel.whisper) {
      return _whisperTarget.isEmpty ? '私聊：/w 對象名稱 訊息' : '私聊給 $_whisperTarget…';
    }
    return '在「${_sendChannel.label}」發言…（私聊用 /w 名稱 訊息）';
  }

  Widget _buildInputRow() => Container(
    height: 30,
    // 底部不留 margin —— 輸入框要貼齊面板下緣
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
    padding: const EdgeInsets.only(left: 4, right: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        _buildChannelButton(),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onSubmitted: _submit,
            textInputAction: TextInputAction.send,
            style: _ts(size: 11, color: Colors.white),
            cursorColor: _goldBright,
            cursorHeight: 13,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              hintText: _hint,
              hintStyle: _ts(size: 11, color: Colors.white38),
            ),
          ),
        ),
        const Icon(Icons.emoji_emotions_outlined, size: 16, color: _gold),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _submit(_controller.text),
          child: const Icon(Icons.send, size: 15, color: _goldBright),
        ),
      ],
    ),
  );

  /// 輸入框左側的頻道按鈕：顯示目前頻道，點擊向上展開清單。
  Widget _buildChannelButton() => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _channelOpen = !_channelOpen),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: PanelTheme.cellBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selected.label,
            style: _ts(
              size: 11,
              color: _channelColor[_selected] ?? _goldBright,
            ),
          ),
          Icon(
            _channelOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            size: 14,
            color: _gold,
          ),
        ],
      ),
    ),
  );

  /// 向上展開的頻道清單。
  Widget _buildChannelList() => Container(
    width: 88,
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: PanelTheme.panelDeco(r: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ch in _channels)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              _selected = ch;
              _channelOpen = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              color: ch == _selected
                  ? PanelTheme.cellBgActive
                  : Colors.transparent,
              child: Text(
                ch.label,
                style: _ts(
                  size: 11,
                  color: ch == _selected
                      ? _goldBright
                      : (_channelColor[ch] ?? Colors.white54),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// 道具列 + 技能列
// ─────────────────────────────────────────────────────────────────────────

// 統一格子尺寸與間距（熱鍵格／左右快捷選單共用，寬高一致）。
const double _cell = 46;
const double _cellGap = 4;

/// 統一黑色格子：空格（熱鍵佔位）或帶 icon+label（快捷選單）。
class _DockCell extends StatelessWidget {
  const _DockCell({this.icon, this.label, this.onTap});

  final IconData? icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: icon == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: _goldBright, size: 20),
                  if (label != null) ...[
                    const SizedBox(height: 2),
                    Text(label!, style: _ts(size: 9, color: Colors.white70)),
                  ],
                ],
              ),
      ),
    );
  }
}

/// 一排格子（等間距）。
class _CellRow extends StatelessWidget {
  const _CellRow(this.cells);
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: _cellGap),
          cells[i],
        ],
      ],
    );
  }
}

/// 快捷選單：一排 icon+label 格（左/右共用；寬高與熱鍵格一致）。
class _QuickMenu extends StatelessWidget {
  const _QuickMenu(this.entries);
  final List<(IconData, String, VoidCallback?)> entries;

  @override
  Widget build(BuildContext context) {
    return _CellRow([
      for (final (icon, label, onTap) in entries)
        _DockCell(icon: icon, label: label, onTap: onTap),
    ]);
  }
}

/// 左側熱鍵區：5×2 黑色空格 + 下方左側快捷選單（6 格）。
class _ActionBars extends StatelessWidget {
  const _ActionBars(this.game);
  final MyGame game;

  @override
  Widget build(BuildContext context) {
    List<Widget> emptyRow() => List.generate(5, (_) => const _DockCell());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CellRow(emptyRow()),
        const SizedBox(height: _cellGap),
        _CellRow(emptyRow()),
        const SizedBox(height: _cellGap),
        // 左側快捷選單。
        // 「隊伍」移除 —— 隊伍欄本來就常駐在左上角，不需要按鈕開關。
        // 「好友」與「門派」合併成「社交」，兩個標籤切換。
        //
        // 「布置」只在可布置的地圖出現，所以整列要跟著 mapInfo 重建 ——
        // 按鈕數量會在 4 顆與 5 顆之間變動（伺服器仍會重驗地圖限制）。
        ValueListenableBuilder<SMapInfo?>(
          valueListenable: game.mapInfoNotifier,
          builder: (context, info, child) => _QuickMenu([
            (Icons.person, '角色', () => debugPrint('[HUD] 角色')),
            (
              Icons.people_alt_outlined,
              '社交',
              () => game.socialPanelOpenNotifier.value =
                  !game.socialPanelOpenNotifier.value,
            ),
            (Icons.auto_awesome, '技能', () => debugPrint('[HUD] 技能')),
            (
              Icons.backpack,
              '背包',
              () => game.inventoryPanelOpenNotifier.value =
                  !game.inventoryPanelOpenNotifier.value,
            ),
            if (info?.mapId == MyGame.decoratableMapId)
              (
                Icons.chair_outlined,
                '布置',
                () => game.decorPanelOpenNotifier.value =
                    !game.decorPanelOpenNotifier.value,
              ),
            // 「秘境」已移到右下角商城旁邊。
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 貨幣 + 小地圖
// ─────────────────────────────────────────────────────────────────────────

class _TopRightPanel extends StatelessWidget {
  const _TopRightPanel(
    this.mapInfo,
    this.playerMark, {
    required this.minimapSize,
  });

  final ValueListenable<SMapInfo?> mapInfo;
  final ValueListenable<({int x, int y, int facing})?> playerMark;

  /// 小地圖直徑，由 HUD 依剩餘高度算出。
  final double minimapSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      // 貨幣列已移到畫面中下、HP/MP 條的正上方（見 _CurrencyRow）。
      child: _Minimap(mapInfo, playerMark, size: minimapSize),
    );
  }
}

/// 小地圖：資料驅動。地名/傳送點藍點來自 S_MAP_INFO，玩家箭頭來自 playerMark（隨移動更新）。
/// 傳送點與玩家皆依地圖 width/height 正規化到圓形範圍（同一套俯視投影）。
class _Minimap extends StatelessWidget {
  const _Minimap(this.mapInfo, this.playerMark, {this.size = 220});

  final ValueListenable<SMapInfo?> mapInfo;
  final ValueListenable<({int x, int y, int facing})?> playerMark;

  /// 直徑。由 HUD 依剩餘高度算出 —— 寫死 220 的話手機橫向會被下緣切掉。
  final double size;

  // 藍點/玩家分布半徑（留邊給圓框與地名列）。內部一律由 size 推導。
  double get _plotR => size * 0.40;
  double get _center => size / 2;
  static const Color _portalBlue = Color(0xFF6FA8DC);

  // facing 0-7 的格位移向量（與 IsoPlayerComponent 一致），用來算箭頭朝向。
  static const List<(int, int)> _facingDelta = [
    (0, -1),
    (1, -1),
    (1, 0),
    (1, 1),
    (0, 1),
    (-1, 1),
    (-1, 0),
    (-1, -1),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([mapInfo, playerMark]),
      builder: (context, _) {
        final info = mapInfo.value;
        final mark = playerMark.value;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2C3A24), Color(0xFF161B12)],
            ),
            border: Border.all(
              color: _gold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 地名（由伺服器 S_MAP_INFO 提供）
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (info?.mapName.isNotEmpty ?? false)
                        ? info!.mapName
                        : '未知之地',
                    style: _ts(size: 12, color: _goldBright),
                  ),
                ),
              ),
              // N 指北
              Positioned(
                top: 30,
                child: Text('N', style: _ts(size: 11, color: Colors.white70)),
              ),
              // 傳送點藍色光點
              ..._portalDots(info),
              // 玩家箭頭（依實際格座標定位、依 facing 旋轉）
              _playerMarker(info, mark),
            ],
          ),
        );
      },
    );
  }

  /// 格座標 (x,y) → 圓內像素中心（俯視投影，與藍點共用）。
  Offset _project(int x, int y, SMapInfo info) {
    final nx = (x + 0.5) / info.width * 2 - 1;
    final ny = (y + 0.5) / info.height * 2 - 1;
    return Offset(_center + nx * _plotR, _center + ny * _plotR);
  }

  /// 把每個傳送點的格座標正規化到圓內位置，畫成藍點。
  List<Widget> _portalDots(SMapInfo? info) {
    if (info == null || info.width <= 0 || info.height <= 0) {
      return const [];
    }
    return [
      for (final p in info.portals)
        Builder(
          builder: (_) {
            final o = _project(p.locX, p.locY, info);
            return Positioned(
              left: o.dx - 6,
              top: o.dy - 6,
              child: _PortalDot(name: p.name),
            );
          },
        ),
    ];
  }

  /// 玩家箭頭：有地圖尺寸與玩家座標時定位並旋轉；否則退回圓心。
  Widget _playerMarker(SMapInfo? info, ({int x, int y, int facing})? mark) {
    const icon = Icon(Icons.navigation, size: 20, color: Color(0xFF4CD07D));
    if (info == null || info.width <= 0 || info.height <= 0 || mark == null) {
      return icon; // Stack 置中
    }
    final o = _project(mark.x, mark.y, info);
    final (ddx, ddy) = _facingDelta[mark.facing.clamp(0, 7)];
    // Icons.navigation 預設朝上(-y)；旋轉到 (ddx,ddy) 方向需 atan2(dy,dx)+π/2。
    final angle = math.atan2(ddy.toDouble(), ddx.toDouble()) + math.pi / 2;
    return Positioned(
      left: o.dx - 10,
      top: o.dy - 10,
      child: Transform.rotate(angle: angle, child: icon),
    );
  }
}

/// 小地圖上的單一傳送點藍色光點（含外光暈，hover 顯示名稱）。
class _PortalDot extends StatelessWidget {
  const _PortalDot({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _Minimap._portalBlue,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _Minimap._portalBlue.withValues(alpha: 0.9),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
    return name.isEmpty ? dot : Tooltip(message: name, child: dot);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ⑦ 任務追蹤
// ─────────────────────────────────────────────────────────────────────────

class _QuestPanel extends StatelessWidget {
  const _QuestPanel();

  static const _quests = [
    ('主線', Color(0xFFE8C547), '天機之謎', '前往天機門與長老對話', '0/1'),
    ('支線', Color(0xFF56C06A), '收集靈草', '收集千年靈芝', '5/10'),
    ('日常', Color(0xFF56A8E0), '門派任務', '完成3次門派任務', '1/3'),
    ('引導', Color(0xFF7EC98A), '靈寵培養', '提升靈寵等級至30級', '28/30'),
    ('活動', Color(0xFFB06FE0), '秘境探險', '通關秘境第3層', '0/1'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: _panelDeco(),
      child: Column(
        // 有 Expanded 時主軸必須是 max（預設），不可用 min
        children: [
          // 標題
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  '任務',
                  style: _ts(
                    size: 15,
                    color: _goldBright,
                    weight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.settings, size: 16, color: _gold),
              ],
            ),
          ),
          // Tab
          Row(children: [_tab('進行中', true), _tab('可接取', false)]),
          const Divider(height: 1, color: PanelTheme.divider),
          // 任務列表：同上，用 Expanded 吃剩餘空間避免溢出
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: _quests.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 12, color: Color(0x1AFFFFFF)),
              itemBuilder: (_, i) {
                final (tag, color, name, desc, progress) = _quests[i];
                return _QuestRow(
                  tag: tag,
                  color: color,
                  name: name,
                  desc: desc,
                  progress: progress,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: active ? _gold.withValues(alpha: 0.18) : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          label,
          style: _ts(
            size: 13,
            color: active ? _goldBright : Colors.white54,
            weight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.tag,
    required this.color,
    required this.name,
    required this.desc,
    required this.progress,
  });

  final String tag;
  final Color color;
  final String name;
  final String desc;
  final String progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_fire_department, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '[$tag] ',
                      style: _ts(size: 12, color: color),
                    ),
                    TextSpan(
                      text: name,
                      style: _ts(size: 12, weight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(desc, style: _ts(size: 11, color: Colors.white60)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(progress, style: _ts(size: 11, color: _goldBright)),
      ],
    );
  }
}
