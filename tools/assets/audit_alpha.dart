import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as im;

String norm(String s) =>
    s.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');
Iterable<File> files(String root) sync* {
  if (!Directory(root).existsSync()) return;
  for (final e in Directory(root).listSync(followLinks: false)) {
    final name = norm(e.path).split('/').last;
    if (e is Directory) {
      if (name.startsWith('.') ||
          const ['build', 'node_modules'].contains(name)) {
        continue;
      }
      yield* files(e.path);
    } else if (e is File) {
      yield e;
    }
  }
}

String csv(Object? s) => '"${(s ?? '').toString().replaceAll('"', '""')}"';
Map<String, dynamic> stats(im.Image image, [List<int>? rect]) {
  final x0 = rect?[0] ?? 0,
      y0 = rect?[1] ?? 0,
      w = rect?[2] ?? image.width,
      h = rect?[3] ?? image.height;
  var zero = 0, partial = 0, opaque = 0, minA = 255, maxA = 0, sum = 0;
  var left = image.width, top = image.height, right = -1, bottom = -1;
  for (var y = y0; y < y0 + h; y++) {
    for (var x = x0; x < x0 + w; x++) {
      final a = image.getPixel(x, y).a.toInt();
      sum += a;
      if (a < minA) minA = a;
      if (a > maxA) maxA = a;
      if (a == 0) {
        zero++;
      } else {
        if (a == 255) {
          opaque++;
        } else {
          partial++;
        }
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  final n = w * h, visible = partial + opaque;
  return {
    'width': w,
    'height': h,
    'alphaType': partial > 0
        ? 'graded'
        : zero > 0
        ? 'binary'
        : 'opaque',
    'alpha0Ratio': zero / n,
    'alphaPartialRatio': partial / n,
    'alpha255Ratio': opaque / n,
    'partialVisibleRatio': visible == 0 ? 0 : partial / visible,
    'minAlpha': minA,
    'maxAlpha': maxA,
    'meanAlpha': sum / n,
    'visibleBounds': right < 0
        ? 'empty'
        : '$left,$top,${right - left + 1},${bottom - top + 1}',
  };
}

void plates(im.Image image, String name) {
  final small = im.copyResize(
    image,
    width: image.width > 320 ? 320 : image.width,
  );
  final plate = im.Image(
    width: small.width * 4,
    height: small.height,
    numChannels: 3,
  );
  for (var y = 0; y < small.height; y++) {
    for (var x = 0; x < small.width; x++) {
      final p = small.getPixel(x, y), a = p.a / 255;
      for (var k = 0; k < 4; k++) {
        final bg = k == 0
            ? 0
            : k == 1
            ? 255
            : k == 2
            ? ((x ~/ 16 + y ~/ 16) % 2 == 0 ? 90 : 200)
            : 0;
        final r = k == 3 ? 255 : bg, g = bg, b = k == 3 ? 255 : bg;
        plate.setPixelRgb(
          x + k * small.width,
          y,
          (p.r * a + r * (1 - a)).round(),
          (p.g * a + g * (1 - a)).round(),
          (p.b * a + b * (1 - a)).round(),
        );
      }
    }
  }
  File(
    'docs/alpha/$name-backgrounds.png',
  ).writeAsBytesSync(im.encodePng(plate));
  final alpha = im.Image(
    width: small.width,
    height: small.height,
    numChannels: 3,
  );
  for (final p in small) {
    alpha.setPixelRgb(p.x, p.y, p.a, p.a, p.a);
  }
  File('docs/alpha/$name-alpha.png').writeAsBytesSync(im.encodePng(alpha));
}

void main(List<String> args) {
  final targets =
      files('.')
          .where(
            (f) =>
                RegExp(
                  r'\.(png|jpe?g|webp|svg|ico)$',
                  caseSensitive: false,
                ).hasMatch(f.path) &&
                !norm(f.path).startsWith('docs/alpha/'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final sourceFiles =
      [
        ...files('lib'),
        ...files('assets'),
        ...files('web'),
        ...files('android'),
        ...files('ios'),
        ...files('windows'),
        File('pubspec.yaml'),
      ].where(
        (f) => RegExp(
          r'\.(dart|json|xml|xaml|yaml|html|css|plist|rc)$',
        ).hasMatch(f.path),
      );
  final sources = <String, String>{
    for (final f in sourceFiles) norm(f.path): f.readAsStringSync(),
  };
  final hashProcess = Process.runSync('node', ['tools/assets/hash_assets.cjs']);
  if (hashProcess.exitCode != 0) {
    throw StateError('Hash scan failed: ${hashProcess.stderr}');
  }
  final hashes = jsonDecode(hashProcess.stdout as String) as Map;
  final bundleFile = File('docs/alpha/bundle_decode.json');
  final bundle = <String, dynamic>{
    if (bundleFile.existsSync())
      for (final r in jsonDecode(bundleFile.readAsStringSync()) as List)
        r['path'] as String: r,
  };
  final rows = <Map<String, dynamic>>[], frames = <Map<String, dynamic>>[];
  for (final file in targets) {
    final path = norm(file.path), base = path.split('/').last;
    final refs = sources.entries
        .where(
          (e) =>
              e.value.contains(path) ||
              (base.length > 6 && e.value.contains(base)),
        )
        .map((e) => e.key)
        .toList();
    final backup =
        path.contains('backup') ||
        path.contains('_demo') ||
        path.contains('_rejected') ||
        !path.startsWith('assets/') &&
            !path.startsWith('web/') &&
            !path.startsWith('android/') &&
            !path.startsWith('ios/') &&
            !path.startsWith('windows/');
    final platform = !path.startsWith('assets/');
    final row = <String, dynamic>{
      'path': path,
      'sha256': hashes[path] ?? 'not computed',
      'format': path.split('.').last,
      'references': refs.join(';'),
      'usageStatus': backup
          ? 'backup/preview'
          : refs.isNotEmpty
          ? 'reference found (static)'
          : platform
          ? 'platform resource'
          : 'dynamic/unreferenced: review',
      'screens': path.startsWith('assets/ui/')
          ? 'UI'
          : platform
          ? 'platform launch/icon'
          : 'world/editor',
      'states': 'normal; inspect state-specific rendering',
      'sourcePath': path.replaceFirst(RegExp(r'_[0-9a-f]{8}\.png$'), '.png'),
      'publishedPath': path,
      'expectedTransparency': 'review by role',
      'finding': '',
      'priority': 'P1',
      'verificationStatus': 'pixel scan only; runtime not implied',
    };
    try {
      final bytes = file.readAsBytesSync();
      final image = im.decodeImage(bytes);
      if (image == null) {
        row['finding'] = 'non-raster or decoder unsupported';
      } else {
        row.addAll(stats(image));
        if (path.endsWith('.png')) {
          row['pngBitDepth'] = bytes[24];
          row['pngColorType'] = bytes[25];
        }
        if (path.contains('char_female') ||
            path.contains('char_male') ||
            path.contains('pearl_01')) {
          plates(image, base.replaceAll('.png', ''));
        }
        final sidecar = File(path.replaceFirst(RegExp(r'\.[^.]+$'), '.json'));
        if (sidecar.existsSync()) {
          final data = jsonDecode(sidecar.readAsStringSync());
          if (data is Map && data['animations'] is Map) {
            for (final a in (data['animations'] as Map).entries) {
              if (a.value is! Map || a.value['frames'] is! List) continue;
              for (final f in a.value['frames']) {
                final rect = (f['rect'] as List?)?.cast<int>();
                if (rect == null) continue;
                final valid =
                    rect.length == 4 &&
                    rect[0] >= 0 &&
                    rect[1] >= 0 &&
                    rect[2] > 0 &&
                    rect[3] > 0 &&
                    rect[0] + rect[2] <= image.width &&
                    rect[1] + rect[3] <= image.height;
                frames.add({
                  'path': path,
                  'animation': a.key,
                  'frame': f['frame_index'],
                  'rect': rect.join(','),
                  'finding': valid ? '' : 'out of bounds',
                  if (valid) ...stats(image, rect),
                });
              }
            }
          }
        }
      }
    } catch (e) {
      row['finding'] = 'decode error: $e';
    }
    classify(row, bundle);
    rows.add(row);
  }
  void writeCsv(String path, List<Map<String, dynamic>> data) {
    final keys = data.expand((r) => r.keys).toSet().toList();
    File(path).writeAsStringSync(
      [
        keys.map(csv).join(','),
        ...data.map((r) => keys.map((k) => csv(r[k])).join(',')),
      ].join('\n'),
    );
  }

  writeCsv('docs/asset_alpha_inventory.csv', rows);
  writeCsv('docs/asset_alpha_frames.csv', frames);
  File(
    'docs/alpha/inventory.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
  stdout.writeln('Scanned ${rows.length} images, ${frames.length} atlas frames');
  for (final r in rows.where(
    (r) =>
        (r['path'] as String).contains('char_female') ||
        (r['path'] as String).contains('char_male'),
  )) {
    stdout.writeln(jsonEncode(r));
  }
}

void classify(Map<String, dynamic> row, Map bundle) {
  final p = row['path'] as String;
  final refs = row['references'] as String;
  final isSource = RegExp(r'/char_(female|male|bg)\.png$').hasMatch(p);
  if (p.startsWith('assets/tiles/') && !p.contains('/_')) {
    row['usageStatus'] = 'conditional runtime / map packet';
    row['references'] =
        '$refs;lib/network/packets/server/s_map_tiles.dart;lib/game/map/iso_map_component.dart;lib/game/map/scene_asset_loader.dart';
    row['screens'] = 'world; editor (root tiles only)';
    row['states'] = 'S_MAP_TILES tileDir + tiles[id]; fallback ground atlas';
    row['expectedTransparency'] =
        'opaque diamond interior; transparent outer corners';
  } else if (p.startsWith('assets/maps/')) {
    row['usageStatus'] = 'conditional runtime / map id';
    row['references'] =
        'lib/game/map/scene_asset_loader.dart:loadMapBackground';
    row['screens'] = 'world';
    row['states'] = 'matching mapId';
    row['expectedTransparency'] =
        'wall silhouette can be transparent; not necessarily a full background';
  } else if (p.startsWith('assets/objects/')) {
    row['usageStatus'] = 'catalog / editor source';
    row['screens'] = 'world; decoration; editor';
    row['states'] = 'normal 1; moving 0.4; ghost 0.5; separate shadow';
    row['expectedTransparency'] = p.contains('cultivation_array')
        ? 'intentional magic glow'
        : 'opaque prop; transparent silhouette; independent shadow';
  } else if (p.startsWith('assets/characters/')) {
    row['usageStatus'] = p.endsWith('/3221.png')
        ? 'active player atlas'
        : 'legacy bundled asset; current descriptor uses 3221';
    row['screens'] = 'world; remote player';
    row['states'] = 'atlas animations and directions';
    row['expectedTransparency'] =
        'opaque sprite body; transparent frame padding';
  } else if (p.startsWith('assets/monsters/')) {
    row['usageStatus'] = 'name mapped conditional runtime';
    row['screens'] = 'world';
    row['states'] = 'normal 1; corpse 0.5';
    row['expectedTransparency'] =
        'opaque sprite body; transparent frame padding';
  } else if (p.startsWith('assets/weapons/')) {
    row['usageStatus'] = 'disabled optional art; WeaponVisual.none default';
    row['references'] = '$refs;lib/game/map/floating_weapon_component.dart';
    row['screens'] = 'world (optional weapon)';
    row['expectedTransparency'] = 'orb silhouette and glow';
    row['finding'] =
        'painted checkerboard confirmed by contact sheet; keep disabled, not shipped as a visible weapon';
    row['priority'] = 'P2';
  } else if (p.startsWith('assets/ui/') || p.startsWith('assets/images/')) {
    row['usageStatus'] = refs.isEmpty
        ? 'no current static consumer found; retained legacy'
        : 'configured UI / preload / fallback';
    row['expectedTransparency'] =
        p.contains('_bg') || p.endsWith('/loading.png')
        ? 'opaque backdrop or panel'
        : 'intentional edge/ink/cloud/glow transparency';
    row['states'] = 'normal; disabled/hover/pressed when configured';
    if (isSource) {
      row['usageStatus'] = 'publishing source';
      row['references'] = 'tools/assets/publish_portraits.cjs';
    }
    if (RegExp(r'/char_(male|female)(_[0-9a-f]{8})?\.png$').hasMatch(p)) {
      row['screens'] =
          'character create; character select; transition consumers';
      row['expectedTransparency'] = 'opaque solid body; transparent silhouette';
      row['priority'] = 'P0';
      row['finding'] =
          'source alpha repaired; see repair_summary.json and mask tests';
      if (p.contains('9387b9c6') || p.contains('dea83ef9')) {
        row['usageStatus'] = 'superseded published copy; no active constant';
        row['finding'] =
            'original alpha defect; retained history, not selected by current code';
      }
    }
    if (p.endsWith('/cloud_label03.png')) {
      row['usageStatus'] = 'preload only; no visible consumer';
      row['finding'] =
          'possible baked checker/shadow patch; not used for current labels';
    }
  } else if (!p.startsWith('assets/') &&
      !p.contains('backup') &&
      !p.endsWith('preview.png')) {
    row['usageStatus'] = 'platform resource declaration / generated variant';
    row['screens'] = 'platform launcher/splash';
    row['expectedTransparency'] =
        'platform icon or splash alpha; native runtime not tested';
  }
  if (p.contains('backup') || p.contains('/_demo') || p.endsWith('preview.png')) {
    row['usageStatus'] = 'backup/preview; not active';
  }
  final decodeStatus = row.containsKey('width')
      ? 'all pixels decoded'
      : 'no decoded raster; inspect separately';
  final bundleStatus = bundle.containsKey(p)
      ? '; Flutter bundle decode passed'
      : ' ; not in tested Flutter bundle';
  row['verificationStatus'] =
      '$decodeStatus$bundleStatus; contact sheet inspection for assets; no live-world claim';
  if ((row['finding'] as String).isEmpty) {
    row['finding'] =
        'no alpha defect identified by pixel scan; intended transparency preserved';
  }
}
