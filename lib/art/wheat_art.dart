import 'dart:math';

import 'package:flutter/painting.dart';

import 'icons.dart';
import 'palette.dart';

/// Wheat in its three growth stages. [base] is where the plant meets the
/// soil and [u] is one "unit" (1/100 of the plot width).

void _stem(Canvas c, Offset from, Offset to, Offset control, double u, Color color) {
  final p = Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  c.drawPath(p, stroke..strokeWidth = u * 3.2..color = Palette.outline);
  c.drawPath(p, stroke..strokeWidth = u * 1.7..color = color);
}

void _leafAt(Canvas c, Offset center, double angle, double w, double h, double u,
    {Color color = Palette.leaf}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  shape(
    c,
    Path()..addOval(Rect.fromCenter(center: Offset.zero, width: w, height: h)),
    color: color,
    ow: u * 1.3,
  );
  c.restore();
}

/// Stage 1: a tiny two-leaf sprout.
void drawSprout(Canvas c, Offset base, double u, double grow) {
  final g = 0.6 + 0.4 * grow;
  final top = base + Offset(0, -8 * u * g);
  _stem(c, base, top, base + Offset(u, -4 * u * g), u, Palette.leaf);
  _leafAt(c, top + Offset(-3 * u, 0), -0.9, 3.4 * u * g, 6 * u * g, u, color: Palette.leafLight);
  _leafAt(c, top + Offset(3 * u, -u), 0.9, 3.4 * u * g, 6 * u * g, u, color: Palette.leafLight);
}

/// Stage 2: green stalks with young (green) ears.
void drawYoungWheat(Canvas c, Offset base, double u, double grow, double sway) {
  final g = 0.65 + 0.35 * grow;
  for (var k = -1; k <= 1; k++) {
    final len = (k == 0 ? 19 : 15) * u * g;
    final a = k * 0.32 + sway;
    final tip = base + Offset(sin(a) * len, -cos(a) * len);
    _stem(c, base, tip, base + Offset(k * u * 1.5, -len * 0.5), u, Palette.leaf);
    wheatEar(c, tip, base,
        s: 0.24 * u, color: Palette.leafLight, outline: Palette.outline, ow: 4.5);
  }
  _leafAt(c, base + Offset(-3.5 * u, -4 * u), -0.8, 3 * u, 8 * u, u);
  _leafAt(c, base + Offset(3.5 * u, -5 * u), 0.8, 3 * u, 8 * u, u);
}

/// Stage 3: tall golden wheat, ready to harvest. [sway] tilts it in the wind.
void drawRipeWheat(Canvas c, Offset base, double u, double sway) {
  for (var k = -1; k <= 1; k++) {
    final len = (k == 0 ? 24 : 20) * u;
    final a = k * 0.3 + sway * (1 + k * 0.15);
    final tip = base + Offset(sin(a) * len, -cos(a) * len);
    final control = base + Offset(sin(a * 0.4) * len * 0.5, -len * 0.55);
    _stem(c, base, tip, control, u, Palette.wheatDark);
    wheatEar(c, tip, base, s: 0.34 * u, color: Palette.wheat, outline: Palette.outline, ow: 4);
  }
  _leafAt(c, base + Offset(-3.5 * u, -4 * u), -0.8, 3 * u, 8 * u, u,
      color: const Color(0xFFB9C255));
  _leafAt(c, base + Offset(3.5 * u, -5 * u), 0.8, 3 * u, 8 * u, u,
      color: const Color(0xFFB9C255));
}
