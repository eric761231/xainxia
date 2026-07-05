import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/my_game.dart';
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
                // ① 左上：人物資訊 + ② 隊伍欄（同一 Column，隊伍自動接在人物下方）
                Positioned(
                  top: 12,
                  left: 12,
                  child: _Scaled(
                    Alignment.topLeft,
                    scale,
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CharacterPanel(),
                        SizedBox(height: 12),
                        _PartyPanel(),
                      ],
                    ),
                  ),
                ),
                // ④ 上方中央：Buff / Debuff
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Scaled(Alignment.topCenter, scale, const _BuffPanel()),
                  ),
                ),
                // ⑥ 右上：貨幣 + 小地圖 + ⑦ 任務（同一 Column，任務接在小地圖下方）
                Positioned(
                  top: 12,
                  right: 12,
                  child: _Scaled(
                    Alignment.topRight,
                    scale,
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopRightPanel(),
                        SizedBox(height: 12),
                        _QuestPanel(),
                      ],
                    ),
                  ),
                ),
                // ③ 左下：聊天視窗
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _Scaled(Alignment.bottomLeft, scale, const _ChatPanel()),
                ),
                // ⑤ 中下：道具列 + 技能列
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Scaled(
                        Alignment.bottomCenter, scale, const _ActionBars()),
                  ),
                ),
                // ⑧ 右下：快捷功能列
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _Scaled(Alignment.bottomRight, scale, _FunctionBar(game)),
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

