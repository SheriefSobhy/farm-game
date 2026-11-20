import 'dart:math';

import 'package:flutter/widgets.dart';

import 'palette.dart';

/// Every icon in the game, drawn with code (no image files needed).
enum GameIconType {
  coin,
  wheat,
  flour,
  bread,
  lock,
  barn,
  windmill,
  oven,
  stall,
  bag,
  plot,
  soundOn,
  soundOff,
  check,
  plus,
  warning,
  arrow,
}

/// A painted icon you can use like any widget.
class GameIcon extends StatelessWidget {
  const GameIcon(this.type, {super.key, this.size = 24});

  final GameIconType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(type)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.type);
  final GameIconType type;

  @override
  void paint(Canvas canvas, Size size) =>
      paintGameIcon(canvas, Offset.zero & size, type);

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => oldDelegate.type != type;
}

/// Paints [type] centered inside [rect]. Usable from Flame and Flutter.
void paintGameIcon(Canvas c, Rect rect, GameIconType type) {
  switch (type) {
    case GameIconType.windmill:
      drawWindmill(c, rect);
      return;
    case GameIconType.oven:
      drawOven(c, rect);
      return;
    case GameIconType.stall:
      drawStall(c, rect, withGoods: false);
      return;
    default:
  }
  _unitSpace(c, rect, () {
    switch (type) {
      case GameIconType.coin:
        _coin(c);
      case GameIconType.wheat:
        _wheatBundle(c);
      case GameIconType.flour:
        _flourSack(c);
      case GameIconType.bread:
        _bread(c);
      case GameIconType.lock:
        _lock(c);
      case GameIconType.barn:
        _barn(c);
      case GameIconType.bag:
        _bag(c);
      case GameIconType.plot:
        _plot(c);
      case GameIconType.soundOn:
        _speaker(c, on: true);
      case GameIconType.soundOff:
        _speaker(c, on: false);
      case GameIconType.check:
        _badge(c, Palette.green, Palette.greenDark, _tick);
      case GameIconType.plus:
        _badge(c, Palette.green, Palette.greenDark, _plusMark);
      case GameIconType.arrow:
        _arrow(c);
      case GameIconType.warning:
        _badge(c, Palette.orange, Palette.orangeDark, _bang);
      case GameIconType.windmill:
      case GameIconType.oven:
      case GameIconType.stall:
        break;
    }
  });
}

// =============================================================== helpers

/// Runs [draw] in a 100x100 space centered on (0,0) that fits [rect].
void _unitSpace(Canvas c, Rect rect, VoidCallback draw) {
  c.save();
  c.translate(rect.center.dx, rect.center.dy);
  final k = rect.shortestSide / 100;
  c.scale(k, k);
  draw();
  c.restore();
}

/// Cartoon shape: thick outline drawn first, fill drawn on top.
void shape(
  Canvas c,
  Path p, {
  Color? color,
  Gradient? gradient,
  double ow = 6,
  Color outline = Palette.outline,
}) {
  if (ow > 0) {
    c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ow
        ..strokeJoin = StrokeJoin.round
        ..color = outline,
    );
  }
  final paint = Paint();
  if (gradient != null) {
    paint.shader = gradient.createShader(p.getBounds());
  } else {
    paint.color = color ?? Palette.outline;
  }
  c.drawPath(p, paint);
}

Path circlePath(double x, double y, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

Path rrectPath(double l, double t, double w, double h, double r) => Path()
  ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)));

void line(Canvas c, Offset a, Offset b, Color color, double w) {
  c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round,
  );
}

void _shine(Canvas c, Rect r) =>
    c.drawOval(r, Paint()..color = const Color(0x73FFFFFF));

LinearGradient _vertical(List<Color> colors) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

// ================================================================= items

