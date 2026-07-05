import 'package:flutter/material.dart';

import '../../theme/game_ui_assets.dart';
import '../../theme/game_ui_styles.dart';

/// 訊息對話框：底圖 + 標題 + 內文 + 文字按鈕。
///
/// UI 結構（只有 2 層嵌套就完成面板）：
///
///   showDialog
///     Material + Center
///       Stack  ← 底圖與文字疊在同一層
///         ├─ Image（dialog_message_bg.png）
///         └─ Padding → Column（標題、內文、OK 文字按鈕）
///
/// 用法：
/// ```dart
/// GameMessageDialog.show(
///   context: context,
///   title: '登入失敗',
///   message: '帳號或密碼錯誤',
/// );
/// ```
class GameMessageDialog extends StatelessWidget {
  const GameMessageDialog({
    required this.title,
    required this.message,
    this.okLabel = 'OK',
    super.key,
  });

  final String title;
  final String message;
  final String okLabel;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String okLabel = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => GameMessageDialog(
        title: title,
        message: message,
        okLabel: okLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(child: _buildPanel(context)),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          GameUiAssets.dialogMessageBg,
          width: 360,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _fallbackBackground(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GameUiStyles.shadowTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GameUiStyles.shadowTextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: GameUiStyles.capsuleButtonStyle(),
                child: Text(
                  okLabel,
                  style: GameUiStyles.shadowTextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackBackground() {
    return Container(
      width: 360,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