/// 帶金框的方形圖示格（Buff / 技能 / 道具共用）。
class _Slot extends StatelessWidget {
  const _Slot({
    required this.icon,
    required this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _gold.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, size: size * 0.55, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ① 人物資訊
// ─────────────────────────────────────────────────────────────────────────

class _CharacterPanel extends StatelessWidget {
  const _CharacterPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(10),
      decoration: _panelDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 頭像
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF3A2E22), Color(0xFF1A1410)],
              ),
              border: Border.all(color: _gold, width: 2),
            ),
            child: const Icon(Icons.person, color: _goldBright, size: 38),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _gold.withValues(alpha: 0.6)),
                      ),
                      child: Text('Lv.75',
                          style: _ts(
                              size: 12,
                              color: _goldBright,
                              weight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Text('金丹初期·三重',
                        style: _ts(size: 12, color: _goldBright)),
                  ],
                ),
                const SizedBox(height: 5),
                _labeledBar('HP', '36215 / 36215', 1.0, const Color(0xFFC0392B)),
                const SizedBox(height: 3),
                _labeledBar('MP', '8576 / 8576', 1.0, const Color(0xFF2E6FC0)),
                const SizedBox(height: 3),
                _labeledBar('EXP', '68.59%', 0.6859, const Color(0xFFCBA135)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.whatshot, size: 13, color: _goldBright),
                    const SizedBox(width: 3),
                    Text('戰力 ', style: _ts(size: 12, color: _gold)),
                    Text('125,680',
                        style: _ts(size: 12, weight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledBar(String label, String value, double frac, Color color) {
    return Row(
      children: [
        SizedBox(
            width: 30,
            child: Text(label, style: _ts(size: 10, color: Colors.white70))),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Bar(fraction: frac, color: color, height: 14),
              Text(value, style: _ts(size: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ② 隊伍欄
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
      width: 320,
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
        // 頭像 + 等級
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF241C15),
            border: Border.all(color: _gold.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text('$level',
              style: _ts(size: 13, color: _goldBright, weight: FontWeight.bold)),
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

class _ChatPanel extends StatelessWidget {
  const _ChatPanel();

  static const _tabs = ['綜合', '世界', '門派', '隊伍', '私聊', '系統'];
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
    return Container(
      width: 400,
      height: 232,
      decoration: _panelDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左側頻道 Tab
          Container(
            width: 52,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0x33C9A24B))),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      color: i == 0
                          ? _gold.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Text(_tabs[i],
                          style: _ts(
                              size: 12,
                              color: i == 0 ? _goldBright : Colors.white54)),
                    ),
                  ),
              ],
            ),
          ),
          // 訊息 + 輸入列
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final (channel, sender, text, time, color) = _messages[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '$channel ', style: _ts(size: 11, color: color)),
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
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
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
                      const Icon(Icons.emoji_emotions_outlined,
                          size: 16, color: _gold),
                      const SizedBox(width: 8),
                      const Icon(Icons.send, size: 15, color: _goldBright),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ④ Buff / Debuff
// ─────────────────────────────────────────────────────────────────────────

class _BuffPanel extends StatelessWidget {
  const _BuffPanel();

  static const _buffs = [
    (Icons.eco, Color(0xFF4CAF50), '28:59'),
    (Icons.self_improvement, Color(0xFF3F7CC0), '58:32'),
    (Icons.spa, Color(0xFF4CAF7D), '58:32'),
    (Icons.shield, Color(0xFF4A90A4), '02:15'),
    (Icons.flash_on, Color(0xFF56B4C0), '05:32'),
    (Icons.hourglass_bottom, Color(0xFF7EAF6A), '12:30'),
    (Icons.favorite, Color(0xFF56A86A), '00:38'),
    (Icons.local_florist, Color(0xFF6FA84C), '03:20'),
    (Icons.brightness_7, Color(0xFF9AA84C), '01:15'),
    (Icons.whatshot, Color(0xFFCBA135), '59:59'),
  ];

  static const _debuffs = [
    (Icons.bolt, Color(0xFF8E44AD), '00:15'),
    (Icons.local_florist, Color(0xFFAD4499), '00:08'),
    (Icons.dangerous, Color(0xFFC0392B), '00:12'),
    (Icons.coronavirus, Color(0xFFAD3B2B), '00:04'),
    (Icons.whatshot, Color(0xFFC0562B), '00:09'),
    (Icons.water_drop, Color(0xFFB03A4A), '00:07'),
    (Icons.cut, Color(0xFFC0392B), '00:10'),
    (Icons.ac_unit, Color(0xFF9B3B6A), '00:05'),
    (Icons.air, Color(0xFFA84C6A), '00:09'),
    (Icons.flash_on, Color(0xFFC0442B), '00:06'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _panelDeco(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('增益', _buffs, const Color(0xFF7EC98A)),
          const SizedBox(height: 6),
          _row('減益', _debuffs, const Color(0xFFC98A8A)),
        ],
      ),
    );
  }

  Widget _row(String label, List<(IconData, Color, String)> list, Color labelColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: Text(label,
              style: _ts(size: 12, color: labelColor, weight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        for (final (icon, color, time) in list)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Slot(icon: icon, color: color, size: 34),
                const SizedBox(height: 1),
                Text(time, style: _ts(size: 9, color: Colors.white70)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ⑤ 道具列 + 技能列
// ─────────────────────────────────────────────────────────────────────────

class _ActionBars extends StatelessWidget {
  const _ActionBars();

  static const _items = [
    (Icons.science, Color(0xFFC0392B), '98', 'F1'),
    (Icons.science, Color(0xFF2E6FC0), '75', 'F2'),
    (Icons.science, Color(0xFF8E44AD), '42', 'F3'),
    (Icons.local_drink, Color(0xFF4CAF50), '28', 'F4'),
    (Icons.bakery_dining, Color(0xFFCBA135), '15', 'F5'),
    (Icons.spa, Color(0xFFE07A2B), '10', 'F6'),
    (Icons.description, Color(0xFFB0A084), '5', 'F7'),
    (Icons.local_bar, Color(0xFF56A86A), '3', 'F8'),
  ];

  static const _skills = [
    (Icons.ac_unit, Color(0xFF3F7CC0), '1'),
    (Icons.whatshot, Color(0xFFC0562B), '2'),
    (Icons.flash_on, Color(0xFF4A90C0), '3'),
    (Icons.eco, Color(0xFF4CAF50), '4'),
    (Icons.brightness_7, Color(0xFFCBA135), '5'),
    (Icons.auto_awesome, Color(0xFF8E44AD), '6'),
    (Icons.bolt, Color(0xFF56B4C0), '7'),
    (Icons.air, Color(0xFF7EAF6A), '8'),
    (Icons.self_improvement, Color(0xFF6FA8DC), '9'),
    (Icons.dangerous, Color(0xFF9B59B6), '0'),
    (Icons.stars, Color(0xFFCBA135), '='),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 道具列 F1~F8
        _bar([
          for (final (icon, color, count, key) in _items)
            _KeySlot(icon: icon, color: color, corner: count, keyLabel: key, size: 40),
        ]),
        const SizedBox(height: 6),
        // 技能列 1~0 =
        _bar([
          for (final (icon, color, key) in _skills)
            _KeySlot(icon: icon, color: color, keyLabel: key, size: 46),
        ]),
      ],
    );
  }

  Widget _bar(List<Widget> slots) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: _panelDeco(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in slots)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3), child: s),
        ],
      ),
    );
  }
}