void _coin(Canvas c) {
  shape(
    c,
    circlePath(0, 0, 44),
    gradient: const RadialGradient(
      center: Alignment(-0.35, -0.45),
      radius: 0.95,
      colors: [Palette.goldLight, Palette.gold, Palette.goldDark],
      stops: [0, 0.55, 1],
    ),
    ow: 7,
  );
  c.drawCircle(
    Offset.zero,
    31,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Palette.goldDark,
  );
  shape(c, _star(0, 2, 18, 8), color: Palette.goldLight, ow: 4, outline: Palette.goldDark);
  _shine(c, const Rect.fromLTWH(-30, -34, 22, 12));
}

Path _star(double cx, double cy, double outer, double inner) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = -pi / 2 + i * pi / 5;
    final pt = Offset(cx + cos(a) * r, cy + sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// One wheat ear (head of grains) at the end of a stalk.
/// [top] is the tip of the stalk, [base] is where it starts.
void wheatEar(Canvas c, Offset top, Offset base,
    {double s = 1, Color color = Palette.wheat, Color? outline, double ow = 4}) {
  final d = top - base;
  final len = d.distance;
  if (len == 0) return;
  final dir = d / len;
  final perp = Offset(-dir.dy, dir.dx);
  final ang = atan2(dir.dy, dir.dx) - pi / 2;
  final o = outline ?? Palette.outline;

  void grain(Offset center, double tilt) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(ang + tilt);
    shape(
      c,
      Path()
        ..addOval(Rect.fromCenter(
            center: Offset.zero, width: 8 * s, height: 14 * s)),
      color: color,
      ow: ow * s,
      outline: o,
    );
    c.restore();
  }

  for (var k = 3; k >= 0; k--) {
    final p = top - dir * (k * 8.5 * s);
    grain(p + perp * (5.2 * s), -0.45);
    grain(p - perp * (5.2 * s), 0.45);
  }
  grain(top + dir * (5 * s), 0);
}

void _wheatBundle(Canvas c) {
  const base = Offset(0, 44);
  const tops = [Offset(-24, -24), Offset(0, -34), Offset(24, -24)];
  for (final t in tops) {
    line(c, base, t, Palette.outline, 9);
  }
  for (final t in tops) {
    line(c, base, t, Palette.wheatDark, 4.5);
  }
  for (final t in tops) {
    wheatEar(c, t, base);
  }
  shape(c, rrectPath(-14, 14, 28, 11, 5), color: Palette.red, ow: 5);
}

void _flourSack(Canvas c) {
  final body = Path()
    ..moveTo(-15, -24)
    ..quadraticBezierTo(-42, -8, -37, 24)
    ..quadraticBezierTo(-34, 44, 0, 44)
    ..quadraticBezierTo(34, 44, 37, 24)
    ..quadraticBezierTo(42, -8, 15, -24)
    ..close();
  final tuft = Path()
    ..moveTo(-14, -24)
    ..lineTo(-22, -42)
    ..quadraticBezierTo(-6, -34, 0, -40)
    ..quadraticBezierTo(6, -34, 22, -42)
    ..lineTo(14, -24)
    ..close();
  shape(c, tuft, gradient: _vertical(const [Palette.paper, Palette.paperDark]));
  shape(c, body, gradient: _vertical(const [Color(0xFFFFFCF3), Color(0xFFEBD6AA)]));
  shape(c, rrectPath(-18, -30, 36, 9, 4.5), color: Palette.woodDark, ow: 4);
  // Little wheat stamp on the front
  shape(c, circlePath(0, 14, 15), color: const Color(0xFFF7E7C2), ow: 3, outline: Palette.wheatDark);
  wheatEar(c, const Offset(0, 6), const Offset(0, 26),
      s: 0.62, color: Palette.wheat, outline: Palette.wheatDark, ow: 3);
  // flour dust
  c.drawCircle(const Offset(-26, 38), 3, Paint()..color = const Color(0xCCFFFFFF));
  c.drawCircle(const Offset(30, 34), 2.2, Paint()..color = const Color(0xCCFFFFFF));
  _shine(c, const Rect.fromLTWH(-28, -10, 12, 20));
}

