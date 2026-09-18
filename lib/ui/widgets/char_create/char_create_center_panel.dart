import 'package:flutter/material.dart';
import '../../layout/char_create/char_create_ui_assets.dart';

/// Art occupies only the stage body; footer and sidebars have separate bounds.
class CharCreateCenterPanel extends StatelessWidget {
  const CharCreateCenterPanel({super.key, required this.sex});
  final int sex;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Image.asset(CharCreateUiAssets.portrait(sex),
      fit: BoxFit.contain, alignment: Alignment.bottomCenter,
      gaplessPlayback: true,
      errorBuilder: (_, error, stack) => const Icon(Icons.person, size: 120, color: Colors.white),
    ),
  );
}
