import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as im;

bool inside(double x, double y, List<List<int>> polygon) {
  var yes = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i], b = polygon[j];
    if ((a[1] > y) != (b[1] > y) &&
        x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]) {
      yes = !yes;
    }
  }
  return yes;
}

void main() {
  final old = im.decodePng(
    File('docs/alpha/before/char_female.png').readAsBytesSync(),
  )!;
  final reference = im.copyResize(
    im.decodePng(
      File('docs/alpha/hair_reconstruction_reference.png').readAsBytesSync(),
    )!,
    width: old.width,
    height: old.height,
    interpolation: im.Interpolation.cubic,
  );
  final fixed = im.Image.from(old),
      mask = im.Image(width: old.width, height: old.height, numChannels: 1);
  // Reviewed interior hair regions only; neither face nor exterior silhouette.
  final polygons = <List<List<int>>>[
    [
      [349, 115],
      [364, 107],
      [386, 108],
      [404, 121],
      [410, 146],
      [398, 162],
      [382, 142],
      [366, 133],
      [348, 142],
    ],
    [
      [371, 76],
      [382, 71],
      [394, 78],
      [400, 94],
      [389, 101],
      [371, 92],
    ],
    [
      [341, 134],
      [346, 123],
      [349, 139],
      [343, 158],
      [346, 179],
      [340, 170],
      [337, 155],
    ],
    [
      [399, 178],
      [411, 187],
      [429, 213],
      [445, 235],
      [447, 310],
      [427, 345],
      [413, 311],
      [414, 263],
      [401, 211],
    ],
    [
      [347, 183],
      [352, 197],
      [348, 220],
      [332, 233],
      [338, 211],
    ],
  ];
  var changed = 0;
  for (final p in old) {
    if (!polygons.any((poly) => inside(p.x + .5, p.y + .5, poly))) continue;
    final r = reference.getPixel(p.x, p.y);
    // Reject reference checkerboard/skin; only borrow dark reconstructed hair.
    if (r.r > 100 || r.g > 100 || r.b > 100 || p.a == 255) continue;
    final a = p.a / 255;
    fixed.setPixelRgba(
      p.x,
      p.y,
      (p.r * a + r.r * (1 - a)).round(),
      (p.g * a + r.g * (1 - a)).round(),
      (p.b * a + r.b * (1 - a)).round(),
      255,
    );
    mask.setPixelR(p.x, p.y, 255);
    changed++;
  }
  File(
    'assets/ui/char_create/char_female.png',
  ).writeAsBytesSync(im.encodePng(fixed));
  File(
    'docs/alpha/female_repair_mask.png',
  ).writeAsBytesSync(im.encodePng(mask));
  final male = im.decodePng(
        File('docs/alpha/before/char_male.png').readAsBytesSync(),
      )!,
      maleFixed = im.Image.from(
        im.decodePng(
          File('docs/alpha/before/char_male.png').readAsBytesSync(),
        )!,
      );
  final maleMask = im.Image(
    width: male.width,
    height: male.height,
    numChannels: 1,
  );
  var maleChanged = 0;
  for (var y = 3; y < male.height - 3; y++) {
    for (var x = 3; x < male.width - 3; x++) {
      final p = male.getPixel(x, y);
      if (p.a < 240 || p.a == 255) continue;
      var interior = true;
      for (var dy = -3; dy <= 3 && interior; dy++) {
        for (var dx = -3; dx <= 3; dx++) {
          if (male.getPixel(x + dx, y + dy).a < 240) {
            interior = false;
            break;
          }
        }
      }
      if (!interior) continue;
      maleFixed.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      maleMask.setPixelR(x, y, 255);
      maleChanged++;
    }
  }
  File(
    'assets/ui/char_create/char_male.png',
  ).writeAsBytesSync(im.encodePng(maleFixed));
  File(
    'docs/alpha/male_repair_mask.png',
  ).writeAsBytesSync(im.encodePng(maleMask));
  File('docs/alpha/repair_summary.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'femaleChangedPixels': changed,
      'maleChangedPixels': maleChanged,
      'femaleHairPolygons': polygons,
      'femalePolicy':
          'Only damaged alpha in reviewed hair interiors; candidate dark RGB only; preserve all other pixels.',
      'malePolicy':
          'Only alpha, 7x7 neighborhood alpha>=240; RGB and edge coverage unchanged.',
    }),
  );
  stdout.writeln(
    'Female repaired $changed pixels; male interior alpha repaired $maleChanged pixels',
  );
}
