import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../network/packets/server/s_inventory.dart';
import '../theme/game_panel_theme.dart';
import '../widgets/shared/context_menu.dart';
import '../widgets/shared/tabbed_panel.dart';

/// 背包。
///
/// 資料完全由伺服器供應（`S_INVENTORY` 進遊戲時整份、之後靠增量封包維護），
/// 前端不持有任何道具定義 —— 名稱、類型、可否使用都是封包帶來的。
///
/// 分頁只是**篩選同一份資料**，不是三份清單。道具在伺服器只有一個背包，
/// 前端分兩份的話「用掉最後一瓶」就得記得兩邊都刪。
class InventoryPanel extends StatelessWidget {
  const InventoryPanel(this.game, {super.key});

  final MyGame game;

  static const _tabs = ['全部', '裝備', '消耗'];

  bool _matches(InventoryItem it, int tab) {
    switch (tab) {
      case 1:
        return it.isWeapon || it.isArmor;
      case 2:
        return it.usable;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabbedPanel(
      title: '背包',
      icon: Icons.backpack,
      tabs: _tabs,
      onClose: () => game.inventoryPanelOpenNotifier.value = false,
      builder: (context, tab) => ValueListenableBuilder<Map<int, InventoryItem>>(
        valueListenable: game.gameWorldService?.inventoryNotifier ??
            ValueNotifier<Map<int, InventoryItem>>(const {}),
        builder: (context, all, child) {
          final items =
              all.values.where((it) => _matches(it, tab)).toList(growable: false);
          if (items.isEmpty) {
            return Center(
              child: Text(
                all.isEmpty ? '背包是空的' : '這個分頁沒有東西',
                style: PanelTheme.ts(size: 12, color: PanelTheme.textFaint),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _ItemRow(game: game, item: items[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                child: Row(
                  children: [
                    Text('${all.length} 件',
                        style: PanelTheme.ts(
                            size: 10, color: PanelTheme.textDim)),
                    const Spacer(),
                    Text('點道具可使用，右鍵更多',
                        style: PanelTheme.ts(
                            size: 10, color: PanelTheme.textFaint)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.game, required this.item});

  final MyGame game;
  final InventoryItem item;

  /// 右鍵／長按：使用、丟棄。與世界的角色選單共用同一套彈出層。
  void _openMenu(Offset pos) {
    game.showContextMenu(ContextMenuRequest(
      position: pos,
      title: item.displayName,
      items: [
        if (item.usable)
          ContextMenuItem('使用', () => game.gameWorldService?.useItem(item.objId)),
        ContextMenuItem(
          item.count > 1 ? '丟棄一個' : '丟棄',
          () => game.gameWorldService?.dropItem(item.objId),
          danger: true,
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 類型只影響圖示，實際能不能用一律看伺服器給的 usable
    final icon = item.isWeapon
        ? Icons.colorize
        : item.isArmor
            ? Icons.shield_outlined
            : Icons.science_outlined;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.usable
          ? () => game.gameWorldService?.useItem(item.objId)
          : null,
      onSecondaryTapDown: (d) => _openMenu(d.globalPosition),
      onLongPressStart: (d) => _openMenu(d.globalPosition),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: item.equipped
              ? PanelTheme.cellBgActive
              : PanelTheme.cellBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: item.usable
                    ? PanelTheme.goldBright
                    : PanelTheme.textDim),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PanelTheme.ts(size: 12, color: Colors.white70),
              ),
            ),
            if (item.equipped) ...[
              Text('裝備中',
                  style: PanelTheme.ts(
                      size: 10, color: PanelTheme.goldBright)),
              const SizedBox(width: 8),
            ],
            // 只有可疊加的才顯示數量 —— 武器永遠是 1，寫出來只是雜訊
            if (item.stackable)
              Text('×${item.count}',
                  style: PanelTheme.ts(size: 11, color: PanelTheme.textDim)),
          ],
        ),
      ),
    );
  }
}
