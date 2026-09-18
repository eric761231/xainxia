import '../theme/game_design.dart';
import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../../utils/auth_input_validator.dart';
import 'serverlist.dart';
import '../layout/xaml/specs/account_ui_spec.dart';
import '../layout/xaml/ui_xaml_parts.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../widgets/shared/login_text_style.dart';
import '../widgets/shared/xaml_background.dart';

/// Shared transparent login form and collapsible server selector.
class AccountOverlay extends StatefulWidget {
  final MyGame game;

  const AccountOverlay(this.game, {super.key});

  @override
  State<AccountOverlay> createState() => _AccountOverlayState();
}

class _AccountOverlayState extends State<AccountOverlay> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoggingIn = false;
  bool _serverOpen = false;

  @override
  void initState() {
    super.initState();
    widget.game.selectedServerNotifier.addListener(_onSelectedServerChanged);
  }

  @override
  void dispose() {
    widget.game.selectedServerNotifier.removeListener(_onSelectedServerChanged);
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onSelectedServerChanged() {
    if (mounted) setState(() {});
  }

  void _openServerSelect() => setState(() => _serverOpen = !_serverOpen);

  Future<void> _exitGame() => widget.game.exitApplication();

  Future<void> _logoutAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('登出帳號'),
        content: const Text('確定要登出並返回登入畫面？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('登出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.game.logoutToAccount();
  }

  Future<void> _submit() async {
    if (_isLoggingIn) return;

    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    final server = widget.game.effectiveSelectedServer;

    final accountError = AuthInputValidator.validateAccount(user);
    if (accountError != null) return _showLoginFailedDialog(accountError);

    final passwordError = AuthInputValidator.validatePassword(pass);
    if (passwordError != null) return _showLoginFailedDialog(passwordError);

    if (server == null) return _showLoginFailedDialog('請選擇伺服器');

    setState(() => _isLoggingIn = true);
    try {
      final authResult = await widget.game.authenticate(user, pass, server);
      if (!mounted) return;
      if (authResult.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.game.onLoginSuccess();
        });
        return;
      }
      await _showLoginFailedDialog(authResult.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _showLoginFailedDialog(String message) =>
      GameMessageDialog.show(context, title: '登入失敗', message: message);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AccountUiSpec.holder.revision,
      builder: (context, _, child) => _build(AccountUiSpec.current),
    );
  }

  Widget _build(AccountUiSpec spec) {
    final serverLabel =
        widget.game.selectedServerNotifier.value ??
        widget.game.effectiveSelectedServer ??
        spec.serverSelect.text;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          XamlBackground(
            asset: spec.backgroundAsset,
            fallbackAsset: spec.fallbackBackgroundAsset,
            color: spec.backgroundColor,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900 && constraints.maxHeight >= 420;
                final formWidth = spec.account.box.width.clamp(240.0, 340.0);
                final panelWidth = wide ? 280.0 : formWidth;
                final stageWidth = (constraints.maxWidth - 40).clamp(240.0, 1280.0).toDouble();
                final loginWidth = wide ? formWidth : stageWidth.clamp(240.0, 520.0).toDouble();
                final stageHeight = wide ? 420.0 : 400.0;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: stageWidth,
                      height: stageHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: wide ? (stageWidth - formWidth) / 2 : 0,
                            top: wide ? 70.0 : -130.0,
                            child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: loginWidth,
                            child: AutofillGroup(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _field(
                                      spec.account,
                                      controller: _userCtrl,
                                      obscure: false,
                                    ),
                                    const SizedBox(height: 8),
                                    _field(
                                      spec.password,
                                      controller: _passCtrl,
                                      obscure: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _button(
                                      spec.submit,
                                      label: _isLoggingIn
                                          ? '登入中…'
                                          : spec.submit.text,
                                      onPressed: _isLoggingIn ? null : _submit,
                                    ),
                                    _button(
                                      spec.session,
                                      label: widget.game.isLoggedIn
                                          ? '登出帳號'
                                          : '離開遊戲',
                                      onPressed: _isLoggingIn
                                          ? null
                                          : (widget.game.isLoggedIn
                                                ? _logoutAccount
                                                : _exitGame),
                                    ),
                                    if (!wide) ...[
                                      const SizedBox(height: 8),
                                      _button(
                                        spec.serverSelect,
                                        label: _serverOpen
                                            ? '收合伺服器列表'
                                            : '伺服器列表${serverLabel == spec.serverSelect.text ? '' : ' · $serverLabel'}',
                                        onPressed: _isLoggingIn ? null : _openServerSelect,
                                      ),
                                      if (_serverOpen)
                                        ServerSelectOverlay(
                                          widget.game,
                                          onClose: () => setState(() => _serverOpen = false),
                                        ),
                                    ],
                                  ],
                                ),
                            ),
                          ),
                          if (wide) const SizedBox(width: 20),
                          if (wide)
                            SizedBox(
                              width: panelWidth,
                              child: _serverOpen
                                  ? ServerSelectOverlay(
                                      widget.game,
                                      onClose: () => setState(() => _serverOpen = false),
                                    )
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        tooltip: '展開伺服器列表',
                                        onPressed: _isLoggingIn ? null : _openServerSelect,
                                        icon: Text('‹', style: loginTextStyle(28)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    XamlField spec, {
    required TextEditingController controller,
    required bool obscure,
  }) => SizedBox(
    height: spec.box.height.clamp(48.0, 56.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          child: Text(spec.hint, style: loginTextStyle(spec.textSize)),
        ),
        Expanded(child: TextField(
      key: ValueKey(obscure ? 'login-password' : 'login-account'),
      controller: controller,
      obscureText: obscure,
      enabled: !_isLoggingIn,
      autocorrect: false,
      enableSuggestions: !obscure,
      autofillHints: [
        obscure ? AutofillHints.password : AutofillHints.username,
      ],
      textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
      onSubmitted: obscure ? (_) => _submit() : null,
      style: loginTextStyle(spec.textSize),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        isDense: true,
        hintText: null,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ))),
      ],
    ),
  );

  Widget _button(
    XamlButton spec, {
    required String label,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: spec.box.height.clamp(48.0, 56.0),
    child: TextButton(
      onPressed: onPressed,
      style: GameDesign.button(primary: spec == AccountUiSpec.current.submit),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: loginTextStyle(spec.textSize, enabled: onPressed != null),
      ),
    ),
  );
}
