// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

// Primary color: #433DCB
const _r = 0x43, _g = 0x3D, _b = 0xCB;

void _setPixel(img.Image image, int x, int y, img.Color color) {
  if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
    image.setPixel(x, y, color);
  }
}

/// Filled anti-aliased circle
void _circle(img.Image image, int cx, int cy, int r, img.Color color) {
  for (var y = cy - r; y <= cy + r; y++) {
    for (var x = cx - r; x <= cx + r; x++) {
      final dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r * r) {
        _setPixel(image, x, y, color);
      }
    }
  }
}

/// Ring (outer radius [or_], inner radius [ir])
void _ring(img.Image image, int cx, int cy, int outerR, int innerR, img.Color color) {
  for (var y = cy - outerR; y <= cy + outerR; y++) {
    for (var x = cx - outerR; x <= cx + outerR; x++) {
      final dx = x - cx, dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 <= outerR * outerR && d2 >= innerR * innerR) {
        _setPixel(image, x, y, color);
      }
    }
  }
}

/// Rounded rectangle
void _roundedRect(
    img.Image image, int x0, int y0, int x1, int y1, int r, img.Color color) {
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final cx = x.clamp(x0 + r, x1 - r);
      final cy = y.clamp(y0 + r, y1 - r);
      final dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r * r) {
        _setPixel(image, x, y, color);
      }
    }
  }
}

/// Leaf shape = intersection of two circles
void _leaf(img.Image image, int cx, int cy, int leafR, int offset,
    img.Color color) {
  final cy1 = cy - offset;
  final cy2 = cy + offset;
  for (var y = cy - leafR - offset; y <= cy + leafR + offset; y++) {
    for (var x = cx - leafR; x <= cx + leafR; x++) {
      final dx1 = x - cx, dy1 = y - cy1;
      final dx2 = x - cx, dy2 = y - cy2;
      final in1 = dx1 * dx1 + dy1 * dy1 <= leafR * leafR;
      final in2 = dx2 * dx2 + dy2 * dy2 <= leafR * leafR;
      if (in1 && in2) _setPixel(image, x, y, color);
    }
  }
}

img.Image _buildIcon(int size, {bool fgOnly = false}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  final cx = size ~/ 2;
  final cy = size ~/ 2;

  final primary = img.ColorRgba8(_r, _g, _b, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final clear = img.ColorRgba8(0, 0, 0, 0);

  // Background
  img.fill(image, color: fgOnly ? clear : primary);

  if (!fgOnly) {
    // Slight inner glow: darker rounded rect vignette
    _roundedRect(image, 0, 0, size - 1, size - 1, size ~/ 5, primary);
  }

  final s = size / 1024.0;

  // Outer zen ring
  _ring(image, cx, cy, (300 * s).round(), (215 * s).round(), white);

  // Center coin dot
  _circle(image, cx, cy, (82 * s).round(), white);

  // Vertical stem (from coin to top of ring, like a sprout)
  final stemW = (22 * s).round();
  final stemTop = cy - (268 * s).round();
  final stemBot = cy - (82 * s).round();
  for (var y = stemTop; y <= stemBot; y++) {
    for (var x = cx - stemW; x <= cx + stemW; x++) {
      _setPixel(image, x, y, white);
    }
  }

  // Two small leaves on the stem
  final leafCy = cy - (185 * s).round();
  _leaf(image, cx - (52 * s).round(), leafCy, (52 * s).round(),
      (30 * s).round(), white);
  _leaf(image, cx + (52 * s).round(), leafCy, (52 * s).round(),
      (30 * s).round(), white);

  return image;
}

void main() {
  // 1. Full icon (for launcher)
  final icon = _buildIcon(1024);
  File('assets/icon/app_icon.png')
      .writeAsBytesSync(img.encodePng(icon));
  print('✓ assets/icon/app_icon.png');

  // 2. Foreground only (for Android adaptive icon)
  final fg = _buildIcon(1024, fgOnly: true);
  File('assets/icon/app_icon_fg.png')
      .writeAsBytesSync(img.encodePng(fg));
  print('✓ assets/icon/app_icon_fg.png');

  // 3. Splash image: white design on transparent (shown on light splash bg)
  final splashSize = 512;
  final splash = img.Image(width: splashSize, height: splashSize, numChannels: 4);
  img.fill(splash, color: img.ColorRgba8(0, 0, 0, 0));
  final primary = img.ColorRgba8(_r, _g, _b, 255);
  final scx = splashSize ~/ 2;
  final scy = splashSize ~/ 2;
  final s = splashSize / 1024.0;

  _ring(splash, scx, scy, (300 * s).round(), (215 * s).round(), primary);
  _circle(splash, scx, scy, (82 * s).round(), primary);
  final stemW = (22 * s).round();
  final stemTop = scy - (268 * s).round();
  final stemBot = scy - (82 * s).round();
  for (var y = stemTop; y <= stemBot; y++) {
    for (var x = scx - stemW; x <= scx + stemW; x++) {
      _setPixel(splash, x, y, primary);
    }
  }
  final leafCy = scy - (185 * s).round();
  _leaf(splash, scx - (52 * s).round(), leafCy, (52 * s).round(),
      (30 * s).round(), primary);
  _leaf(splash, scx + (52 * s).round(), leafCy, (52 * s).round(),
      (30 * s).round(), primary);

  File('assets/icon/app_splash.png')
      .writeAsBytesSync(img.encodePng(splash));
  print('✓ assets/icon/app_splash.png');
  print('\nDone! Run: flutter pub run flutter_launcher_icons');
  print('Then:     dart run flutter_native_splash:create');
}
