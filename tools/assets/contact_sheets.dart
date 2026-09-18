import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as im;

void main() {
  final rows =
      (jsonDecode(File('docs/alpha/inventory.json').readAsStringSync()) as List)
          .where(
            (r) =>
                r['path'].startsWith('assets/') &&
                !RegExp(r'_[0-9a-f]{8}\.png$').hasMatch(r['path']),
          )
          .toList();
  for (var page = 0; page * 30 < rows.length; page++) {
    final out = im.Image(width: 1000, height: 900, numChannels: 3);
    im.fill(out, color: im.ColorRgb8(36, 36, 36));
    for (var i = 0; i < 30 && page * 30 + i < rows.length; i++) {
      final p = rows[page * 30 + i]['path'] as String;
      final src = im.decodeImage(File(p).readAsBytesSync());
      if (src == null) continue;
      final scale = (180 / src.width < 140 / src.height
          ? 180 / src.width
          : 140 / src.height);
      final small = im.copyResize(
        src,
        width: (src.width * scale).round().clamp(1, 180),
        height: (src.height * scale).round().clamp(1, 140),
      );
      final ox = (i % 5) * 200, oy = (i ~/ 5) * 150;
      for (var y = 0; y < 140; y++) {
        for (var x = 0; x < 200; x++) {
          final bg = (x ~/ 12 + y ~/ 12) % 2 == 0 ? 80 : 165;
          out.setPixelRgb(ox + x, oy + y, bg, bg, bg);
        }
      }
      im.compositeImage(
        out,
        small,
        dstX: ox + (200 - small.width) ~/ 2,
        dstY: oy,
      );
      final label = '${page * 30 + i} ${p.split('/').last}';
      im.drawString(
        out,
        label.length > 26 ? label.substring(0, 26) : label,
        font: im.arial14,
        x: ox,
        y: oy + 136,
        color: im.ColorRgb8(255, 255, 255),
      );
    }
    File('docs/alpha/contact_$page.png').writeAsBytesSync(im.encodePng(out));
  }
  File('docs/alpha/contact_index.json').writeAsStringSync(
    jsonEncode([
      for (var i = 0; i < rows.length; i++)
        {'index': i, 'path': rows[i]['path']},
    ]),
  );
}