void _bread(Canvas c) {
  final loaf = Path()
    ..moveTo(-42, 18)
    ..cubicTo(-48, -14, -26, -32, 0, -32)
    ..cubicTo(26, -32, 48, -14, 42, 18)
    ..quadraticBezierTo(42, 30, 30, 30)
    ..lineTo(-30, 30)
    ..quadraticBezierTo(-42, 30, -42, 18)
    ..close();
  shape(c, loaf,
      gradient: _vertical(const [Color(0xFFF0B25C), Color(0xFFD9893A), Color(0xFFB0632A)]),
      ow: 7);
  for (final x in [-20.0, 0.0, 20.0]) {
    line(c, Offset(x - 7, -2), Offset(x + 7, -20), const Color(0xFF9A5424), 7);
    line(c, Offset(x - 7, -2), Offset(x + 7, -20), const Color(0xFFFAD9A0), 3.5);
  }
  _shine(c, const Rect.fromLTWH(-32, -22, 16, 9));
}

// ============================================================ small icons

void _lock(Canvas c) {
  final shackle = Path()
    ..moveTo(-18, -6)
    ..lineTo(-18, -20)
    ..arcToPoint(const Offset(18, -20), radius: const Radius.circular(18))
    ..lineTo(18, -6);
  c.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..color = Palette.outline);
  c.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Palette.stone);
  shape(c, rrectPath(-30, -10, 60, 50, 11),
      gradient: _vertical(const [Palette.goldLight, Palette.goldDark]));
  shape(c, circlePath(0, 8, 7), color: Palette.outline, ow: 0);
  shape(c, rrectPath(-3.5, 8, 7, 18, 3), color: Palette.outline, ow: 0);
}

void _barn(Canvas c) {
  final body = Path()
    ..moveTo(-38, 42)
    ..lineTo(-38, -4)
    ..lineTo(0, -34)
    ..lineTo(38, -4)
    ..lineTo(38, 42)
    ..close();
  shape(c, body, gradient: _vertical(const [Palette.red, Palette.redDark]));
  final roof = Path()
    ..moveTo(-46, 0)
    ..lineTo(0, -42)
    ..lineTo(46, 0);
  c.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.outline);
  c.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.paper);
  shape(c, rrectPath(-17, 8, 34, 34, 3), color: Palette.paper, ow: 5);
  line(c, const Offset(-13, 12), const Offset(13, 38), Palette.redDark, 4);
  line(c, const Offset(13, 12), const Offset(-13, 38), Palette.redDark, 4);
  shape(c, rrectPath(-8, -16, 16, 13, 3), color: Palette.goldLight, ow: 4);
}

void _bag(Canvas c) {
  final handle = Path()
    ..moveTo(-16, -14)
    ..cubicTo(-16, -44, 16, -44, 16, -14);
  c.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round
        ..color = Palette.outline);
  c.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = Palette.woodLight);
  final body = Path()
    ..moveTo(-34, -16)
    ..lineTo(34, -16)
    ..lineTo(40, 36)
    ..quadraticBezierTo(40, 44, 32, 44)
    ..lineTo(-32, 44)
    ..quadraticBezierTo(-40, 44, -40, 36)
    ..close();
  shape(c, body, gradient: _vertical(const [Palette.orange, Palette.orangeDark]));
  _unitSub(c, const Offset(0, 16), 0.42, _coin);
}

void _unitSub(Canvas c, Offset at, double scale, void Function(Canvas) draw) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(scale, scale);
  draw(c);
  c.restore();
}

void _plot(Canvas c) {
  shape(c, rrectPath(-44, -30, 88, 72, 16),
      gradient: _vertical(const [Palette.soilLight, Palette.soil]), ow: 6);
  for (final y in [-12.0, 8.0, 28.0]) {
    shape(c, rrectPath(-34, y - 6, 68, 10, 5), color: Palette.soilDark, ow: 0);
  }
  line(c, const Offset(0, -12), const Offset(0, -34), Palette.outline, 8);
  line(c, const Offset(0, -12), const Offset(0, -34), Palette.leaf, 4);
  _leaf(c, const Offset(-9, -36), -0.6, 1.3);
  _leaf(c, const Offset(9, -38), 0.6, 1.3);
}

