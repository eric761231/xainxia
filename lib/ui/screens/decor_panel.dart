import '../widgets/shared/panel_drag_bounds.dart';
import '../../game/tile_tool_mode.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../network/packets/server/s_placeable_list.dart';
import '../theme/game_panel_theme.dart';

// PanelTheme 的別名 —— 面板內有大量引用，保留短名稱、實作指向共用主題。
const _gold = PanelTheme.gold;
const _goldBright = PanelTheme.goldBright;
const _panelBg = PanelTheme.panelBg;

TextStyle _ts({double size = 12, Color color = Colors.white}) =>
    PanelTheme.ts(size: size, color: color);

/// 洞府布置面板。
///
/// 只在可布置的地圖（修練洞府）顯示。選一件家具後進入放置模式，
/// 點地圖格子即送出 `C_PLACE_PROPERTY`；拆除模式點已放置的家具即移除。
///
/// 合法性一律由伺服器判定（放置面規則、重疊、件數上限、是否站在該格），
/// 前端不預判 —— 否則兩邊規則會漸漸不一致。失敗原因會以系統訊息回到聊天。
class DecorPanel extends StatefulWidget {
  const DecorPanel(this.game, {super.key});

  final MyGame game;

  @override
  State<DecorPanel> createState() => _DecorPanelState();
}

class _DecorPanelState extends State<DecorPanel> {
  Offset _offset = Offset.zero;
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.game.gameWorldService?.requestPlaceableList();
    });
  }

  void _selectItem(PlaceableItem item) {
    final g = widget.game;
    final already = g.pendingPropertyIdNotifier.value == item.propertyId &&
        g.tileToolNotifier.value == TileTool.place;
    if (already) {
      g.setTileTool(TileTool.none);
      return;
    }
    g.setTileTool(TileTool.place);
    g.pendingPropertyIdNotifier.value = item.propertyId;
  }

  /// 在某個工具模式與「一般模式」之間切換。
  void _toggleTool(TileTool tool) {
    final g = widget.game;
    g.setTileTool(g.tileToolNotifier.value == tool ? TileTool.none : tool);
  }

  void _close() {
    final g = widget.game;
    g.decorPanelOpenNotifier.value = false;
    g.setTileTool(TileTool.none);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.game.gameWorldService;
    return Transform.translate(
      offset: _offset,
      child: Container(
        key: _contentKey,
        width: 300,
        height: 380,
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PanelTheme.panelBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            _buildModeBar(),
            Expanded(
              child: service == null
                  ? const SizedBox.shrink()
                  : ValueListenableBuilder<List<PlaceableItem>>(
                      valueListenable: service.placeableNotifier,
                      builder: (context, items, child) => items.isEmpty
                          ? Center(
                              child: Text('清單載入中…',
                                  style:
                                      _ts(size: 11, color: Colors.white30)))
                          : _buildList(items),
                    ),
            ),
            _buildHint(),
          ],
        ),
      ),
    );
  }

  /// 標題列：只有這裡可拖曳，避免與清單捲動搶手勢。
  Widget _buildTitleBar() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => setState(() => _offset = boundedPanelOffset(context, _contentKey, _offset, d.delta)),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chair_outlined, size: 16, color: _goldBright),
              const SizedBox(width: 6),
              Text('洞府布置', style: _ts(size: 13, color: _goldBright)),
              const Spacer(),
              GestureDetector(
                onTap: _close,
                child: SizedBox(width: 44, height: 44, child: Icon(Icons.close, size: 20, color: _gold)),
              ),
            ],
          ),
        ),
      );

  Widget _buildModeBar() => ValueListenableBuilder<TileTool>(
        valueListenable: widget.game.tileToolNotifier,
        builder: (context, tool, child) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              Expanded(child: Text(_hintFor(tool), style: _ts(size: 11, color: _hintColorFor(tool)))),
              _modeButton('搬動', TileTool.move, tool, const Color(0xFF7FB4E0)),
              const SizedBox(width: 6),
              _modeButton('拆除', TileTool.remove, tool, const Color(0xFFE08A8A)),
            ],
          ),
        ),
      );

  static String _hintFor(TileTool tool) {
    switch (tool) {
      case TileTool.remove:
        return '拆除模式：點擊家具即收回';
      case TileTool.move:
        return '搬動模式：先點家具，再點新位置';
      case TileTool.place:
        return '點地面預覽，再點同一格確定';
      default:
        return '選一件家具，再點地面放置';
    }
  }

  static Color _hintColorFor(TileTool tool) {
    switch (tool) {
      case TileTool.remove:
        return const Color(0xFFE08A8A);
      case TileTool.move:
        return const Color(0xFF7FB4E0);
      default:
        return Colors.white54;
    }
  }

  Widget _modeButton(String label, TileTool tool, TileTool current, Color on) {
    final active = current == tool;
    return GestureDetector(
      onTap: () => _toggleTool(tool),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? on.withValues(alpha: 0.2) : _gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: active ? on : _gold.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: _ts(size: 11, color: active ? on : Colors.white70)),
      ),
    );
  }

  Widget _buildList(List<PlaceableItem> items) =>
      ValueListenableBuilder<int?>(
        valueListenable: widget.game.pendingPropertyIdNotifier,
        builder: (context, placing, child) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            final selected = placing == it.propertyId;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectItem(it),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _gold.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected
                        ? _goldBright
                        : _gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(it.name,
                          style: _ts(
                              size: 12,
                              color: selected ? _goldBright : Colors.white70)),
                    ),
                    Text(
                      it.isWall ? '牆面' : '地面',
                      style: _ts(size: 10, color: Colors.white30),
                    ),
                    if (it.blocking) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.block, size: 12, color: Color(0x66C9A24B)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );

  /// 底部區：放置預覽落下後變成「確定／取消」，否則顯示操作提示。
  ///
  /// 面板上的按鈕是第二條確認路徑 —— 手機上「再點同一格」在小螢幕不好瞄準。
  Widget _buildHint() => ValueListenableBuilder<(int, int)?>(
        valueListenable: widget.game.pendingCellNotifier,
        builder: (context, cell, child) {
          if (cell == null) {
            return Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: ValueListenableBuilder<int?>(
                valueListenable: widget.game.pendingPropertyIdNotifier,
                builder: (context, placing, _) => Text(
                  placing == null
                      ? '放置失敗的原因會顯示在聊天的系統頻道'
                      : '已選定，點地圖上的格子預覽位置',
                  style: _ts(size: 10, color: Colors.white24),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('預覽於 (${cell.$1}, ${cell.$2})',
                      style: _ts(size: 10, color: Colors.white38)),
                ),
                GestureDetector(
                  onTap: () => widget.game.cancelPendingPlacement(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: _gold.withValues(alpha: 0.4)),
                    ),
                    child: Text('取消',
                        style: _ts(size: 11, color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.game.confirmPendingPlacement(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _goldBright),
                    ),
                    child:
                        Text('確定', style: _ts(size: 11, color: _goldBright)),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
