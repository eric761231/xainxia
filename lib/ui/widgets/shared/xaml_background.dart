import 'package:flutter/material.dart';

/// 全螢幕背景：主素材 → fallback 素材 → 純色。
///
/// Loading、登入、伺服器選單、選角、創角共用同一張 `loginFlowBg`，所以這段
/// 「三層退路」也該只有一份。各畫面各寫一次 errorBuilder 的話，之後換背景素材
/// 就得記得五個地方都要改。
class XamlBackground extends StatelessWidget {
  const XamlBackground({
    super.key,
    required this.asset,
    required this.fallbackAsset,
    required this.color,
  });

  final String asset;
  final String fallbackAsset;
  final Color color;

  @override
  Widget build(BuildContext context) => _image(asset);

  Widget _image(String path) => Image.asset(
        path,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            path == asset && asset != fallbackAsset
                ? _image(fallbackAsset)
                : ColoredBox(color: color),
      );
}
