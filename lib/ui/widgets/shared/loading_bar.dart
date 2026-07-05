import 'package:flutter/material.dart';

/// 載入進度條（含滑動指示器）。
class LoadingBar extends StatelessWidget {
  final double progress;
  final double width;

  const LoadingBar({required this.progress, this.width = 600, super.key});

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    const thumbSize = 40.0;
    const barHeight = 20.0;
    final top = (56 - barHeight) / 2;
    final left = ((width - thumbSize) * clamped).clamp(0.0, width - thumbSize);

    return SizedBox(
      width: width,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF4E2E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E150D), width: 3),
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              '${(clamped * 100).toInt()}%'.padLeft(3),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: left,
            top: (56 - thumbSize) / 2,
            child: _LoadingThumb(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _LoadingThumb extends StatelessWidget {
  const _LoadingThumb({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E150D), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Icon(
          progress < 0.98 ? Icons.person : Icons.check,
          color: progress < 0.98 ? Colors.redAccent : Colors.green,
          size: 18,
        ),
      ),
    );
  }
}
