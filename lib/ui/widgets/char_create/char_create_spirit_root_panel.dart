import 'package:flutter/material.dart';
import '../../../models/char_create_template.dart';
import '../../theme/game_design.dart';
import '../shared/character_stage.dart';

class CharCreateSpiritRootPanel extends StatelessWidget {
  const CharCreateSpiritRootPanel({super.key, required this.selectedIndex,
    required this.enabled, required this.onSelected});
  final int selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final selected = CharCreateTemplate.spiritRootDetails[selectedIndex];
    return Column(children: [
      const StageHeading('選擇靈根'),
      for (var row = 0; row < 4; row++)
        Row(children: [for (var col = 0; col < 2; col++)
          Expanded(child: _item(row * 2 + col)),
        ]),
      const SizedBox(height: 16),
      Text(selected.name, style: GameDesign.text(size: 22, color: GameDesign.gold)),
      const SizedBox(height: 8),
      Text(selected.description, textAlign: TextAlign.center, style: GameDesign.text()),
    ]);
  }
  Widget _item(int index) {
    final root = CharCreateTemplate.spiritRootDetails[index];
    final active = index == selectedIndex;
    return Semantics(selected: active, child: TextButton(
      key: ValueKey('root-$index'),
      onPressed: enabled ? () => onSelected(index) : null,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
      child: Column(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 160),
          width: 50, height: 50, padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: active ? const Color(0x44306664) : const Color(0x18203942),
            border: Border.all(color: active ? GameDesign.gold : GameDesign.jade.withValues(alpha: .5), width: active ? 2 : 1),
            boxShadow: active ? [BoxShadow(color: GameDesign.gold.withValues(alpha: .25), blurRadius: 14)] : null),
          child: Image.asset(root.iconAsset, fit: BoxFit.contain)),
        const SizedBox(height: 4),
        Text(root.name.substring(0, 1), style: GameDesign.text(size: 20,
          color: active ? GameDesign.gold : Colors.white)),
      ]),
    ));
  }
}
