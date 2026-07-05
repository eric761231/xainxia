import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'loading_bar.dart';

/// 載入 / 過場 overlay 共用骨架：透明 Material → 全螢幕背景 →
/// 底部（訊息 + 進度條）。呼叫端自訂 [background] 與 [message]。
class ProgressOverlayScaffold extends StatelessWidget {
  const ProgressOverlayScaffold({
    super.key,
    required this.background,
    required this.message,
    required this.progress,
  });

  /// 全螢幕背景（含各自的圖片與 fallback 邏輯）。
  final Widget background;

  /// 進度條上方訊息（靜態文字或 ValueListenableBuilder）。
  final Widget message;

  /// 進度 0.0–1.0。
  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: background),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 0
                      ? constraints.maxWidth * 0.6
                      : 360.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      message,
                      const SizedBox(height: 12),
                      ValueListenableBuilder<double>(
                        valueListenable: progress,
                        builder: (context, value, child) {
                          return LoadingBar(progress: value, width: width);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
