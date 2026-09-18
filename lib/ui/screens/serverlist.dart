import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../models/server_status.dart';
import '../layout/xaml/specs/server_select_ui_spec.dart';
import '../layout/xaml/ui_xaml_parts.dart';
import '../widgets/shared/login_text_style.dart';

/// 伺服器選單。
///
/// 版面來自 `assets/ui/xaml/server_select.xaml`；可選與否、狀態顏色對應、更新與
/// 確認流程仍在 Dart。
class ServerSelectOverlay extends StatefulWidget {
  final MyGame game;

  const ServerSelectOverlay(this.game, {super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<ServerSelectOverlay> createState() => _ServerSelectOverlayState();
}

class _ServerSelectOverlayState extends State<ServerSelectOverlay> {
  String? _selected;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.game.effectiveSelectedServer;
    widget.game.serverStatusesNotifier.addListener(_onStatusesUpdated);
    _refreshStatuses();
  }

  @override
  void dispose() {
    widget.game.serverStatusesNotifier.removeListener(_onStatusesUpdated);
    super.dispose();
  }

  void _onStatusesUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshStatuses() async {
    setState(() => _refreshing = true);
    await widget.game.refreshServerStatuses();
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      // 刷新不能把有效的選擇洗掉：沿用 effectiveSelectedServer，它在目前選擇
      // 仍然合法時會回傳同一個名字。
      _selected = widget.game.effectiveSelectedServer;
    });
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      widget.game.overlays.remove('ServerSelect');
    }
  }

  void _confirm() {
    final name = _selected;
    if (name == null) return;
    final status = widget.game.serverListService?.findByName(name);
    if (status != null && !status.selectable) return;
    widget.game.selectedServer = name;
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ServerSelectUiSpec.holder.revision,
      builder: (context, _, child) => _build(ServerSelectUiSpec.current),
    );
  }

  Widget _build(ServerSelectUiSpec spec) {
    final selected = widget.game.serverStatuses.where(
      (s) => s.name == _selected,
    );
    final canConfirm = selected.isNotEmpty && selected.first.selectable;
    final content = Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text('伺服器列表', style: loginTextStyle(spec.title.size)),
                Positioned(
                  right: 0,
                  child: IconButton(
                    tooltip: '收合伺服器選單',
                    onPressed: _close,
                    icon: Text('›', style: loginTextStyle(28)),
                  ),
                ),
              ],
            ),
          ),
          if (_refreshing)
            Text(
              spec.refreshing.text,
              style: loginTextStyle(spec.refreshing.size),
            ),
          if (widget.game.serverStatuses.isEmpty && !_refreshing)
            Text('暫無可用伺服器', style: loginTextStyle(16)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.game.serverStatuses.length,
              separatorBuilder: (_, index) =>
                  SizedBox(height: spec.grid.rowGap),
              itemBuilder: (context, index) => SizedBox(
                height: spec.grid.itemHeight,
                child: _item(widget.game.serverStatuses[index], spec.grid, 1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _button(spec.cancel, onPressed: _close)),
              Expanded(
                child: _button(
                  spec.confirm,
                  onPressed: canConfirm ? _confirm : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (widget.onClose != null) return content;
    // Compatibility for callers outside the account page.
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SizedBox(width: 300, child: content),
        ),
      ),
    );
  }

  Widget _item(ServerStatus status, ServerGridSpec spec, double scale) {
    final isSelected = status.name == _selected;
    // The indicator is intentionally binary for quick scanning: green means
    // selectable, red means unavailable. The adjacent label keeps the detail.
    final statusColor = status.selectable ? Colors.greenAccent : Colors.redAccent;

    return Opacity(
      opacity: status.selectable ? 1.0 : spec.disabledOpacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: status.selectable
            ? () => setState(() => _selected = status.name)
            : null,
        child: Semantics(
          selected: isSelected,
          button: true,
          child: Row(
            children: [
              Expanded(child: Text(status.name, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: loginTextStyle(spec.nameSize * scale))),
              const SizedBox(width: 10),
              Container(width: 8 * scale, height: 8 * scale,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              SizedBox(width: 48, child: Text(status.loadStatus.label,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: loginTextStyle(spec.statusSize * scale))),
              const SizedBox(width: 8),
              Container(width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.white : Colors.white54,
                    width: isSelected ? 3 : 2),
                  color: isSelected ? Colors.amberAccent : Colors.transparent),
                child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(XamlButton spec, {required VoidCallback? onPressed}) =>
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(
          spec.text,
          style: loginTextStyle(spec.textSize, enabled: onPressed != null),
        ),
      );
}