void _leaf(Canvas c, Offset center, double angle, double s) {
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  shape(
    c,
    Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: 10 * s, height: 16 * s)),
    gradient: _vertical(const [Palette.leafLight, Palette.leaf]),
    ow: 4,
  );
  c.restore();
}

void _speaker(Canvas c, {required bool on}) {
  final p = Path()
    ..moveTo(-38, -12)
    ..lineTo(-20, -12)
    ..lineTo(2, -32)
    ..lineTo(2, 32)
    ..lineTo(-20, 12)
    ..lineTo(-38, 12)
    ..close();
  shape(c, p, gradient: _vertical(const [Palette.woodLight, Palette.woodDark]));
  final wave = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  if (on) {
    for (final r in [16.0, 30.0]) {
      final arc = Rect.fromCircle(center: const Offset(4, 0), radius: r);
      c.drawArc(arc, -0.8, 1.6, false, wave..strokeWidth = 10..color = Palette.outline);
      c.drawArc(arc, -0.8, 1.6, false, wave..strokeWidth = 5..color = Palette.green);
    }
  } else {
    for (final w in [12.0, 6.0]) {
      final col = w > 10 ? Palette.outline : Palette.red;
      line(c, const Offset(14, -14), const Offset(40, 12), col, w);
      line(c, const Offset(40, -14), const Offset(14, 12), col, w);
    }
  }
}

void _badge(Canvas c, Color color, Color dark, void Function(Canvas) mark) {
  shape(c, circlePath(0, 0, 42), gradient: _vertical([color, dark]), ow: 7);
  mark(c);
  _shine(c, const Rect.fromLTWH(-26, -32, 22, 11));
}

void _tick(Canvas c) {
  final p = Path()
    ..moveTo(-20, 2)
    ..lineTo(-6, 16)
    ..lineTo(22, -14);
  c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFFFFF));
}

void _plusMark(Canvas c) {
  line(c, const Offset(0, -20), const Offset(0, 20), const Color(0xFFFFFFFF), 12);
  line(c, const Offset(-20, 0), const Offset(20, 0), const Color(0xFFFFFFFF), 12);
}

void _bang(Canvas c) {
  line(c, const Offset(0, -22), const Offset(0, 6), const Color(0xFFFFFFFF), 12);
  c.drawCircle(const Offset(0, 22), 6.5, Paint()..color = const Color(0xFFFFFFFF));
}

// ===================================================== buildings & stall

