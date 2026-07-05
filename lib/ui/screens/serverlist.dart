import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../models/server_status.dart';
import '../theme/game_ui_styles.dart';

class ServerSelectOverlay extends StatefulWidget {
  final MyGame game;

  const ServerSelectOverlay(this.game, {super.key});

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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshStatuses() async {
    setState(() => _refreshing = true);
    await widget.game.refreshServerStatuses();
    if (!mounted) {
      return;
    }
    setState(() {
      _refreshing = false;
      _selected = widget.game.effectiveSelectedServer;
    });
  }

  void _confirm() {
    if (_selected == null) {
      return;
    }
    final status = widget.game.serverListService?.findByName(_selected!);
    if (status != null && !status.selectable) {
      return;
    }
    widget.game.selectedServer = _selected;
    widget.game.overlays.remove('ServerSelect');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: const Alignment(0, -0.3),
        child: _buildMainDialog(),
      ),
    );
  }

  Widget _buildMainDialog() {
    return Container(
      width: 540,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 12),
          _buildServerGrid(),
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '選擇伺服器',
          style: GameUiStyles.shadowTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_refreshing) ...[
          const SizedBox(width: 10),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerGrid() {
    final statuses = widget.game.serverStatuses;
    return SizedBox(
      height: 160,
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: statuses.map(_buildServerItem).toList(),
      ),
    );
  }

  Widget _buildServerItem(ServerStatus status) {
    final isSelected = status.name == _selected;
    final statusColor = _statusColor(status.loadStatus);

    return InkWell(
      onTap: status.selectable
          ? () => setState(() => _selected = status.name)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: status.selectable ? 1.0 : 0.55,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.name,
                      style: GameUiStyles.shadowTextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.loadStatus.label,
                    style: GameUiStyles.shadowTextStyle(fontSize: 12)
                        .copyWith(color: statusColor),
                  ),
                  if (status.max > 0) ...[
                    const Spacer(),
                    Text(
                      '${status.online}/${status.max}',
                      style: GameUiStyles.shadowTextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ServerLoadStatus status) {
    switch (status) {
      case ServerLoadStatus.smooth:
        return Colors.greenAccent;
      case ServerLoadStatus.crowded:
        return Colors.amberAccent;
      case ServerLoadStatus.full:
        return Colors.redAccent;
      case ServerLoadStatus.maintenance:
        return Colors.grey;
      case ServerLoadStatus.offline:
        return Colors.blueGrey;
      case ServerLoadStatus.unknown:
        return Colors.white70;
    }
  }

  Widget _buildActionButtons() {
    final canConfirm = _selected != null &&
        (widget.game.serverListService?.findByName(_selected!)?.selectable ??
            true);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => widget.game.overlays.remove('ServerSelect'),
          style: GameUiStyles.capsuleButtonStyle(),
          child: Text('取消', style: GameUiStyles.shadowTextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: canConfirm ? _confirm : null,
          style: GameUiStyles.capsuleButtonStyle(),
          child: Text('確認', style: GameUiStyles.shadowTextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