/// 帶按鍵標籤（右下數量 / 底部快捷鍵）的圖示格。
class _KeySlot extends StatelessWidget {
  const _KeySlot({
    required this.icon,
    required this.color,
    required this.keyLabel,
    this.corner,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final String keyLabel;
  final String? corner;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            _Slot(icon: icon, color: color, size: size),
            if (corner != null)
              Positioned(
                right: 2,
                bottom: 1,
                child: Text(corner!,
                    style: _ts(size: 11, weight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          width: size * 0.55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(keyLabel, style: _ts(size: 10, color: _goldBright)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ⑥ 貨幣 + 小地圖
// ─────────────────────────────────────────────────────────────────────────

class _TopRightPanel extends StatelessWidget {
  const _TopRightPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
        const _Minimap(),
      ],
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

class _Minimap extends StatelessWidget {
  const _Minimap();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF2C3A24), Color(0xFF161B12)],
        ),
        border: Border.all(color: _gold, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 地名
          Positioned(
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withValues(alpha: 0.5)),
              ),
              child: Text('青雲谷',
                  style: _ts(size: 12, color: _goldBright)),
            ),
          ),
          // N 指北
          Positioned(top: 30, child: Text('N', style: _ts(size: 11, color: Colors.white70))),
          // 幾個地標點
          const Positioned(left: 55, top: 70, child: Icon(Icons.star, size: 13, color: _goldBright)),
          const Positioned(right: 60, top: 65, child: Icon(Icons.star, size: 13, color: _goldBright)),
          const Positioned(left: 70, bottom: 60, child: Icon(Icons.location_on, size: 15, color: Color(0xFF6FA8DC))),
          const Positioned(right: 65, bottom: 55, child: Icon(Icons.location_on, size: 15, color: Color(0xFF6FA8DC))),
          // 玩家方向（中心）
          const Icon(Icons.navigation, size: 20, color: Color(0xFF4CD07D)),
          // 時間
          Positioned(
            bottom: 10,
            child: Text('15:30', style: _ts(size: 11, color: Colors.white70)),
          ),
        ],
      ),
    );
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
      width: 340,
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

// ─────────────────────────────────────────────────────────────────────────
// ⑧ 快捷功能列
// ─────────────────────────────────────────────────────────────────────────

class _FunctionBar extends StatelessWidget {
  const _FunctionBar(this.game);
  final MyGame game;

  static const _entries = [
    (Icons.person, '角色', false),
    (Icons.backpack, '背包', true),
    (Icons.auto_awesome, '技能', true),
    (Icons.self_improvement, '修煉', false),
    (Icons.build, '煉器', false),
    (Icons.science, '煉丹', false),
    (Icons.pets, '靈寵', true),
    (Icons.account_balance, '門派', false),
    (Icons.group, '好友', false),
    (Icons.storefront, '商城', false),
    (Icons.settings, '設定', false),
    (Icons.logout, '離開', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: _panelDeco(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label, dot) in _entries)
            _FunctionButton(
              icon: icon,
              label: label,
              notify: dot,
              // 「離開」回帳號畫面；其餘暫以 debugPrint 佔位。
              onTap: label == '離開'
                  ? () => unawaited(game.logoutToAccount())
                  : () => debugPrint('[HUD] $label'),
            ),
        ],
      ),
    );
  }
}

class _FunctionButton extends StatefulWidget {
  const _FunctionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.notify = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool notify;

  @override
  State<_FunctionButton> createState() => _FunctionButtonState();
}

class _FunctionButtonState extends State<_FunctionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hover
                          ? _gold.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _gold.withValues(alpha: _hover ? 0.9 : 0.4),
                      ),
                    ),
                    child: Icon(widget.icon,
                        size: 22,
                        color: _hover ? _goldBright : const Color(0xFFDCC79A)),
                  ),
                  if (widget.notify)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0392B),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(widget.label, style: _ts(size: 10, color: const Color(0xFFDCC79A))),
            ],
          ),
        ),
      ),
    );
  }
}
