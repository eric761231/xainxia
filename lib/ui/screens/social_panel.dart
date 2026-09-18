import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_panel_theme.dart';
import '../widgets/shared/tabbed_panel.dart';

/// 社交面板：好友與門派合併成一個介面，兩個標籤切換。
///
/// 原本好友與門派各佔一顆快捷鍵，但兩者性質相近且都是「人的清單」，
/// 合併後底部快捷列少一顆、版面也更整齊。
///
/// 資料全是假的 —— 伺服器沒有好友或門派系統。按鈕會有反饋（系統訊息），
/// 但不發封包。將來接上時只換資料來源與按鈕的實作。
class SocialPanel extends StatelessWidget {
  const SocialPanel(this.game, {super.key});

  final MyGame game;

  static const _friends = [
    ('墨無痕', 75, true),
    ('洛清塵', 72, true),
    ('素雪', 73, false),
    ('玄風子', 71, false),
    ('紫霄真人', 70, true),
  ];

  static const _guildMembers = [
    ('掌門・雲中鶴', 88, '掌門'),
    ('副掌門・沈青梧', 84, '副掌門'),
    ('墨無痕', 75, '內門弟子'),
    ('洛清塵', 72, '內門弟子'),
    ('素雪', 73, '外門弟子'),
  ];

  void _stub(String action, String target) =>
      game.gameWorldService?.localSystemMessage('［$action］功能尚未開放（對象：$target）');

  @override
  Widget build(BuildContext context) {
    return TabbedPanel(
      title: '社交',
      icon: Icons.people_alt_outlined,
      tabs: const ['好友', '門派'],
      onClose: () => game.socialPanelOpenNotifier.value = false,
      builder: (context, index) =>
          index == 0 ? _buildFriends() : _buildGuild(),
    );
  }

  Widget _buildFriends() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _friends.length,
        itemBuilder: (context, i) {
          final (name, level, online) = _friends[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: PanelTheme.cellBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 在線狀態用小圓點表示，比文字省空間
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: online
                            ? const Color(0xFF6FBF73)
                            : PanelTheme.textFaint,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(name,
                          style: PanelTheme.ts(
                              size: 12,
                              color: online
                                  ? Colors.white70
                                  : PanelTheme.textFaint)),
                    ),
                    Text('Lv.$level',
                        style: PanelTheme.ts(
                            size: 10, color: PanelTheme.textDim)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    PanelButton(label: '組隊', onTap: () => _stub('組隊', name)),
                    const SizedBox(width: 4),
                    PanelButton(label: '密語', onTap: () => _stub('密語', name)),
                    const SizedBox(width: 4),
                    PanelButton(label: '寄信', onTap: () => _stub('寄信', name)),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _buildGuild() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _guildMembers.length,
        itemBuilder: (context, i) {
          final (name, level, rank) = _guildMembers[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: PanelTheme.cellBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(name,
                      style:
                          PanelTheme.ts(size: 12, color: Colors.white70)),
                ),
                Text(rank,
                    style: PanelTheme.ts(
                        size: 10, color: PanelTheme.goldBright)),
                const SizedBox(width: 8),
                Text('Lv.$level',
                    style:
                        PanelTheme.ts(size: 10, color: PanelTheme.textDim)),
              ],
            ),
          );
        },
      );
}