/// The windmill. [angle] rotates the blades (radians).
void drawWindmill(Canvas c, Rect rect, {double angle = 0.35}) {
  _unitSpace(c, rect, () {
    c.translate(0, 9);
    c.scale(0.8, 0.8);
    // tower
    final tower = Path()
      ..moveTo(-26, 52)
      ..lineTo(-16, -14)
      ..lineTo(16, -14)
      ..lineTo(26, 52)
      ..close();
    shape(c, tower, gradient: _vertical(const [Color(0xFFF6E7C9), Color(0xFFD9BE91)]));
    final stone = Paint()..color = const Color(0x22000000);
    for (final s in const [
      Rect.fromLTWH(-14, 0, 12, 6),
      Rect.fromLTWH(4, 8, 12, 6),
      Rect.fromLTWH(-18, 22, 12, 6),
      Rect.fromLTWH(8, 30, 12, 6),
    ]) {
      c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(3)), stone);
    }
    // door and window
    final door = Path()
      ..addRRect(RRect.fromRectAndCorners(
        const Rect.fromLTWH(-9, 30, 18, 22),
        topLeft: const Radius.circular(9),
        topRight: const Radius.circular(9),
      ));
    shape(c, door, gradient: _vertical(const [Palette.wood, Palette.woodDark]), ow: 4);
    shape(c, circlePath(0, 10, 5.5), color: const Color(0xFF3F6E8C), ow: 3.5);
    // roof
    final roof = Path()
      ..moveTo(-22, -10)
      ..quadraticBezierTo(-12, -30, 0, -40)
      ..quadraticBezierTo(12, -30, 22, -10)
      ..close();
    shape(c, roof, gradient: _vertical(const [Palette.red, Palette.redDark]));
    // blades
    for (var i = 0; i < 4; i++) {
      c.save();
      c.translate(0, -20);
      c.rotate(angle + i * pi / 2);
      line(c, Offset.zero, const Offset(0, -54), Palette.outline, 7);
      line(c, Offset.zero, const Offset(0, -54), Palette.woodDark, 3.5);
      final sail = rrectPath(2, -54, 15, 38, 3);
      shape(c, sail, color: const Color(0xFFFFF7E6), ow: 4);
      for (final y in [-44.0, -34.0, -24.0]) {
        line(c, Offset(3, y), Offset(16, y), const Color(0x664E2F1E), 2);
      }
      line(c, const Offset(9.5, -53), const Offset(9.5, -17), const Color(0x664E2F1E), 2);
      c.restore();
    }
    shape(c, circlePath(0, -20, 7), color: Palette.woodDark, ow: 4);
  });
}

/// The brick oven. While [working], fire glows and smoke puffs rise.
/// [t] is time in seconds (drives the animation).
void drawOven(Canvas c, Rect rect, {double t = 0, bool working = false}) {
  _unitSpace(c, rect, () {
    c.translate(0, 8);
    c.scale(0.86, 0.86);

    // smoke (behind chimney top)
    if (working) {
      for (var i = 0; i < 4; i++) {
        final phase = (t * 0.55 + i / 4) % 1.0;
        final x = 27 + sin(phase * 5 + i) * 7 + phase * 10;
        final y = -50 - phase * 52;
        final r = 6 + phase * 12;
        c.drawCircle(Offset(x, y), r,
            Paint()..color = Color.fromRGBO(240, 236, 230, (1 - phase) * 0.85));
      }
    }
    // chimney
    shape(c, rrectPath(18, -52, 16, 30, 3),
        gradient: _vertical(const [Palette.brick, Palette.brickDark]), ow: 5);
    shape(c, rrectPath(15, -56, 22, 8, 3), color: Palette.stoneDark, ow: 4);

    // dome
    final dome = Path()
      ..moveTo(-46, 40)
      ..lineTo(-46, 6)
      ..arcToPoint(const Offset(46, 6), radius: const Radius.circular(46))
      ..lineTo(46, 40)
      ..close();
    shape(c, dome, gradient: _vertical(const [Color(0xFFDD7556), Palette.brick, Palette.brickDark]));
    c.save();
    c.clipPath(dome);
    final mortar = Paint()
      ..color = const Color(0x55702A1B)
      ..strokeWidth = 2;
    for (var row = 0; row < 9; row++) {
      final y = -36.0 + row * 9;
      c.drawLine(Offset(-50, y), Offset(50, y), mortar);
      for (var col = 0; col < 8; col++) {
        final x = -48.0 + col * 14 + (row.isEven ? 0 : 7);
        c.drawLine(Offset(x, y), Offset(x, y + 9), mortar);
      }
    }
    c.restore();

    // glow
    if (working) {
      final pulse = 0.75 + 0.25 * sin(t * 7);
      c.drawCircle(
        const Offset(0, 28),
        40,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 190, 80, 0.75 * pulse),
            const Color.fromRGBO(255, 140, 40, 0),
          ]).createShader(Rect.fromCircle(center: const Offset(0, 28), radius: 40)),
      );
    }
    // mouth
    final mouth = Path()
      ..moveTo(-22, 40)
      ..lineTo(-22, 22)
      ..arcToPoint(const Offset(22, 22), radius: const Radius.circular(22))
      ..lineTo(22, 40)
      ..close();
    shape(c, mouth, color: working ? const Color(0xFF4A1A0C) : const Color(0xFF2E1A12), ow: 5);
    if (working) {
      c.save();
      c.clipPath(mouth);
      for (var i = 0; i < 3; i++) {
        final x = -11.0 + i * 11;
        final h = 18 + 6 * sin(t * 13 + i * 2.1);
        _flame(c, Offset(x, 40), 9, h, Palette.orange);
        _flame(c, Offset(x, 40), 5, h * 0.6, Palette.goldLight);
      }
      c.restore();
    } else {
      // resting logs
      shape(c, rrectPath(-14, 32, 28, 7, 3.5), color: Palette.woodDark, ow: 3);
    }
    // stone base
    shape(c, rrectPath(-54, 38, 108, 12, 5),
        gradient: _vertical(const [Palette.stone, Palette.stoneDark]), ow: 5);
  });
}

