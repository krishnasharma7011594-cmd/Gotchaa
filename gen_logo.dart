import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void makeLogo(int size, String filename, bool transparentBg) {
  final image = img.Image(width: size, height: size);
  // Fill all with transparent
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final int r = (size * 0.2).toInt();
  const int color1R = 175, color1G = 114, color1B = 219;
  const int color2R = 39, color2G = 196, color2B = 178;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final int dx = x < r ? x : x > size - 1 - r ? size - 1 - x : r;
      final int dy = y < r ? y : y > size - 1 - r ? size - 1 - y : r;

      final double factor = (x + y) / (2.0 * size);
      final int cr = (color1R * (1 - factor) + color2R * factor).toInt();
      final int cg = (color1G * (1 - factor) + color2G * factor).toInt();
      final int cb = (color1B * (1 - factor) + color2B * factor).toInt();

      int alpha = 255;
      if (dx < r && dy < r) {
        final double dist = sqrt(pow(r - dx, 2) + pow(r - dy, 2));
        if (dist > r) {
          alpha = 0;
        } else if (dist > r - 1) {
          alpha = (255 * (r - dist)).toInt();
        }
      }

      if (transparentBg) {
          // keep alpha as transparent where round corners apply
      }

      if (alpha > 0) {
        image.setPixel(x, y, img.ColorRgba8(cr, cg, cb, alpha));
      }
    }
  }

  // Draw a 'G' in the middle. Since we don't have TTF parsing easily available,
  // we can use a very simple built-in string or draw it manually using pixels.
  // We'll draw a white circle and cut out the center and a quadrant.
  final int gRadius = (size * 0.25).toInt();
  final int cx = size ~/ 2;
  final int cy = size ~/ 2;
  final int thickness = (size * 0.1).toInt();

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final double d = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      // Outer and inner circle of G
      if (d >= gRadius - thickness && d <= gRadius) {
        // Cut out top right quadrant partly
        if (x > cx && y < cy - thickness ~/ 2) {
            continue;
        }
        image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
      }
      
      // Horizontal bar of G
      if (y >= cy - thickness ~/ 2 && y <= cy + thickness ~/ 2) {
          if (x >= cx && x <= cx + gRadius) {
              image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
          }
      }
      
      // Vertical drop of G
      if (x >= cx + gRadius - thickness && x <= cx + gRadius) {
          if (y >= cy && y <= cy + gRadius) {
              image.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
          }
      }
    }
  }

  File(filename).writeAsBytesSync(img.encodePng(image));
  print('Saved $filename');
}

void main() {
  Directory('assets/logo').createSync(recursive: true);
  makeLogo(1024, 'assets/logo/gotchaa_icon.png', true);
  makeLogo(512, 'assets/logo/gotchaa_splash.png', true);
}
