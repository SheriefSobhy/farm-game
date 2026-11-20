import 'dart:math';

import 'package:flutter/painting.dart';

import 'icons.dart';
import 'palette.dart';

/// Scenery drawn behind the farm plots and in the screen headers.
/// Functions take the bottom-center [base] point and a height [h] in pixels.

void _scaled(Canvas c, Offset base, double h, VoidCallback draw) {
  c.save();
  c.translate(base.dx, base.dy);
  final k = h / 100;
  c.scale(k, k);
  draw();
  c.restore();
}

LinearGradient _vertical(List<Color> colors) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

/// Sky with soft gradient, a sun and drifting clouds. [t] = seconds.
void drawSky(Canvas c, Rect r, {double t = 0}) {
  c.drawRect(
    r,
    Paint()..shader = _vertical(const [Palette.sky, Palette.skyLow]).createShader(r),
  );
  final sun = Offset(r.right - r.height * 0.55, r.top + r.height * 0.42);
  final sr = r.height * 0.2;
  c.drawCircle(
    sun,
    sr * 2.2,
    Paint()
      ..shader = const RadialGradient(colors: [Color(0x66FFF3B0), Color(0x00FFF3B0)])
          .createShader(Rect.fromCircle(center: sun, radius: sr * 2.2)),
  );
  c.drawCircle(sun, sr, Paint()..color = const Color(0xFFFFE27A));
  for (var i = 0; i < 3; i++) {
    final speed = 6.0 + i * 3;
    final span = r.width + 160;
    final x = r.left - 80 + ((i * 0.37 * span + t * speed) % span);
    final y = r.top + r.height * (0.25 + 0.18 * i);
    drawCloud(c, Offset(x, y), r.height * (0.22 - i * 0.03));
  }
}

void drawCloud(Canvas c, Offset center, double s) {
  final p = Paint()..color = const Color(0xF2FFFFFF);
  final shade = Paint()..color = const Color(0x22769BB5);
  for (final o in const [Offset(-1.1, 0.25), Offset(0, 0.25), Offset(1.1, 0.25)]) {
    c.drawCircle(center + o * s + Offset(0, s * 0.12), s * 0.62, shade);
  }
  for (final (o, r) in const [
    (Offset(-1.1, 0.25), 0.6),
    (Offset(-0.4, -0.15), 0.8),
    (Offset(0.5, -0.05), 0.72),
    (Offset(1.15, 0.3), 0.55),
  ]) {
    c.drawCircle(center + o * s, s * r, p);
  }
}

/// Rolling hills from [top] down to the bottom of [r].
void drawHills(Canvas c, Rect r, double top) {
  final back = Path()..moveTo(r.left, top + 10);
  final w = r.width;
  back.cubicTo(r.left + w * 0.2, top - 14, r.left + w * 0.45, top - 6,
      r.left + w * 0.6, top + 4);
  back.cubicTo(r.left + w * 0.75, top + 12, r.left + w * 0.9, top - 12,
      r.right, top - 2);
  back
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.left, r.bottom)
    ..close();
  c.drawPath(back, Paint()..color = Palette.hill);
  final front = Path()..moveTo(r.left, top + 22);
  front.quadraticBezierTo(r.left + w * 0.5, top + 4, r.right, top + 20);
  front
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.left, r.bottom)
    ..close();
  c.drawPath(
    front,
    Paint()
      ..shader = _vertical(const [Palette.grassLight, Palette.grass])
          .createShader(Rect.fromLTRB(r.left, top, r.right, r.bottom)),
  );
}

void drawFarmhouse(Canvas c, Offset base, double h) {
  _scaled(c, base, h, () {
    c.drawOval(const Rect.fromLTWH(-58, -8, 116, 14), Paint()..color = const Color(0x33000000));
    // chimney
    shape(c, rrectPath(20, -94, 14, 30, 3),
        gradient: _vertical(const [Palette.brick, Palette.brickDark]), ow: 5);
    // walls
    shape(c, rrectPath(-46, -58, 92, 58, 4),
        gradient: _vertical(const [Color(0xFFFFF1D9), Color(0xFFF0D7AE)]));
    // roof
    final roof = Path()
      ..moveTo(-58, -52)
      ..quadraticBezierTo(-30, -78, 0, -98)
      ..quadraticBezierTo(30, -78, 58, -52)
      ..close();
    shape(c, roof, gradient: _vertical(const [Palette.red, Palette.redDark]));
    for (var i = 1; i < 4; i++) {
      final y = -52.0 - i * 11;
      final half = 58 - i * 15.0;
      line(c, Offset(-half + 4, y), Offset(half - 4, y), const Color(0x44000000), 2.5);
    }
    // door
    final door = Path()
      ..addRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(-11, -34, 22, 34),
          topLeft: const Radius.circular(11), topRight: const Radius.circular(11)));
    shape(c, door, gradient: _vertical(const [Palette.wood, Palette.woodDark]), ow: 4);
    c.drawCircle(const Offset(6, -16), 2.2, Paint()..color = Palette.goldLight);
    // windows
    for (final x in [-38.0, 20.0]) {
      shape(c, rrectPath(x, -46, 18, 16, 3), color: const Color(0xFFBFE6FA), ow: 4);
      line(c, Offset(x + 9, -45), Offset(x + 9, -31), Palette.woodDark, 2.5);
      line(c, Offset(x + 1, -38), Offset(x + 17, -38), Palette.woodDark, 2.5);
      shape(c, rrectPath(x - 2, -30, 22, 5, 2), color: Palette.green, ow: 3);
    }
  });
}

