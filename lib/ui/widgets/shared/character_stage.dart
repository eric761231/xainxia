import 'package:flutter/material.dart';
import '../../theme/game_design.dart';
import '../../layout/char_create/char_create_ui_assets.dart';
import '../char_create/char_create_center_panel.dart';

class GameAction extends StatelessWidget {
  const GameAction(this.label, {super.key, this.onPressed, this.primary = false,
    this.danger = false});
  final String label;
  final VoidCallback? onPressed;
  final bool primary, danger;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed, style: GameDesign.button(primary: primary, danger: danger),
    child: Text(label, style: GameDesign.text(size: 18,
      color: onPressed == null ? Colors.white54 : danger ? GameDesign.danger : Colors.white)),
  );
}

class StageHeading extends StatelessWidget {
  const StageHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(children: [Text(text, style: GameDesign.text(size: 26)),
      const SizedBox(height: 12),
      const Divider(height: 1, color: GameDesign.gold, indent: 16, endIndent: 16)]),
  );
}

/// Both character pages use the same art bounds, safe area and footer.
/// Narrow windows reflow vertically instead of shrinking text or hit targets.
class CharacterStage extends StatelessWidget {
  const CharacterStage({super.key, required this.sex, required this.left,
    required this.right, required this.footer, required this.onBack});
  final int? sex;
  final Widget left, right, footer;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF263C43),
    child: Stack(fit: StackFit.expand, children: [
      Image.asset(CharCreateUiAssets.bg, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        colors: [Color(0x55203942), Color(0x10203942), Color(0x55203942)],
      ))),
      SafeArea(child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 1000 && c.maxHeight >= 600;
        final portrait = sex == null ? const SizedBox.shrink()
          : CharCreateCenterPanel(sex: sex!);
        if (!wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(alignment: Alignment.centerLeft, child: GameAction('返回', onPressed: onBack)),
              SizedBox(height: 420, child: portrait),
              left, const SizedBox(height: 24), right,
              const SizedBox(height: 24), footer,
            ]),
          );
        }
        final margin = c.maxWidth >= 1600 ? 64.0 : 32.0;
        final side = (c.maxWidth * .24).clamp(240.0, 370.0);
        return Padding(padding: EdgeInsets.fromLTRB(margin, 12, margin, 20),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft, child: GameAction('返回', onPressed: onBack)),
            Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(width: side, child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12), child: left)),
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: portrait)),
              SizedBox(width: side, child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12), child: right)),
            ])),
            const SizedBox(height: 12), footer,
          ]),
        );
      })),
    ]),
  );
}
