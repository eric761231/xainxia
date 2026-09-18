import 'package:flutter/material.dart';

import '../ui_xaml_assets.dart';
import '../ui_xaml_loader.dart';
import '../ui_xaml_registry.dart';
import '../ui_xaml_spec_holder.dart';

/// Loading / 過場畫面的顯示規格（設計稿像素）。
///
/// 每個欄位都有 Dart 預設值：`loading.xaml` 缺檔、壞掉或少寫某個屬性時，畫面
/// 仍然是現在這個樣子，只是失去外部可調性。這是刻意的 —— 一個打錯的設定檔不該
/// 讓玩家看到黑屏。
@immutable
class LoadingUiSpec {
  const LoadingUiSpec({
    this.backgroundAsset = 'assets/images/loading.png',
    this.fallbackBackgroundAsset = 'assets/images/launch_bg.png',
    this.backgroundColor = const Color(0xFF140E0C),
    this.messageText = '載入中',
    this.messageCenterX = 960,
    this.messageCenterY = 898,
    this.messageSize = 24,
    this.messageColor = const Color(0xFFF2EADA),
    this.barCenterX = 960,
    this.barCenterY = 960,
    this.barWidth = 880,
    this.barHeight = 32,
    this.barRadius = 6,
    this.trackColor = const Color(0x59000000),
    this.fillColor = const Color(0xFF74D2D5),
    this.glowColor = const Color(0xFF74D2D5),
    this.glowBlur = 14,
    this.glowOpacity = 0.55,
    this.textureAsset,
    this.textureHeight = 32,
    this.texturePixelsPerSecond = 52,
    this.showLabel = true,
    this.labelColor = const Color(0xFFF2EADA),
    this.labelSize = 14,
  });

  final String backgroundAsset;
  final String fallbackBackgroundAsset;
  final Color backgroundColor;

  final String messageText;
  final double messageCenterX;
  final double messageCenterY;
  final double messageSize;
  final Color messageColor;

  final double barCenterX;
  final double barCenterY;
  final double barWidth;
  final double barHeight;
  final double barRadius;
  final Color trackColor;
  final Color fillColor;
  final Color glowColor;
  final double glowBlur;
  final double glowOpacity;

  /// 填充區內循環的靈氣紋理；null 表示不鋪紋理（純色填充）。
  final String? textureAsset;
  final double textureHeight;

  /// 紋理每秒水平移動的設計像素數。
  final double texturePixelsPerSecond;

  final bool showLabel;
  final Color labelColor;
  final double labelSize;

  static const LoadingUiSpec defaults = LoadingUiSpec();

  static final holder = UiXamlSpecHolder<LoadingUiSpec>(
    view: UiXamlRegistry.loading,
    initial: defaults,
    build: _build,
  );

  static LoadingUiSpec get current => holder.value;

  static LoadingUiSpec _build(UiXamlResult result, UiXamlAssets assets) {
    final document = result.document;
    if (document == null) return defaults;

    final bg = document.root.child('Background');
    final message = document.findById('message');
    final bar = document.findById('progress');
    const d = defaults;

    String resolve(String? id, String fallback) =>
        id == null ? fallback : (assets.path(id, fallbackPath: fallback) ?? fallback);

    return LoadingUiSpec(
      backgroundAsset:
          resolve(bg?.raw('asset'), d.backgroundAsset),
      fallbackBackgroundAsset:
          resolve(bg?.raw('fallbackAsset'), d.fallbackBackgroundAsset),
      backgroundColor: bg?.color('color', d.backgroundColor) ?? d.backgroundColor,
      messageText: message?.s('text', d.messageText) ?? d.messageText,
      messageCenterX:
          message?.d('centerX', d.messageCenterX, min: 0, max: 1920) ??
              d.messageCenterX,
      messageCenterY:
          message?.d('centerY', d.messageCenterY, min: 0, max: 1080) ??
              d.messageCenterY,
      messageSize:
          message?.d('size', d.messageSize, min: 8, max: 96) ?? d.messageSize,
      messageColor: message?.color('color', d.messageColor) ?? d.messageColor,
      barCenterX:
          bar?.d('centerX', d.barCenterX, min: 0, max: 1920) ?? d.barCenterX,
      barCenterY:
          bar?.d('centerY', d.barCenterY, min: 0, max: 1080) ?? d.barCenterY,
      barWidth: bar?.d('width', d.barWidth, min: 120, max: 1920) ?? d.barWidth,
      // 30–36 是接手計畫定的範圍：再矮紋理看不出來，再高就不像進度條了。
      barHeight: bar?.d('height', d.barHeight, min: 30, max: 36) ?? d.barHeight,
      barRadius: bar?.d('radius', d.barRadius, min: 0, max: 18) ?? d.barRadius,
      trackColor: bar?.color('trackColor', d.trackColor) ?? d.trackColor,
      fillColor: bar?.color('fillColor', d.fillColor) ?? d.fillColor,
      glowColor: bar?.color('glowColor', d.glowColor) ?? d.glowColor,
      glowBlur: bar?.d('glowBlur', d.glowBlur, min: 0, max: 48) ?? d.glowBlur,
      glowOpacity:
          bar?.d('glowOpacity', d.glowOpacity, min: 0, max: 1) ?? d.glowOpacity,
      textureAsset: bar?.raw('textureAsset') == null
          ? d.textureAsset
          : assets.path(bar!.raw('textureAsset')!),
      textureHeight:
          bar?.d('textureHeight', d.textureHeight, min: 4, max: 256) ??
              d.textureHeight,
      texturePixelsPerSecond: bar?.d(
              'texturePixelsPerSecond', d.texturePixelsPerSecond,
              min: 0, max: 600) ??
          d.texturePixelsPerSecond,
      showLabel: bar?.b('showLabel', d.showLabel) ?? d.showLabel,
      labelColor: bar?.color('labelColor', d.labelColor) ?? d.labelColor,
      labelSize:
          bar?.d('labelSize', d.labelSize, min: 6, max: 48) ?? d.labelSize,
    );
  }

  /// 供測試直接由節點樹建 spec，不經檔案系統。
  @visibleForTesting
  static LoadingUiSpec fromResultForTest(
          UiXamlResult result, UiXamlAssets assets) =>
      _build(result, assets);
}
