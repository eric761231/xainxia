import 'package:flutter/material.dart';

import '../../game/my_game.dart';
import '../widgets/shared/game_message_dialog.dart';
import '../theme/game_ui_styles.dart';
import '../../utils/auth_input_validator.dart';

/// AccountOverlay：帳號登入主介面，負責帳密輸入與觸發登入。
class AccountOverlay extends StatefulWidget {
  final MyGame game;

  const AccountOverlay(this.game, {super.key});

  @override
  State<AccountOverlay> createState() => _AccountOverlayState();
}

class _AccountOverlayState extends State<AccountOverlay> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

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
    if (mounted) {
      setState(() {});
    }
  }

  void _openServerSelect() {
    widget.game.overlays.add('ServerSelect');
  }

  void _showLoginPanel() {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.0),
      builder: (ctx) {
        return _LoginDialog(
          game: widget.game,
          userCtrl: _userCtrl,
          passCtrl: _passCtrl,
          onSuccess: () {
            widget.game.onLoginSuccess();
          },
        );
      },
    );
  }

  Future<void> _exitGame() async {
    await widget.game.exitApplication();
  }

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

  @override
  Widget build(BuildContext context) {
    final serverLabel =
        widget.game.selectedServerNotifier.value ?? '選擇伺服器';
    final loggedIn = widget.game.isLoggedIn;

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/loading.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/launch_bg.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF140E0C)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loggedIn)
                    _transparentButton(
                      label: '登出帳號',
                      onPressed: _logoutAccount,
                    )
                  else
                    _transparentButton(
                      label: '離開遊戲',
                      onPressed: _exitGame,
                    ),
                  const SizedBox(width: 12),
                  _transparentButton(
                    label: '帳號 / 登入',
                    onPressed: _showLoginPanel,
                  ),
                  const SizedBox(width: 12),
                  _transparentButton(
                    label: serverLabel,
                    onPressed: _openServerSelect,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transparentButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: Text(
        label,
        style: GameUiStyles.shadowTextStyle(fontSize: 16),
      ),
    );
  }
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog({
    required this.game,
    required this.userCtrl,
    required this.passCtrl,
    required this.onSuccess,
  });

  final MyGame game;
  final TextEditingController userCtrl;
  final TextEditingController passCtrl;
  final VoidCallback onSuccess;

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  bool _isLoggingIn = false;

  Future<void> _submit() async {
    if (_isLoggingIn) {
      return;
    }

    final user = widget.userCtrl.text.trim();
    final pass = widget.passCtrl.text;
    final server = widget.game.effectiveSelectedServer;

    final accountError = AuthInputValidator.validateAccount(user);
    if (accountError != null) {
      await _showLoginFailedDialog(accountError);
      return;
    }

    final passwordError = AuthInputValidator.validatePassword(pass);
    if (passwordError != null) {
      await _showLoginFailedDialog(passwordError);
      return;
    }

    if (server == null) {
      await _showLoginFailedDialog('請選擇伺服器');
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final authResult =
          await widget.game.authenticate(user, pass, server);

      if (!mounted) {
        return;
      }

      if (authResult.success) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onSuccess();
          });
        } else {
          widget.onSuccess();
        }
        return;
      }

      await _showLoginFailedDialog(authResult.message);
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _showLoginFailedDialog(String message) {
    return GameMessageDialog.show(
      context,
      title: '登入失敗',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: widget.userCtrl,
                labelText: '帳號',
                hintText: '4～12 字，小寫英數',
                enabled: !_isLoggingIn,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: widget.passCtrl,
                labelText: '密碼',
                hintText: '4～13 字',
                isPassword: true,
                enabled: !_isLoggingIn,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoggingIn
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: GameUiStyles.capsuleButtonStyle(),
                    child: Text(
                      '取消',
                      style: GameUiStyles.shadowTextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _submit,
                    style: GameUiStyles.capsuleButtonStyle(),
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '登入',
                            style: GameUiStyles.shadowTextStyle(fontSize: 14),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GameUiStyles.shadowTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          enabled: enabled,
          style: GameUiStyles.shadowTextStyle(fontSize: 15),
          cursorColor: const Color(0xFFBF8A5A),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GameUiStyles.shadowTextStyle(fontSize: 13).copyWith(
              color: Colors.white70,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xFF8B5E3C).withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBF8A5A), width: 2.5),
            ),
            disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xFF8B5E3C).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
