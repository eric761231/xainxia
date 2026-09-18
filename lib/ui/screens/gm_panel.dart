import '../widgets/shared/panel_drag_bounds.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../game/tile_tool_mode.dart';
import '../../network/packets/server/s_map_list.dart';
import '../theme/game_panel_theme.dart';

// PanelTheme 的別名 —— 面板內有大量引用，保留短名稱、實作指向共用主題。
const _gold = PanelTheme.gold;
const _goldBright = PanelTheme.goldBright;
const _panelBg = PanelTheme.panelBg;

TextStyle _ts({double size = 12, Color color = Colors.white}) =>
    PanelTheme.ts(size: size, color: color);

/// GM 分頁。本輪只實作「傳送」，其餘先留骨架。
enum _GmTab {
  teleport('傳送'),
  collision('碰撞'),
  spawn('生怪'),
  item('道具'),
  character('角色');

  const _GmTab(this.label);
  final String label;
}

/// GM 專用面板。
///
/// 只有 GM 角色看得到（由 HUD 依 accessLevel 決定是否 render）。
/// 指令一律走 `C_GM_COMMAND`，伺服器每次都會重驗 access_level ——
/// 前端的可見性判斷只是介面過濾，不是安全機制。
class GmPanel extends StatefulWidget {
  const GmPanel(this.game, {super.key});

  final MyGame game;

  @override
  State<GmPanel> createState() => _GmPanelState();
}

class _GmPanelState extends State<GmPanel> {
  final _commandController = TextEditingController();
  final _commandFocus = FocusNode();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  _GmTab _tab = _GmTab.teleport;
  Offset _offset = Offset.zero;
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 開啟時取一次地圖清單；伺服器回 S_MAP_LIST 存進 mapListNotifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.game.gameWorldService?.sendGmCommand('maps');
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _commandFocus.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _run(String command) {
    widget.game.gameWorldService?.sendGmCommand(command);
  }

  void _submitCommand(String raw) {
    final text = raw.trim();
    _commandController.clear();
    if (text.isEmpty) return;
    // 容許使用者習慣性打上前綴
    _run(text.startsWith('.') ? text.substring(1) : text);
    _commandFocus.requestFocus();
  }

