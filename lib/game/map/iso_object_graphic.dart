import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// 物件圖形抽象：可為點陣（PNG/JPG → [ui.Image]）或 SVG 向量（[ui.Picture]）。
///
/// 兩者都提供 intrinsic 尺寸與統一的 [paint]（把圖形等比拉伸畫進目標矩形），
/// 讓遊戲渲染與編輯器預覽共用同一條路徑；SVG 走**向量繪製**（縮放不失真）。
abstract class ObjectGraphic {
  /// 原始（intrinsic）寬高（px / viewBox 單位）。
  double get width;
  double get height;

  /// 把圖形等比拉伸畫進 [dst]；[opacity] < 1 時整體半透明（ghost 預覽用）。
  void paint(Canvas canvas, Rect dst, {double opacity = 1.0});

  static final Map<String, ObjectGraphic?> _cache = {};

  /// 清空載入快取（編輯器「重載素材」用；下次載入會重讀）。
  static void clearCache() => _cache.clear();

  /// 依副檔名載入：`.svg` → 向量 [ui.Picture]；其餘 → [ui.Image]。失敗回 null，皆快取。
  static Future<ObjectGraphic?> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    ObjectGraphic? g;
    try {
      if (assetPath.toLowerCase().endsWith('.svg')) {
        final info = await vg.loadPicture(SvgAssetLoader(assetPath), null);
        g = _SvgGraphic(info.picture, info.size.width, info.size.height);
      } else {
        final data = await rootBundle.load(assetPath);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        g = _RasterGraphic((await codec.getNextFrame()).image);
      }
    } catch (e) {
      debugPrint('ObjectGraphic: 載入失敗 $assetPath（$e）');
      g = null;
    }
    return _cache[assetPath] = g;
  }

  /// 依物件定義的來源資料夾＋檔名載入（`assets/<dir>/<image>`）。
  static Future<ObjectGraphic?> loadForDir(String dir, String image) =>
      image.isEmpty ? Future.value(null) : load('assets/$dir/$image');

  /// 直接從**檔案系統**載入（桌面編輯器用；不經 asset 快照，新增/改檔即時反映）。
  /// 不快取——每次重讀磁碟現況。失敗回 null。
  static Future<ObjectGraphic?> loadFile(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null; // 缺檔靜默略過（不洗版報錯）
      if (path.toLowerCase().endsWith('.svg')) {
        final svg = await file.readAsString();
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        return _SvgGraphic(info.picture, info.size.width, info.size.height);
      }
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      return _RasterGraphic((await codec.getNextFrame()).image);
    } catch (e) {
      debugPrint('ObjectGraphic: 檔案系統載入失敗 $path（$e）');
      return null;
    }
  }
}

class _RasterGraphic extends ObjectGraphic {
  _RasterGraphic(this.image);

  final ui.Image image;

  @override
  double get width => image.width.toDouble();
  @override
  double get height => image.height.toDouble();

  @override
  void paint(Canvas canvas, Rect dst, {double opacity = 1.0}) {
    final src = Rect.fromLTWH(0, 0, width, height);
    final paint = Paint();
    if (opacity < 1.0) paint.color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(image, src, dst, paint);
  }
}

class _SvgGraphic extends ObjectGraphic {
  _SvgGraphic(this.picture, this._w, this._h);

  final ui.Picture picture;
  final double _w;
  final double _h;

  @override
  double get width => _w;
  @override
  double get height => _h;

  @override
  void paint(Canvas canvas, Rect dst, {double opacity = 1.0}) {
    if (_w <= 0 || _h <= 0) return;
    if (opacity < 1.0) {
      canvas.saveLayer(dst, Paint()..color = Color.fromRGBO(255, 255, 255, opacity));
    } else {
      canvas.save();
    }
    canvas.translate(dst.left, dst.top);
    canvas.scale(dst.width / _w, dst.height / _h);
    canvas.drawPicture(picture);
    canvas.restore();
  }
}
