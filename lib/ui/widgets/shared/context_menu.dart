import 'package:flutter/material.dart';

import '../../theme/game_panel_theme.dart';

/// 右鍵／長按選單的一個項目。
class ContextMenuItem {
  const ContextMenuItem(this.label, this.onTap, {this.danger = false});

  final String label;
  final VoidCallback onTap;

  /// 危險操作（驅逐、離開隊伍）以紅字呈現。
  final bool danger;
}

/// 一次選單的請求：在哪裡、顯示哪些項目。
class ContextMenuRequest {
  const ContextMenuRequest({
    required this.position,
    required this.items,
    this.title,
  });

  /// 螢幕座標（全域），通常來自手勢的 `globalPosition`。
  final Offset position;
  final List<ContextMenuItem> items;

  /// 選單標題，通常是被點的對象名稱。
  final String? title;
}

/// 由 [ContextMenuRequest] 驅動的彈出選單浮層。
///
/// 刻意**不用 `showMenu`** —— 這個選單要疊在 Flame 的 GameWidget overlay 之上，
/// 而 `showMenu` 會推一個 route，它的定位基準與關閉時機都不受這裡控制，
/// 在遊戲畫面上很容易出現位置飄掉或關不掉的狀況。
/// 改為一個吃滿整個 Stack 的透明層：點空白即關閉，位置自己算。
class ContextMenuOverlay extends StatelessWidget {
  const ContextMenuOverlay({
    required this.request,
    required this.onDismiss,
    super.key,
  });

  final ContextMenuRequest request;
  final VoidCallback onDismiss;

  static const _width = 168.0;
  static const _itemH = 44.0;
  static const _titleH = 36.0;
  static const _margin = 8.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final height = request.items.length * _itemH +
        (request.title != null ? _titleH : 0) +
        8;

    // 夾在畫面內：靠右就往左翻、靠下就往上翻，否則手機上選單會被切掉。
    var left = request.position.dx;
    var top = request.position.dy;
    if (left + _width + _margin > screen.width) {
      left = screen.width - _width - _margin;
    }
    if (top + height + _margin > screen.height) {
      top = screen.height - height - _margin;
    }
    left = left.clamp(_margin, (screen.width - _width - _margin).clamp(_margin, double.infinity));
    top = top.clamp(_margin, (screen.height - height - _margin).clamp(_margin, double.infinity));

    return Stack(
      children: [
        // 吃掉整個畫面的點擊 → 關閉選單
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: _width,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: PanelTheme.panelDeco(r: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (request.title != null)
                  SizedBox(
                    height: _titleH,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          request.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PanelTheme.ts(
                              size: 11, color: PanelTheme.goldBright),
                        ),
                      ),
                    ),
                  ),
                for (final item in request.items)
                  _MenuRow(item: item, onDismiss: onDismiss),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.item, required this.onDismiss});

  final ContextMenuItem item;
  final VoidCallback onDismiss;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.item.danger ? PanelTheme.danger : Colors.white.withValues(alpha: 0.85);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // 先關再執行：選單是浮層，執行中若又開一個選單才不會被自己關掉
          widget.onDismiss();
          widget.item.onTap();
        },
        child: Container(
          height: ContextMenuOverlay._itemH,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: _hover ? PanelTheme.cellBg : Colors.transparent,
          child: Text(widget.item.label,
              style: PanelTheme.ts(size: 12, color: color)),
        ),
      ),
    );
  }
}
