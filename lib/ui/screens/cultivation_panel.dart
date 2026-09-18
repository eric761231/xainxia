import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../theme/game_panel_theme.dart';
import '../widgets/shared/tabbed_panel.dart';

/// 修練面板：練氣與靈寵合併成一個介面，兩個標籤切換。
///
/// 原本練氣、靈寵、修練各佔一顆快捷鍵，但三者都屬於「養成」，
/// 合併後右側快捷列由 6 顆減為 4 顆。
///
/// 注意：隊伍面板也有一個「靈寵」分頁，那是**出戰中的寵物**；
/// 這裡的靈寵是**培養**介面，兩者用途不同，不要合併。
///
/// 內容目前是骨架 —— 修練與靈寵系統都還沒有伺服器實作。
class CultivationPanel extends StatelessWidget {
  const CultivationPanel(this.game, {super.key});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return TabbedPanel(
      title: '修練',
      icon: Icons.self_improvement,
      tabs: const ['練氣', '靈寵'],
      onClose: () => game.cultivationPanelOpenNotifier.value = false,
      builder: (context, index) => index == 0 ? _buildQi() : _buildPets(),
    );
  }

  Widget _buildQi() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('築基期 三層',
                style:
                    PanelTheme.ts(size: 14, color: PanelTheme.goldBright)),
            const SizedBox(height: 10),
            _stat('修為', '128,400 / 250,000'),
            _stat('打坐效率', '+12%'),
            _stat('突破機率', '38%'),
            const Spacer(),
            PanelButton(
              label: '開始打坐',
              expand: true,
              onTap: () => game.gameWorldService
                  ?.localSystemMessage('［打坐］功能尚未開放'),
            ),
          ],
        ),
      );

  Widget _buildPets() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('尚未培養靈寵',
                style: PanelTheme.ts(size: 12, color: PanelTheme.textDim)),
            const SizedBox(height: 8),
            Text('於秘境中捕捉靈獸後，可在此培養。',
                style: PanelTheme.ts(size: 10, color: PanelTheme.textFaint)),
            const Spacer(),
            PanelButton(
              label: '前往秘境',
              expand: true,
              onTap: game.enterChallenge,
            ),
          ],
        ),
      );

  Widget _stat(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(label,
                style: PanelTheme.ts(size: 11, color: PanelTheme.textDim)),
            const Spacer(),
            Text(value,
                style: PanelTheme.ts(size: 11, color: Colors.white70)),
          ],
        ),
      );
}