void _flame(Canvas c, Offset base, double halfWidth, double height, Color color) {
  final p = Path()
    ..moveTo(base.dx - halfWidth, base.dy)
    ..quadraticBezierTo(base.dx - halfWidth * 1.2, base.dy - height * 0.55,
        base.dx, base.dy - height)
    ..quadraticBezierTo(base.dx + halfWidth * 1.2, base.dy - height * 0.55,
        base.dx + halfWidth, base.dy)
    ..close();
  c.drawPath(p, Paint()..color = color);
}

/// Market stall with a striped awning.
void drawStall(Canvas c, Rect rect, {bool withGoods = true}) {
  _unitSpace(c, rect, () {
    c.translate(0, 4);
    c.scale(0.9, 0.9);
    // posts
    for (final x in [-44.0, 38.0]) {
      shape(c, rrectPath(x, -30, 6, 76, 3), color: Palette.woodDark, ow: 4);
    }
    // counter
    shape(c, rrectPath(-50, 12, 100, 34, 6),
        gradient: _vertical(const [Palette.woodLight, Palette.wood]), ow: 6);
    for (final y in [23.0, 34.0]) {
      line(c, Offset(-46, y), Offset(46, y), const Color(0x554E2F1E), 2.5);
    }
    if (withGoods) {
      _unitSub(c, const Offset(-28, 2), 0.3, _wheatBundle);
      _unitSub(c, const Offset(0, 0), 0.32, _flourSack);
      _unitSub(c, const Offset(28, 4), 0.3, _bread);
    }
    // awning
    final awning = Path()..moveTo(-54, -40);
    awning.lineTo(54, -40);
    awning.lineTo(54, -18);
    const scallops = 6;
    const w = 108 / scallops;
    for (var i = 0; i < scallops; i++) {
      final x1 = 54 - i * w;
      awning.quadraticBezierTo(x1 - w / 2, -6, x1 - w, -18);
    }
    awning.close();
    c.drawPath(
        awning,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.outline);
    c.save();
    c.clipPath(awning);
    for (var i = 0; i < scallops; i++) {
      c.drawRect(Rect.fromLTWH(-54 + i * w, -42, w, 40),
          Paint()..color = i.isEven ? Palette.red : Palette.paper);
    }
    c.restore();
    shape(c, rrectPath(-58, -48, 116, 10, 5), color: Palette.woodDark, ow: 5);
  });
}

void _arrow(Canvas c) {
  final p = Path()
    ..moveTo(-40, -12)
    ..lineTo(4, -12)
    ..lineTo(4, -32)
    ..lineTo(42, 0)
    ..lineTo(4, 32)
    ..lineTo(4, 12)
    ..lineTo(-40, 12)
    ..close();
  shape(c, p, gradient: _vertical(const [Palette.woodLight, Palette.woodDark]), ow: 8);
}
