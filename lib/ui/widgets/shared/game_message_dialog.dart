import 'package:flutter/material.dart';
import '../../theme/game_design.dart';
import 'character_stage.dart';

/// Shared responsive dialog. Content scrolls independently of actions.
class GameMessageDialog extends StatelessWidget {
  const GameMessageDialog({super.key, required this.title, required this.message,
    this.okLabel = '確認', this.confirmation = false, this.danger = false});
  final String title, message, okLabel;
  final bool confirmation, danger;
  static Future<void> show(BuildContext context, {required String title,
    required String message, String okLabel = '確認', bool barrierDismissible = false}) =>
    showDialog<void>(context: context, barrierDismissible: barrierDismissible,
      builder: (_) => GameMessageDialog(title: title, message: message, okLabel: okLabel));
  static Future<bool?> confirm(BuildContext context, {required String title,
    required String message, String confirmLabel = '確認', bool danger = false}) =>
    showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => GameMessageDialog(title: title, message: message,
        okLabel: confirmLabel, confirmation: true, danger: danger));
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: GameDesign.ink, elevation: 0,
    insetPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: GameDesign.text(size: 24, color: danger ? GameDesign.danger : GameDesign.gold)),
          const SizedBox(height: 20),
          Flexible(child: SingleChildScrollView(child: Text(message,
            textAlign: TextAlign.center, style: GameDesign.text(size: 18)))),
          const SizedBox(height: 24),
          Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.center, children: [
            if(confirmation) GameAction('取消', onPressed: () => Navigator.of(context).pop(false)),
            GameAction(okLabel, primary: !danger, danger: danger,
              onPressed: () { if(confirmation) { Navigator.of(context).pop(true); }
                else { Navigator.of(context).pop(); } }),
          ]),
        ]))),
  );
}
