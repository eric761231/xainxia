import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../network/packets/server/s_map_info.dart';
import '../theme/game_ui_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 依視窗等比例縮放（取寬/高比較小值，不變形），並夾在合理範圍。
            final scale = math
                .min(constraints.maxWidth / _designW,
                    constraints.maxHeight / _designH)
                .clamp(0.45, 1.4);

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
                      color: Color(0xFF0B0A08),
                      border: Border(
                        top: BorderSide(color: Color(0x59C9A24B), width: 1.2),
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
                    scale,
                    const _DraggablePanel(child: _PartyPanel()),
                  ),
                ),
                // 右上：任務追蹤（可拖曳移動；寬高與隊伍一致）
                Positioned(
                  top: 12,
                  right: 12,
                  child: _Scaled(
                    Alignment.topRight,
                    scale,
                    const _DraggablePanel(child: _QuestPanel()),
                  ),
                ),
                // 左下（貼底）：5×2 熱鍵格 + 左側快捷選單
                Positioned(
                  bottom: 0,
                  left: 12,
                  child: _Scaled(
                      Alignment.bottomLeft, scale, _ActionBars(game)),
                ),
                // 中下（貼底）：中央生命條 + 聊天（無框、加寬）
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Scaled(
                      Alignment.bottomCenter,
                      scale,
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _CenterVitalBar(
                            level: 75,
                            hpFraction: 0.638,
                            mpFraction: 0.82,
                            expFraction: 0.638,
                            width: 560,
                          ),
                          Transform.translate(
                            offset: const Offset(0, -14),
                            child: const _ChatPanel(width: 560),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 右下（貼底）：小地圖（在聊天界線下方）+ 右側快捷選單
                Positioned(
                  bottom: 0,
                  right: 12,
                  child: _Scaled(
                    Alignment.bottomRight,
                    scale,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopRightPanel(
                            game.mapInfoNotifier, game.playerMarkNotifier),
                        const SizedBox(height: _cellGap),
                        _QuickMenu([
                          (Icons.storefront, '商城',
                              () => debugPrint('[HUD] 商城')),
                          (Icons.settings, '設定',
                              () => debugPrint('[HUD] 設定')),
                          (Icons.logout, '離開',
                              () => unawaited(game.logoutToAccount())),
                          (Icons.self_improvement, '修練',
                              () => debugPrint('[HUD] 修練')),
                          (Icons.air, '練氣', () => debugPrint('[HUD] 練氣')),
                          (Icons.pets, '靈寵', () => debugPrint('[HUD] 靈寵')),
                        ]),
                      ],
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
    return Transform.scale(
      scale: scale,
      alignment: alignment,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 共用樣式
// ─────────────────────────────────────────────────────────────────────────

const _gold = Color(0xFFC9A24B);
const _goldBright = Color(0xFFE8C86A);
const _panelBg = Color(0xD90E0C0A); // 半透明深色暖黑

BoxDecoration _panelDeco({double radius = 10}) => BoxDecoration(
      color: _panelBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.2),
    );

TextStyle _ts({
  double size = 13,
  Color color = Colors.white,
  FontWeight weight = FontWeight.normal,
}) =>
    TextStyle(
      fontFamily: GameUiFonts.kingHwaOldSong,
      fontSize: size,
      color: color,
      fontWeight: weight,
      shadows: const [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(0.5, 0.5)),
      ],
    );

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
  const _Bar({
    required this.fraction,
    required this.color,
    this.height = 13,
  });

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
        border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
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
        border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined,
          color: _gold.withValues(alpha: 0.5), size: side * 0.42),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 隊伍欄
// ─────────────────────────────────────────────────────────────────────────

class _PartyPanel extends StatelessWidget {
  const _PartyPanel();

  static const _members = [
    ('墨無痕', 75, '36215/36215', '8576/8576', Icons.content_cut),
    ('洛清塵', 72, '29876/29876', '7456/7456', Icons.eco),
    ('素雪', 73, '27543/27543', '9123/9123', Icons.auto_awesome),
    ('玄風子', 71, '25431/25431', '6987/6987', Icons.gps_fixed),
    ('紫霄真人', 70, '23109/23109', '6721/6721', Icons.nightlight_round),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: _panelDeco(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab
          Row(
            children: [
              _tab('隊友', true),
              _tab('靈寵', false),
            ],
          ),
          const Divider(height: 1, color: Color(0x33C9A24B)),
          // 成員列表
          SizedBox(
            height: 300,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final (name, lv, hp, mp, icon) = _members[i];
                return _PartyMemberRow(
                    name: name, level: lv, hp: hp, mp: mp, classIcon: icon);
              },
            ),
          ),
          // 分頁列
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x33C9A24B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.keyboard_arrow_up, size: 18, color: _gold),
                const SizedBox(width: 12),
                Text('1 / 2', style: _ts(size: 12, color: _goldBright)),
                const SizedBox(width: 12),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: _gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? _gold.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: _ts(
                size: 13,
                color: active ? _goldBright : Colors.white54,
                weight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _PartyMemberRow extends StatelessWidget {
  const _PartyMemberRow({
    required this.name,
    required this.level,
    required this.hp,
    required this.mp,
    required this.classIcon,
  });

  final String name;
  final int level;
  final String hp;
  final String mp;
  final IconData classIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  border: Border.all(color: _gold.withValues(alpha: 0.6)),
                ),
                child: Text('$level',
                    style: _ts(
                        size: 9,
                        color: _goldBright,
                        weight: FontWeight.bold)),
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
              Text(name, style: _ts(size: 12)),
              const SizedBox(height: 2),
              _Bar(fraction: 1.0, color: const Color(0xFFC0392B), height: 7),
              const SizedBox(height: 2),
              _Bar(fraction: 1.0, color: const Color(0xFF2E6FC0), height: 7),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(classIcon, size: 16, color: _goldBright),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ③ 聊天視窗
// ─────────────────────────────────────────────────────────────────────────

/// 中央生命條：左 HP（紅）、右 MP（藍），中央菱形顯示等級與經驗%，菱形外框＝經驗條。
class _CenterVitalBar extends StatelessWidget {
  const _CenterVitalBar({
    this.level = 75,
    this.hpFraction = 0.638,
    this.mpFraction = 0.82,
    this.expFraction = 0.638,
    this.width = 460,
  });

  final int level;
  final double hpFraction;
  final double mpFraction;
  final double expFraction;
  final double width;

  static const _barH = 22.0;
  static const _diamond = 60.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _diamond,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // HP / MP 橫條（垂直置中對齊菱形；中央留給菱形）
          SizedBox(
            height: _barH,
            child: Row(
              children: [
                Expanded(
                    child: _side('HP', hpFraction, const Color(0xFFC0392B),
                        AlignmentDirectional.centerStart)),
                const SizedBox(width: _diamond - 10),
                Expanded(
                    child: _side('MP', mpFraction, const Color(0xFF2E6FC0),
                        AlignmentDirectional.centerEnd)),
              ],
            ),
          ),
          // 中央菱形（等級 + 經驗%，外框＝經驗條）
          _LevelDiamond(
              level: level, expFraction: expFraction, size: _diamond),
        ],
      ),
    );
  }

  Widget _side(String label, double frac, Color color, AlignmentGeometry a) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _Bar(fraction: frac, color: color, height: _barH),
        Align(
          alignment: a,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: _ts(size: 12, weight: FontWeight.bold)),
          ),
        ),
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
              Text('$level',
                  style: _ts(
                      size: 20,
                      color: _goldBright,
                      weight: FontWeight.bold)),
              Text('${(expFraction * 100).toStringAsFixed(1)}%',
                  style: _ts(size: 9, color: Colors.white70)),
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

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({this.width = 460});

  final double width;

  static const _tabsLeft = ['綜合', '世界', '隊伍'];
  static const _tabsRight = ['門派', '私聊', '系統'];
  static const _messages = [
    ('[世界]', '劍心無名', '來組隊打秘境！', '15:28', Color(0xFF6FA8DC)),
    ('[門派]', '清風徐來', '門派BOSS 5分鐘後開始，大家準備', '15:29', Color(0xFF93C47D)),
    ('[隊伍]', '墨無痕', '集合！準備出發', '15:29', Color(0xFF76A5AF)),
    ('[系統]', '', '恭喜玩家「逍遙子」突破至元嬰期！', '15:30', Color(0xFFC9A24B)),
    ('[世界]', '小仙女', '收購千年靈芝，價格私聊', '15:30', Color(0xFF6FA8DC)),
    ('[系統]', '', '獲得經驗 x12500', '15:30', Color(0xFFC9A24B)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 236,
      // 聊天框線先隱藏（透明底，疊在底部 dock 上）。
      child: Column(
        children: [
          // 頻道頁籤（上方，分左右兩組；中央留白給菱形尖角）
          SizedBox(
            height: 28,
            child: Row(
              children: [
                _tabGroup(_tabsLeft, selectedIndex: 0),
                const SizedBox(width: 64),
                _tabGroup(_tabsRight, selectedIndex: -1),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0x33C9A24B)),
          // 訊息
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final (channel, sender, text, time, color) = _messages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '$channel ', style: _ts(size: 11, color: color)),
                      if (sender.isNotEmpty)
                        TextSpan(
                            text: '$sender：',
                            style: _ts(size: 11, color: _goldBright)),
                      TextSpan(text: text, style: _ts(size: 11)),
                      TextSpan(
                          text: '  $time',
                          style: _ts(size: 10, color: Colors.white38)),
                    ]),
                  ),
                );
              },
            ),
          ),
          // 輸入列
          Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text('點擊輸入訊息…',
                        style: _ts(size: 11, color: Colors.white38))),
                const Icon(Icons.emoji_emotions_outlined, size: 16, color: _gold),
                const SizedBox(width: 8),
                const Icon(Icons.send, size: 15, color: _goldBright),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 一組頻道頁籤（左或右半）；[selectedIndex] < 0 表示本組無選中。
  Widget _tabGroup(List<String> tabs, {required int selectedIndex}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Text(
              tabs[i],
              style: _ts(
                size: 12,
                color: i == selectedIndex ? _goldBright : Colors.white54,
                weight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
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
          border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1),
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
        // 左側快捷選單
        _QuickMenu([
          (Icons.person, '角色', () => debugPrint('[HUD] 角色')),
          (Icons.group, '隊伍', () => debugPrint('[HUD] 隊伍')),
          (Icons.people_alt, '好友', () => debugPrint('[HUD] 好友')),
          (Icons.auto_awesome, '技能', () => debugPrint('[HUD] 技能')),
          (Icons.backpack, '背包', () => debugPrint('[HUD] 背包')),
          (Icons.account_balance, '門派', () => debugPrint('[HUD] 門派')),
        ]),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 貨幣 + 小地圖
// ─────────────────────────────────────────────────────────────────────────

class _TopRightPanel extends StatelessWidget {
  const _TopRightPanel(this.mapInfo, this.playerMark);

  final ValueListenable<SMapInfo?> mapInfo;
  final ValueListenable<({int x, int y, int facing})?> playerMark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 貨幣列
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: _panelDeco(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _currency(Icons.monetization_on, const Color(0xFFE8C547), '1,245,678'),
              const SizedBox(width: 12),
              _currency(Icons.diamond, const Color(0xFF56C0E0), '12,450'),
              const SizedBox(width: 12),
              _currency(Icons.auto_awesome, const Color(0xFFB06FE0), '8,860'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 小地圖
        _Minimap(mapInfo, playerMark),
      ],
      ),
    );
  }

  Widget _currency(IconData icon, Color color, String value) {
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

/// 小地圖：資料驅動。地名/傳送點藍點來自 S_MAP_INFO，玩家箭頭來自 playerMark（隨移動更新）。
/// 傳送點與玩家皆依地圖 width/height 正規化到圓形範圍（同一套俯視投影）。
class _Minimap extends StatelessWidget {
  const _Minimap(this.mapInfo, this.playerMark);

  final ValueListenable<SMapInfo?> mapInfo;
  final ValueListenable<({int x, int y, int facing})?> playerMark;

  static const double _size = 220;
  // 藍點/玩家分布半徑（留邊給圓框與地名列）。
  static const double _plotR = _size * 0.40;
  static const double _center = _size / 2;
  static const Color _portalBlue = Color(0xFF6FA8DC);

  // facing 0-7 的格位移向量（與 IsoPlayerComponent 一致），用來算箭頭朝向。
  static const List<(int, int)> _facingDelta = [
    (0, -1), (1, -1), (1, 0), (1, 1),
    (0, 1), (-1, 1), (-1, 0), (-1, -1),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([mapInfo, playerMark]),
      builder: (context, _) {
        final info = mapInfo.value;
        final mark = playerMark.value;
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2C3A24), Color(0xFF161B12)],
            ),
            border: Border.all(color: _gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 地名（由伺服器 S_MAP_INFO 提供）
              Positioned(
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
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
                  child:
                      Text('N', style: _ts(size: 11, color: Colors.white70))),
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
        Builder(builder: (_) {
          final o = _project(p.locX, p.locY, info);
          return Positioned(
            left: o.dx - 6,
            top: o.dy - 6,
            child: _PortalDot(name: p.name),
          );
        }),
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
            color: Colors.white.withValues(alpha: 0.85), width: 1),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Text('任務', style: _ts(size: 15, color: _goldBright, weight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.settings, size: 16, color: _gold),
              ],
            ),
          ),
          // Tab
          Row(
            children: [
              _tab('進行中', true),
              _tab('可接取', false),
            ],
          ),
          const Divider(height: 1, color: Color(0x33C9A24B)),
          // 任務列表
          SizedBox(
            height: 300,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: _quests.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 12, color: Color(0x1AFFFFFF)),
              itemBuilder: (_, i) {
                final (tag, color, name, desc, progress) = _quests[i];
                return _QuestRow(
                    tag: tag, color: color, name: name, desc: desc, progress: progress);
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
        child: Text(label,
            style: _ts(
                size: 13,
                color: active ? _goldBright : Colors.white54,
                weight: active ? FontWeight.bold : FontWeight.normal)),
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
              Text.rich(TextSpan(children: [
                TextSpan(text: '[$tag] ', style: _ts(size: 12, color: color)),
                TextSpan(
                    text: name,
                    style: _ts(size: 12, weight: FontWeight.bold)),
              ])),
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

