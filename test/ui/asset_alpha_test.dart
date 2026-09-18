import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as im;
import 'package:xianxia_game/ui/layout/char_create/char_create_ui_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all packaged project PNGs decode through Flutter', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths =
        manifest
            .listAssets()
            .where((p) => p.startsWith('assets/') && p.endsWith('.png'))
            .toList()
          ..sort();
    final records = <Map<String, dynamic>>[];
    for (final path in paths) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      records.add({
        'path': path,
        'width': frame.image.width,
        'height': frame.image.height,
        'status': 'Flutter bundle decode passed',
      });
      frame.image.dispose();
      codec.dispose();
    }
    expect(
      paths,
      containsAll([
        CharCreateUiAssets.charFemale,
        CharCreateUiAssets.charMale,
        CharCreateUiAssets.bg,
      ]),
    );
    File(
      'docs/alpha/bundle_decode.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(records));
  });
  test(
    'female repair is confined to reviewed missing hair; solid body remains opaque',
    () {
      final old = im.decodePng(
        File('docs/alpha/before/char_female.png').readAsBytesSync(),
      )!;
      final fixed = im.decodePng(
        File('docs/design/char-create-redesign/before/char_female.png').readAsBytesSync(),
      )!;
      final mask = im.decodePng(
        File('docs/alpha/female_repair_mask.png').readAsBytesSync(),
      )!;
      var outsideChanges = 0, brokenRepair = 0, repairs = 0;
      for (final p in old) {
        final q = fixed.getPixel(p.x, p.y);
        final selected = mask.getPixel(p.x, p.y).r > 0;
        if (selected) {
          repairs++;
          if (q.a != 255) brokenRepair++;
        } else if (p.r != q.r || p.g != q.g || p.b != q.b || p.a != q.a) {
          outsideChanges++;
        }
      }
      expect(repairs, greaterThan(2000));
      expect(outsideChanges, 0);
      expect(brokenRepair, 0);
      for (final point in [
        [365, 150],
        [361, 290],
        [370, 500],
        [400, 600],
      ]) {
        expect(fixed.getPixel(point[0], point[1]).a, 255);
      }
      expect(old.getPixel(350, 123).a, 0);
      expect(fixed.getPixel(350, 123).a, 255);
      expect(fixed.getPixel(0, 0).a, 0);
    },
  );
  test(
    'male interior opacity repair preserves all RGB and silhouette edges',
    () {
      final old = im.decodePng(
        File('docs/alpha/before/char_male.png').readAsBytesSync(),
      )!;
      final fixed = im.decodePng(
        File('docs/design/char-create-redesign/before/char_male.png').readAsBytesSync(),
      )!;
      final mask = im.decodePng(
        File('docs/alpha/male_repair_mask.png').readAsBytesSync(),
      )!;
      var rgbChanges = 0, outsideChanges = 0, bad = 0;
      for (final p in old) {
        final q = fixed.getPixel(p.x, p.y);
        if (p.r != q.r || p.g != q.g || p.b != q.b) rgbChanges++;
        if (mask.getPixel(p.x, p.y).r == 0) {
          if (p.a != q.a) outsideChanges++;
        } else if (q.a != 255) {
          bad++;
        }
      }
      expect(rgbChanges, 0);
      expect(outsideChanges, 0);
      expect(bad, 0);
    },
  );
}