void drawTree(Canvas c, Offset base, double h, {bool apples = true}) {
  _scaled(c, base, h, () {
    c.drawOval(const Rect.fromLTWH(-30, -6, 60, 12), Paint()..color = const Color(0x33000000));
    shape(c, rrectPath(-7, -44, 14, 44, 5),
        gradient: _vertical(const [Palette.wood, Palette.woodDark]), ow: 5);
    const blobs = [(Offset(0, -74), 27.0), (Offset(-20, -58), 21.0), (Offset(20, -58), 21.0)];
    final ol = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Palette.outline;
    for (final (o, r) in blobs) {
      c.drawCircle(o, r, ol);
    }
    final fill = Paint()
      ..shader = _vertical(const [Palette.leafLight, Palette.leaf, Palette.grassDeep])
          .createShader(const Rect.fromLTWH(-42, -102, 84, 66));
    for (final (o, r) in blobs) {
      c.drawCircle(o, r, fill);
    }
    final light = Paint()..color = const Color(0x40FFFFFF);
    c.drawCircle(const Offset(-8, -84), 9, light);
    c.drawCircle(const Offset(-26, -64), 6, light);
    if (apples) {
      for (final a in const [Offset(10, -70), Offset(-14, -52), Offset(24, -52), Offset(-4, -62)]) {
        shape(c, circlePath(a.dx, a.dy, 4), color: Palette.red, ow: 2.5);
      }
    }
  });
}

void drawBush(Canvas c, Offset base, double h) {
  _scaled(c, base, h, () {
    const blobs = [(Offset(-16, -30), 22.0), (Offset(14, -30), 22.0), (Offset(0, -44), 24.0)];
    final ol = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Palette.outline;
    for (final (o, r) in blobs) {
      c.drawCircle(o, r, ol);
    }
    final fill = Paint()
      ..shader = _vertical(const [Palette.leafLight, Palette.leaf])
          .createShader(const Rect.fromLTWH(-40, -70, 80, 62));
    for (final (o, r) in blobs) {
      c.drawCircle(o, r, fill);
    }
    for (final f in const [Offset(-14, -38), Offset(8, -50), Offset(18, -30)]) {
      c.drawCircle(f, 4, Paint()..color = const Color(0xFFFFB3C7));
    }
  });
}

/// A wooden fence from [x0] to [x1]; [y] is the ground line.
void drawFence(Canvas c, double x0, double x1, double y, double h) {
  final rail = Paint()..color = Palette.woodLight;
  final ol = Paint()
    ..color = Palette.outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  for (final ry in [y - h * 0.72, y - h * 0.36]) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x0, ry - h * 0.08, x1, ry + h * 0.08), Radius.circular(h * 0.08));
    c.drawRRect(r, ol);
    c.drawRRect(r, rail);
  }
  final spacing = h * 1.3;
  for (var x = x0 + spacing / 2; x < x1; x += spacing) {
    final post = Path()
      ..moveTo(x - h * 0.14, y)
      ..lineTo(x - h * 0.14, y - h * 0.86)
      ..lineTo(x, y - h)
      ..lineTo(x + h * 0.14, y - h * 0.86)
      ..lineTo(x + h * 0.14, y)
      ..close();
    c.drawPath(post, ol);
    c.drawPath(post, Paint()..color = Palette.wood);
  }
}

void drawFlower(Canvas c, Offset p, double r, Color petal) {
  final ol = Paint()..color = const Color(0x664E2F1E);
  final fill = Paint()..color = petal;
  for (var i = 0; i < 5; i++) {
    final a = i * 2 * pi / 5;
    c.drawCircle(p + Offset(cos(a), sin(a)) * r, r * 0.75, ol);
  }
  for (var i = 0; i < 5; i++) {
    final a = i * 2 * pi / 5;
    c.drawCircle(p + Offset(cos(a), sin(a)) * r, r * 0.62, fill);
  }
  c.drawCircle(p, r * 0.55, Paint()..color = Palette.gold);
}

void drawGrassTuft(Canvas c, Offset p, double h, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = max(1.5, h * 0.16)
    ..strokeCap = StrokeCap.round;
  c.drawLine(p, p + Offset(-h * 0.35, -h * 0.8), paint);
  c.drawLine(p, p + Offset(0, -h), paint);
  c.drawLine(p, p + Offset(h * 0.35, -h * 0.75), paint);
}