  void _teleport(int mapId) {
    final x = int.tryParse(_xController.text.trim());
    final y = int.tryParse(_yController.text.trim());
    _run(x != null && y != null ? 'tp $mapId $x $y' : 'tp $mapId');
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset,
      child: Container(
        key: _contentKey,
        width: 420,
        height: 460,
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PanelTheme.panelBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            const Divider(height: 1, color: PanelTheme.divider),
            _buildConsole(),
          ],
        ),
      ),
    );
  }

  /// 標題列：只有這裡可拖曳。
  ///
  /// 刻意不把整個面板包進拖曳手勢 —— 那會跟裡面的輸入框與清單捲動搶手勢。
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
              const Icon(Icons.shield_moon_outlined,
                  size: 16, color: _goldBright),
              const SizedBox(width: 6),
              Text('GM 工具', style: _ts(size: 13, color: _goldBright)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.game.gmPanelOpenNotifier.value = false,
                child: SizedBox(width: 44, height: 44, child: Icon(Icons.close, size: 20, color: _gold)),
              ),
            ],
          ),
        ),
      );

  Widget _buildTabBar() => SizedBox(
        height: 44,
        child: Row(
          children: [
            for (final t in _GmTab.values)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = t),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t == _tab
                          ? _gold.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: const Border(
                        bottom: BorderSide(color: PanelTheme.divider),
                      ),
                    ),
                    child: Text(
                      t.label,
                      style: _ts(
                        size: 12,
                        color: t == _tab ? _goldBright : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildTabContent() {
    switch (_tab) {
      case _GmTab.teleport:
        return _buildTeleportTab();
      case _GmTab.collision:
        return _buildCollisionTab();
      default:
        return Center(
          child: Text('「${_tab.label}」尚未實作',
              style: _ts(size: 12, color: Colors.white30)),
        );
    }
  }

  /// 碰撞編輯分頁：開關編輯模式，並顯示目前這張地圖有幾格被擋。
  ///
  /// 地形是全體共用的，改了所有人立刻看到 —— 提示裡講明，
  /// 避免 GM 以為只是自己的預覽。
  Widget _buildCollisionTab() => ValueListenableBuilder<TileTool>(
        valueListenable: widget.game.tileToolNotifier,
        builder: (context, tool, child) {
          final editing = tool == TileTool.collision;
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editing
                      ? '編輯中：點格子切換可否通行（紅＝擋住）'
                      : '開啟後點擊地圖格子即可設定地形碰撞',
                  style: _ts(
                      size: 11,
                      color: editing
                          ? const Color(0xFFE08A8A)
                          : Colors.white54),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.game.setTileTool(
                      editing ? TileTool.none : TileTool.collision),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: editing
                          ? const Color(0x33E08A8A)
                          : _gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: editing
                              ? const Color(0xFFE08A8A)
                              : _gold.withValues(alpha: 0.45)),
                    ),
                    child: Text(editing ? '結束編輯' : '開始編輯',
                        style: _ts(
                            size: 12,
                            color: editing
                                ? const Color(0xFFE08A8A)
                                : _goldBright)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '目前地圖共 ${widget.game.currentTerrain.length} 格不可通行',
                  style: _ts(size: 11, color: Colors.white38),
                ),
                const SizedBox(height: 6),
                Text(
                  '地形對所有玩家生效，且會寫入資料庫永久保存。',
                  style: _ts(size: 10, color: Colors.white24),
                ),
                Text(
                  '指令備援：.collision list ／ .collision <x> <y> on|off ／ .collision clear',
                  style: _ts(size: 10, color: Colors.white24),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildTeleportTab() {
    final service = widget.game.gameWorldService;
    if (service == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Row(
            children: [
              Text('座標', style: _ts(size: 11, color: Colors.white54)),
              const SizedBox(width: 8),
              _coordField(_xController, 'X'),
              const SizedBox(width: 6),
              _coordField(_yController, 'Y'),
              const SizedBox(width: 8),
              Expanded(
                child: Text('留空則傳送到地圖中央',
                    style: _ts(size: 10, color: Colors.white30)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<MapListEntry>>(
            valueListenable: service.mapListNotifier,
            builder: (context, maps, child) {
              if (maps.isEmpty) {
                return Center(
                  child: Text('地圖清單載入中…',
                      style: _ts(size: 11, color: Colors.white30)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: maps.length,
                itemBuilder: (context, i) {
                  final m = maps[i];
                  return InkWell(
                    onTap: () => _teleport(m.mapId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('${m.mapId}',
                                style: _ts(size: 11, color: _gold)),
                          ),
                          Expanded(
                            child: Text(m.name,
                                style: _ts(size: 12, color: Colors.white70)),
                          ),
                          const Icon(Icons.my_location,
                              size: 14, color: Color(0x66C9A24B)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _coordField(TextEditingController c, String hint) => SizedBox(
        width: 46,
        height: 24,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          style: _ts(size: 11),
          cursorColor: _goldBright,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            hintText: hint,
            hintStyle: _ts(size: 11, color: Colors.white24),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _gold.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: _goldBright),
            ),
          ),
        ),
      );

  /// 底部主控台：自由指令輸入 + 輸出區（與聊天完全分離）。
  Widget _buildConsole() {
    final service = widget.game.gameWorldService;
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          Expanded(
            child: service == null
                ? const SizedBox.shrink()
                : ValueListenableBuilder<List<String>>(
                    valueListenable: service.gmLogNotifier,
                    builder: (context, log, child) {
                      if (log.isEmpty) {
                        return Center(
                          child: Text('輸入指令，或用 help 看清單',
                              style: _ts(size: 11, color: Colors.white24)),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                        reverse: true,
                        itemCount: log.length,
                        itemBuilder: (context, i) {
                          final line = log[log.length - 1 - i];
                          final isEcho = line.startsWith('>');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: _ts(
                                size: 11,
                                color: isEcho
                                    ? const Color(0xFF9FD6FF)
                                    : Colors.white70,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text('>', style: _ts(size: 12, color: _gold)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    focusNode: _commandFocus,
                    onSubmitted: _submitCommand,
                    textInputAction: TextInputAction.send,
                    style: _ts(size: 11),
                    cursorColor: _goldBright,
                    cursorHeight: 13,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: 'tp 1 40 40',
                      hintStyle: _ts(size: 11, color: Colors.white24),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _submitCommand(_commandController.text),
                  child: const Icon(Icons.send, size: 15, color: _goldBright),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
