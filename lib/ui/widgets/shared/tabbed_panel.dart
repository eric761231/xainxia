import 'panel_drag_bounds.dart';
import 'package:flutter/material.dart';

import '../../theme/game_panel_theme.dart';

/// 標題列 + 分頁 + 內容的通用面板。
///
/// 社交（好友／門派）與修練（練氣／靈寵）的結構完全一樣，
/// 差別只在標題與各分頁的內容，所以抽成同一個元件而不是複製兩份。
/// 面板本身可拖曳，但**只有標題列吃拖曳手勢** —— 整個面板都可拖的話，
/// 會跟內容裡的清單捲動、輸入框搶手勢（GM 面板踩過這個坑）。
class TabbedPanel extends StatefulWidget {
  const TabbedPanel({
    required this.title,
    required this.icon,
    required this.tabs,
    required this.builder,
    required this.onClose,
    this.width = 300,
    this.height = 380,
    super.key,
  });

  final String title;
  final IconData icon;

  /// 分頁名稱，依序顯示。
  final List<String> tabs;

  /// 依分頁索引建立內容。
  final Widget Function(BuildContext context, int index) builder;

  final VoidCallback onClose;
  final double width;
  final double height;

  @override
  State<TabbedPanel> createState() => _TabbedPanelState();
}

class _TabbedPanelState extends State<TabbedPanel> {
  int _tab = 0;
  Offset _offset = Offset.zero;
  final _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset,
      child: Container(
        key: _contentKey,
        width: widget.width,
        height: widget.height,
        decoration: PanelTheme.panelDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            _buildTabBar(),
            Expanded(child: widget.builder(context, _tab)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => setState(() => _offset = boundedPanelOffset(context, _contentKey, _offset, d.delta)),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: PanelTheme.cellBg,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(PanelTheme.radius - 1)),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: PanelTheme.goldBright),
              const SizedBox(width: 6),
              Text(widget.title,
                  style:
                      PanelTheme.ts(size: 13, color: PanelTheme.goldBright)),
              const Spacer(),
              GestureDetector(
                onTap: widget.onClose,
                child: SizedBox(width: 44, height: 44, child: Icon(Icons.close, size: 20, color: PanelTheme.gold)),
              ),
            ],
          ),
        ),
      );

  Widget _buildTabBar() => SizedBox(
        height: 44,
        child: Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    alignment: Alignment.center,
                    color: i == _tab
                        ? PanelTheme.cellBgActive
                        : Colors.transparent,
                    child: Text(
                      widget.tabs[i],
                      style: PanelTheme.ts(
                        size: 12,
                        color: i == _tab
                            ? PanelTheme.goldBright
                            : PanelTheme.textDim,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// 面板內部常用的小按鈕（好友列的組隊／密語／寄信、隊伍的離開等）。
class PanelButton extends StatelessWidget {
  const PanelButton({
    required this.label,
    required this.onTap,
    this.danger = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  /// true = 撐滿寬度（底部的主要動作用）。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: danger
            ? PanelTheme.danger.withValues(alpha: 0.16)
            : PanelTheme.cellBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: PanelTheme.ts(
          size: 10,
          color: danger ? PanelTheme.danger : Colors.white70,
        ),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: expand ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}
