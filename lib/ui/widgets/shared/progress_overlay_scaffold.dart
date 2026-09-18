import '../../theme/game_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../layout/ui_scale.dart';
import '../../layout/xaml/specs/loading_ui_spec.dart';
import 'energy_loading_bar.dart';
import '../../layout/char_create/char_create_ui_assets.dart';

/// 載入 / 過場 overlay 共用骨架。
///
/// 版面全部來自 [LoadingUiSpec]（即 `loading.xaml`）：背景素材、訊息位置與字級、
/// 進度條位置與外觀。呼叫端只提供進度值，以及過場時要覆寫的訊息文字。
///
/// 縮放用 [UiScale.compute] 而非 `updateFrom`：這是疊在其他畫面上的 overlay，
/// 動到共用的全域係數會讓底下那頁在 overlay 出現時跳版。
class ProgressOverlayScaffold extends StatelessWidget {
  const ProgressOverlayScaffold({
    super.key,
    required this.progress,
    this.messageOverride,
    this.spec,
    this.portraitSex,
  });

  /// 進度 0.0–1.0。
  final ValueListenable<double> progress;
  final int? portraitSex;

  /// 過場畫面用；null 時顯示 XAML 裡的 `message` 文字。
  final ValueListenable<String>? messageOverride;

  /// 測試可注入；正式使用 [LoadingUiSpec.current]。
  final LoadingUiSpec? spec;

  @override
  Widget build(BuildContext context) {
    final s = spec ?? LoadingUiSpec.current;
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale =
              UiScale.compute(
                Size(constraints.maxWidth, constraints.maxHeight),
                designWidth: 1920,
                designHeight: 1080,
              ) ??
              1.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: _Background(spec: s)),
              if (portraitSex != null)
                Positioned(
                  top: 24 * scale,
                  bottom:
                      (constraints.maxHeight / 2 -
                              (s.messageCenterY - 540) * scale +
                              40 * scale)
                          .clamp(0.0, constraints.maxHeight),
                  left: constraints.maxWidth * 0.15,
                  right: constraints.maxWidth * 0.15,
                  child: IgnorePointer(
                    child: Image.asset(
                      CharCreateUiAssets.portrait(portraitSex!),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              _centered(
                x: s.messageCenterX,
                y: s.messageCenterY,
                scale: scale,
                constraints: constraints,
                child: _message(s, scale),
              ),
              _centered(
                x: s.barCenterX,
                y: s.barCenterY,
                scale: scale,
                constraints: constraints,
                child: ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, child) =>
                      EnergyLoadingBar(progress: value, spec: s, scale: scale),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _message(LoadingUiSpec s, double scale) {
    final style = GameDesign.text(size: (s.messageSize * scale).clamp(18, 28));
    final override = messageOverride;
    if (override == null) {
      return Text(s.messageText, style: style, textAlign: TextAlign.center);
    }
    return ValueListenableBuilder<String>(
      valueListenable: override,
      builder: (context, text, child) => Text(
        text.isEmpty ? s.messageText : text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 以設計座標的中心點定位。
  ///
  /// 背景是 cover，所以版面中心跟著畫面中心走，而不是跟著左上角 —— 用
  /// FractionalTranslation 從畫面中心往外推，才不會在超寬螢幕上整組偏到一邊。
  Widget _centered({
    required double x,
    required double y,
    required double scale,
    required BoxConstraints constraints,
    required Widget child,
  }) {
    final dx = (x - 1920 / 2) * scale;
    final dy = (y - 1080 / 2) * scale;
    return Center(
      child: Transform.translate(offset: Offset(dx, dy), child: child),
    );
  }
}

/// 背景：主素材 → fallback 素材 → 純色。
class _Background extends StatelessWidget {
  const _Background({required this.spec});

  final LoadingUiSpec spec;

  @override
  Widget build(BuildContext context) => _image(spec.backgroundAsset);

  Widget _image(String asset) => Image.asset(
    asset,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) =>
        asset == spec.backgroundAsset && asset != spec.fallbackBackgroundAsset
        ? _image(spec.fallbackBackgroundAsset)
        : ColoredBox(color: spec.backgroundColor),
  );
}
