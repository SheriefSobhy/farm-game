import 'dart:math';
import 'dart:ui';

/// Smooth, glossy cartoon art drawn with vector paths and gradients.
///
/// Everything here is resolution independent: it is drawn straight onto the
/// canvas, so it stays crisp at any zoom. Shapes use a soft gradient fill, a
/// thin darker outline, a glossy highlight and a soft drop shadow.
abstract final class Cartoon {
  // ------------------------------------------------------------- helpers

  static Paint fill(Color c) => Paint()..color = c;

  static Paint line(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Paint vGrad(Rect r, Color top, Color bottom) =>
      Paint()..shader = Gradient.linear(r.topCenter, r.bottomCenter, [top, bottom]);

  static Paint hGrad(Rect r, Color left, Color right) =>
      Paint()..shader = Gradient.linear(r.centerLeft, r.centerRight, [left, right]);

  /// Fills [p] with [paint] and outlines it with [outline].
  static void shape(Canvas c, Path p, Paint paint, Color outline, double w) {
    c.drawPath(p, paint);
    c.drawPath(p, line(outline, w));
  }

  /// A soft, blurred shadow ellipse on the ground.
  static void groundShadow(Canvas c, Offset center, double w, double h, {double alpha = 0.28}) {
    c.drawOval(
      Rect.fromCenter(center: center, width: w, height: h),
      Paint()
        ..color = Color.fromRGBO(30, 60, 10, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.3),
    );
  }

  /// A glossy white highlight that fades out toward the bottom of [r].
  static void gloss(Canvas c, Rect r, {double alpha = 0.6}) {
    c.drawOval(
      r,
      Paint()
        ..shader = Gradient.linear(r.topCenter, r.bottomCenter, [
          Color.fromRGBO(255, 255, 255, alpha),
          const Color(0x00FFFFFF),
        ]),
    );
  }

  /// Runs [draw] inside a layer when the art must be faded or recolored.
  static void layered(Canvas c, Rect bounds, Paint? paint, double opacity, void Function() draw) {
    if (paint == null && opacity >= 1) {
      draw();
      return;
    }
    final p = Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0));
    if (paint?.colorFilter != null) p.colorFilter = paint!.colorFilter;
    c.saveLayer(bounds.inflate(4), p);
    draw();
    c.restore();
  }

  // ------------------------------------------------------------- ground

  static const grassTop = Color(0xFF9CDB5A);
  static const grassBottom = Color(0xFF79C443);
  static const grassDark = Color(0xFF58A636);
  static const grassLight = Color(0xFFB9EA78);

  /// The base lawn: a soft gradient with light and dark patches.
  static void lawn(Canvas c, Rect area, Random rnd) {
    c.drawRect(area, vGrad(area, grassTop, grassBottom));
    // big soft patches give the lawn some gentle variation
    final n = (area.width * area.height / 900).round();
    for (var i = 0; i < n; i++) {
      final light = rnd.nextBool();
      final w = 20 + rnd.nextDouble() * 34;
      final center = Offset(
        area.left + rnd.nextDouble() * area.width,
        area.top + rnd.nextDouble() * area.height,
      );
      c.drawOval(
        Rect.fromCenter(center: center, width: w, height: w * 0.6),
        Paint()
          ..color = (light ? grassLight : grassDark).withValues(alpha: light ? 0.35 : 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  /// A small tuft of three curved grass blades with its base at [o].
  static void tuft(Canvas c, Offset o, double s, {Color color = grassDark}) {
    final p = Path()
      ..moveTo(o.dx - 2 * s, o.dy)
      ..quadraticBezierTo(o.dx - 2.1 * s, o.dy - 1.8 * s, o.dx - 3.2 * s, o.dy - 3 * s)
      ..quadraticBezierTo(o.dx - 1.2 * s, o.dy - 2.2 * s, o.dx - 0.7 * s, o.dy - 0.8 * s)
      ..quadraticBezierTo(o.dx - 0.4 * s, o.dy - 3 * s, o.dx + 0.2 * s, o.dy - 4.4 * s)
      ..quadraticBezierTo(o.dx + 1 * s, o.dy - 2.6 * s, o.dx + 0.8 * s, o.dy - 0.8 * s)
      ..quadraticBezierTo(o.dx + 1.6 * s, o.dy - 2.2 * s, o.dx + 3.2 * s, o.dy - 2.8 * s)
      ..quadraticBezierTo(o.dx + 2.2 * s, o.dy - 1.4 * s, o.dx + 2 * s, o.dy)
      ..close();
    c.drawPath(p, fill(color));
  }

  /// A tiny five-petal flower.
  static void flower(Canvas c, Offset o, Color petal, {double s = 1}) {
    final petals = fill(petal);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      c.drawCircle(o + Offset(cos(a), sin(a)) * 1.1 * s, 0.95 * s, petals);
    }
    c.drawCircle(o, 0.75 * s, fill(const Color(0xFFFFC93C)));
    c.drawCircle(o + Offset(-0.25 * s, -0.25 * s), 0.3 * s, fill(const Color(0xCCFFFFFF)));
  }

  /// A smooth, rounded dirt path with soft edges and a few pebbles.
  static void dirtPath(Canvas c, Path path, Rect bounds, Random rnd) {
    // soft darker edge
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0x5584541E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
    );
    c.save();
    c.clipPath(path);
    c.drawRect(bounds, vGrad(bounds, const Color(0xFFF0CF96), const Color(0xFFDDAE6E)));
    // inner shading so the path looks slightly sunken
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0x40A0662C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
    for (var i = 0; i < 40; i++) {
      final o = Offset(
        bounds.left + rnd.nextDouble() * bounds.width,
        bounds.top + rnd.nextDouble() * bounds.height,
      );
      final r = 0.5 + rnd.nextDouble() * 0.7;
      c.drawOval(
        Rect.fromCenter(center: o, width: r * 2.2, height: r * 1.6),
        fill(const Color(0xFFC99556)),
      );
      c.drawCircle(o.translate(-r * 0.3, -r * 0.3), r * 0.35, fill(const Color(0x88FFF1D6)));
    }
    c.restore();
  }

  // ------------------------------------------------------------- field

  /// A tilled soil plot with two raised rows. Planted (watered) soil is
  /// darker than empty soil.
  static void soil(Canvas c, Rect r, {required bool wet}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(5));
    c.drawRRect(
      rr.shift(const Offset(0, 1.4)),
      Paint()
        ..color = const Color(0x55264A12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    final top = wet ? const Color(0xFFB0703F) : const Color(0xFFE2AE73);
    final bottom = wet ? const Color(0xFF85502A) : const Color(0xFFC08549);
    final outline = wet ? const Color(0xFF5A3218) : const Color(0xFF8A5528);
    c.drawRRect(rr, vGrad(r, top, bottom));

    // two raised rows (ridges) with a groove between them
    final ridgeLight = wet ? const Color(0xFFC0814C) : const Color(0xFFF0C388);
    final ridgeDark = wet ? const Color(0xFF94592F) : const Color(0xFFCF9558);
    final h = (r.height - 7) / 2;
    for (var i = 0; i < 2; i++) {
      final ridge = RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 2.2, r.top + 2.2 + i * (h + 2.6), r.width - 4.4, h),
        Radius.circular(h / 2),
      );
      c.drawRRect(ridge, vGrad(ridge.outerRect, ridgeLight, ridgeDark));
      c.drawRRect(ridge, line(outline.withValues(alpha: 0.35), 0.5));
      // glossy line along the top of the ridge
      c.drawLine(
        Offset(ridge.left + h / 2, ridge.top + 1.1),
        Offset(ridge.right - h / 2, ridge.top + 1.1),
        line(const Color(0x55FFFFFF), 0.8),
      );
      // little clods
      for (var k = 0; k < 4; k++) {
        c.drawCircle(
          Offset(ridge.left + 4 + k * (ridge.width - 8) / 3, ridge.bottom - 1.4 - (k % 2) * 0.7),
          0.55,
          fill(ridgeDark.withValues(alpha: 0.9)),
        );
      }
    }
    c.drawRRect(rr, line(outline, 0.8));
  }

  static const _leafLight = Color(0xFFA6E663);
  static const _leafDark = Color(0xFF4CA22C);
  static const _leafLine = Color(0xFF2E7520);

  static Path _leafPath(double len, double w) => Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(w, -len * 0.45, 0, -len)
    ..quadraticBezierTo(-w, -len * 0.45, 0, 0)
    ..close();

  /// A leaf growing from [base], tilted by [angle] (radians, 0 = up).
  static void leaf(
    Canvas c,
    Offset base,
    double angle,
    double len,
    double w, {
    Color light = _leafLight,
    Color dark = _leafDark,
    Color outline = _leafLine,
  }) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    final p = _leafPath(len, w);
    final b = Rect.fromLTWH(-w, -len, w * 2, len);
    shape(c, p, hGrad(b, light, dark), outline, 0.35);
    c.drawLine(Offset(0, -len * 0.15), Offset(0, -len * 0.75), line(const Color(0x55FFFFFF), 0.3));
    c.restore();
  }

  static const _grain = [Color(0xFFFFE68A), Color(0xFFF0B43A)];
  static const _grainLine = Color(0xFFB0741C);
  static const _youngGrain = [Color(0xFFD5F27E), Color(0xFF86C640)];
  static const _youngLine = Color(0xFF4F8A24);

  /// A wheat ear (stacked grains) whose stalk top is at [top].
  static void _ear(Canvas c, Offset top, double tilt, int pairs, List<Color> g, Color outline) {
    c.save();
    c.translate(top.dx, top.dy);
    c.rotate(tilt);
    // awns (bristles) poking out of the top
    final awn = line(g[1].withValues(alpha: 0.9), 0.25);
    final tipY = -pairs * 1.35 - 1;
    c.drawLine(Offset(0, tipY), Offset(0, tipY - 2.6), awn);
    c.drawLine(Offset(-0.4, tipY + 0.4), Offset(-1.5, tipY - 2), awn);
    c.drawLine(Offset(0.4, tipY + 0.4), Offset(1.5, tipY - 2), awn);
    for (var j = 0; j < pairs; j++) {
      final y = -j * 1.35 - 0.6;
      for (final side in [-1.0, 1.0]) {
        c.save();
        c.translate(side * 0.6, y);
        c.rotate(side * 0.45);
        final grain = Rect.fromCenter(center: Offset.zero, width: 1.5, height: 2.4);
        c.drawOval(grain, vGrad(grain, g[0], g[1]));
        c.drawOval(grain, line(outline, 0.25));
        c.restore();
      }
    }
    final head = Rect.fromCenter(center: Offset(0, tipY + 0.4), width: 1.4, height: 2.2);
    c.drawOval(head, vGrad(head, g[0], g[1]));
    c.drawOval(head, line(outline, 0.25));
    // shiny highlight
    c.drawOval(
      Rect.fromCenter(center: Offset(-0.45, -pairs * 0.8), width: 0.5, height: pairs * 1.1),
      fill(const Color(0x99FFFFFF)),
    );
    c.restore();
  }

  /// One clump of wheat whose base is at the origin. [stage]: 0 sprout,
  /// 1 young (green), 2 ripe (golden).
  static void wheat(Canvas c, int stage) {
    groundShadow(c, const Offset(0, 0.3), 9, 2.4, alpha: 0.25);
    switch (stage) {
      case 0:
        leaf(c, const Offset(-0.4, 0), -0.7, 4.2, 1.3);
        leaf(c, const Offset(0.4, 0), 0.7, 4.2, 1.3);
        leaf(c, Offset.zero, 0.05, 5.6, 1.4);
      case 1:
        const stalks = [(-2.6, 8.0, -0.12), (0.0, 10.0, 0.0), (2.6, 8.0, 0.12)];
        for (final (x, h, t) in stalks) {
          final top = Offset(x + t * h * 0.6, -h);
          c.drawLine(Offset(x * 0.4, 0), top, line(_leafLine, 0.95));
          c.drawLine(Offset(x * 0.4, 0), top, line(const Color(0xFF7CC443), 0.55));
          _ear(c, top, t, 2, _youngGrain, _youngLine);
        }
        leaf(c, const Offset(-0.6, 0), -0.9, 4.5, 1.2);
        leaf(c, const Offset(0.6, 0), 0.9, 4.5, 1.2);
      default:
        const stalks = [
          (-3.6, 9.5, -0.22),
          (3.6, 9.5, 0.22),
          (-1.7, 12.0, -0.09),
          (1.7, 12.0, 0.09),
          (0.0, 13.5, 0.0),
        ];
        for (final (x, h, t) in stalks) {
          final top = Offset(x + t * h * 0.6, -h);
          c.drawLine(Offset(x * 0.4, 0), top, line(_grainLine, 1.0));
          c.drawLine(Offset(x * 0.4, 0), top, line(const Color(0xFFF2C855), 0.6));
          _ear(c, top, t, 4, _grain, _grainLine);
        }
        const gl = Color(0xFFF5D670);
        const gd = Color(0xFFD9A13A);
        leaf(c, const Offset(-0.6, 0), -1.0, 4.8, 1.2, light: gl, dark: gd, outline: _grainLine);
        leaf(c, const Offset(0.6, 0), 1.0, 4.8, 1.2, light: gl, dark: gd, outline: _grainLine);
    }
  }

  /// A rounded growth bar.
  static void progressBar(Canvas c, Rect r, double p) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height / 2));
    c.drawRRect(rr.shift(const Offset(0, 0.6)), fill(const Color(0x40000000)));
    c.drawRRect(rr, fill(const Color(0xFF5B3A22)));
    final inner = r.deflate(0.8);
    if (p > 0) {
      final fr = Rect.fromLTWH(inner.left, inner.top, max(inner.height, inner.width * p), inner.height);
      final f = RRect.fromRectAndRadius(fr, Radius.circular(inner.height / 2));
      c.drawRRect(f, vGrad(fr, const Color(0xFFB4F05A), const Color(0xFF52B52A)));
      c.drawLine(
        Offset(fr.left + inner.height / 2, fr.top + inner.height * 0.32),
        Offset(fr.right - inner.height / 2, fr.top + inner.height * 0.32),
        line(const Color(0x88FFFFFF), inner.height * 0.3),
      );
    }
  }

  /// A four-pointed twinkle.
  static void sparkle(Canvas c, Offset o, double s, double alpha) {
    final p = Path()
      ..moveTo(o.dx, o.dy - s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s)
      ..close();
    c.drawPath(p, fill(Color.fromRGBO(255, 255, 255, alpha)));
  }

  // ------------------------------------------------------------- barn

  static const _barnRed = Color(0xFFEE4B3B);
  static const _barnRedDark = Color(0xFFBE2A20);
  static const _barnLine = Color(0xFF6A160F);
  static const _trim = Color(0xFFFFFBF2);
  static const _trimShade = Color(0xFFE9DCC8);

  static Path _barnFacade() => Path()
    ..moveTo(3, 64)
    ..lineTo(3, 27)
    ..lineTo(10, 11)
    ..lineTo(24, 2)
    ..lineTo(38, 11)
    ..lineTo(45, 27)
    ..lineTo(45, 64)
    ..close();

  /// The front of the red barn in a 48 x 64 box (no shadow, no cupola).
  static void barnFront(Canvas c) {
    const box = Rect.fromLTWH(0, 0, 48, 64);
    final facade = _barnFacade();
    c.drawPath(facade, vGrad(box, _barnRed, _barnRedDark));
    // planks + glossy left side, clipped to the walls
    c.save();
    c.clipPath(facade);
    final plank = line(const Color(0x33600F0A), 0.5);
    for (var x = 7.5; x < 45; x += 4.5) {
      c.drawLine(Offset(x, 0), Offset(x, 64), plank);
    }
    c.drawRect(
      const Rect.fromLTWH(3, 0, 14, 64),
      hGrad(const Rect.fromLTWH(3, 0, 14, 64), const Color(0x40FFFFFF), const Color(0x00FFFFFF)),
    );
    c.drawRect(const Rect.fromLTWH(3, 60, 42, 4), fill(const Color(0x33000000)));
    c.restore();
    c.drawPath(facade, line(_barnLine, 1));

    // white roof trim with a thin dark outline
    final roof = Path()
      ..moveTo(1, 29)
      ..lineTo(8.6, 10.2)
      ..lineTo(24, 0)
      ..lineTo(39.4, 10.2)
      ..lineTo(47, 29);
    c.drawPath(roof, line(_barnLine, 5.2));
    c.drawPath(roof, line(_trim, 3.4));
    c.drawPath(roof.shift(const Offset(0, 0.8)), line(_trimShade, 1));

    // hay loft window
    final loft = RRect.fromRectAndRadius(const Rect.fromLTWH(17, 13, 14, 12), const Radius.circular(2));
    c.drawRRect(loft.inflate(1.6), fill(_trim));
    c.drawRRect(loft.inflate(1.6), line(_barnLine, 0.7));
    c.drawRRect(loft, vGrad(loft.outerRect, const Color(0xFF5A1E14), const Color(0xFF3E120C)));
    final hay = Path()
      ..moveTo(17, 25)
      ..quadraticBezierTo(19, 18, 22, 21)
      ..quadraticBezierTo(24, 16.5, 27, 20)
      ..quadraticBezierTo(29.5, 18.5, 31, 25)
      ..close();
    c.save();
    c.clipRRect(loft);
    c.drawPath(hay, vGrad(const Rect.fromLTWH(17, 17, 14, 8), const Color(0xFFFFE27A), const Color(0xFFE5A92F)));
    c.restore();

    // big double doors with white X braces
    const door = Rect.fromLTWH(11, 34, 26, 30);
    c.drawRect(door, vGrad(door, const Color(0xFFD8382B), const Color(0xFFA9231A)));
    final brace = line(_trim, 1.7);
    for (final half in [
      const Rect.fromLTWH(11, 34, 13, 30),
      const Rect.fromLTWH(24, 34, 13, 30),
    ]) {
      final h = half.deflate(1.6);
      c.drawLine(h.topLeft, h.bottomRight, brace);
      c.drawLine(h.topRight, h.bottomLeft, brace);
    }
    c.drawLine(const Offset(24, 34), const Offset(24, 64), line(_trim, 1.6));
    c.drawRect(door.deflate(0.8), line(_trim, 1.8));
    c.drawRect(door, line(_barnLine, 0.7));
    // little door handles
    c.drawCircle(const Offset(22, 49), 0.8, fill(const Color(0xFFFFC93C)));
    c.drawCircle(const Offset(26, 49), 0.8, fill(const Color(0xFFFFC93C)));
  }

  /// The full barn (cupola, walls, doors) in the 48 x 112 farm spot.
  static void barn(Canvas c, {Paint? paint}) {
    groundShadow(c, const Offset(24, 107), 58, 9);
    // cupola with a weather vane on the roof
    final cup = vGrad(const Rect.fromLTWH(19, 30, 10, 14), _trim, _trimShade);
    c.drawLine(const Offset(24, 18), const Offset(24, 28), line(const Color(0xFF5A3A22), 0.8));
    final vane = Path()
      ..moveTo(21, 21)
      ..lineTo(27, 21)
      ..lineTo(28.5, 20)
      ..lineTo(27, 22.5)
      ..lineTo(21, 22.5)
      ..close();
    c.drawPath(vane, fill(const Color(0xFF5A3A22)));
    shape(c, Path()..addRect(const Rect.fromLTWH(19.5, 32, 9, 12)), cup, _barnLine, 0.7);
    c.drawRect(const Rect.fromLTWH(21.5, 34.5, 5, 6), fill(const Color(0xFF5A1E14)));
    final cupRoof = Path()
      ..moveTo(17.5, 33)
      ..lineTo(24, 26.5)
      ..lineTo(30.5, 33)
      ..close();
    shape(c, cupRoof, vGrad(const Rect.fromLTWH(17, 26, 14, 7), _barnRed, _barnRedDark), _barnLine, 0.7);

    c.save();
    c.translate(-2, 42);
    c.scale(52 / 48, 66 / 64);
    barnFront(c);
    c.restore();
  }

  // ------------------------------------------------------------- windmill

  /// The windmill tower in its 32 x 46 farm box (sails drawn separately).
  static void windmillTower(Canvas c) {
    groundShadow(c, const Offset(16, 45), 30, 5);
    final body = Path()
      ..moveTo(4.5, 45)
      ..lineTo(9.5, 13)
      ..lineTo(22.5, 13)
      ..lineTo(27.5, 45)
      ..close();
    const b = Rect.fromLTWH(4, 12, 24, 34);
    c.drawPath(body, hGrad(b, const Color(0xFFFFF8E6), const Color(0xFFE3C99A)));
    c.save();
    c.clipPath(body);
    // soft stone courses
    for (final y in [21.0, 29.0, 37.0]) {
      c.drawLine(Offset(0, y), Offset(32, y), line(const Color(0x33A27A45), 0.6));
    }
    c.drawRect(const Rect.fromLTWH(4, 41, 24, 5), fill(const Color(0x22000000)));
    c.restore();
    c.drawPath(body, line(const Color(0xFF7A5230), 0.8));

    // round window
    c.drawCircle(const Offset(16, 25), 2.6, fill(const Color(0xFF7A5230)));
    c.drawCircle(
      const Offset(16, 25),
      2,
      Paint()..shader = Gradient.radial(const Offset(15.3, 24.3), 2.4, [const Color(0xFFB9ECFF), const Color(0xFF4AA3DE)]),
    );
    c.drawCircle(const Offset(15.2, 24.2), 0.6, fill(const Color(0xDDFFFFFF)));

    // arched wooden door
    final door = Path()
      ..moveTo(12.5, 45)
      ..lineTo(12.5, 38.5)
      ..arcToPoint(const Offset(19.5, 38.5), radius: const Radius.circular(3.5))
      ..lineTo(19.5, 45)
      ..close();
    shape(c, door, vGrad(const Rect.fromLTWH(12, 35, 8, 10), const Color(0xFFC4824A), const Color(0xFF8E5528)), const Color(0xFF5A3418), 0.6);
    c.drawLine(const Offset(16, 35.5), const Offset(16, 45), line(const Color(0x665A3418), 0.4));

    // red dome cap
    final cap = Path()
      ..moveTo(6.5, 15)
      ..quadraticBezierTo(7, 3, 16, 2)
      ..quadraticBezierTo(25, 3, 25.5, 15)
      ..close();
    shape(c, cap, vGrad(const Rect.fromLTWH(6, 2, 20, 13), const Color(0xFFF65C49), const Color(0xFFB8281F)), const Color(0xFF6A160F), 0.8);
    gloss(c, const Rect.fromLTWH(9, 3.5, 7, 5), alpha: 0.7);
    final rim = RRect.fromRectAndRadius(const Rect.fromLTWH(5.5, 13.5, 21, 3), const Radius.circular(1.5));
    c.drawRRect(rim, vGrad(rim.outerRect, _trim, _trimShade));
    c.drawRRect(rim, line(const Color(0xFF7A5230), 0.6));
  }

  /// The four sails, centered on the hub at the origin (radius ~22).
  static void windmillSails(Canvas c) {
    const wood = Color(0xFF9A6634);
    const woodLine = Color(0xFF5A3418);
    for (var i = 0; i < 4; i++) {
      c.save();
      c.rotate(i * pi / 2);
      // cloth sail on a lattice frame
      final sail = RRect.fromRectAndRadius(const Rect.fromLTWH(1, -21.5, 6.5, 16.5), const Radius.circular(1.6));
      c.drawRRect(sail.shift(const Offset(0.6, 0.8)), fill(const Color(0x33000000)));
      c.drawRRect(sail, hGrad(sail.outerRect, const Color(0xFFFFFDF6), const Color(0xFFEBDDBD)));
      final lattice = line(const Color(0x669A6634), 0.4);
      for (final y in [-17.5, -13.5, -9.5]) {
        c.drawLine(Offset(1.2, y), Offset(7.3, y), lattice);
      }
      c.drawLine(const Offset(4.3, -21.3), const Offset(4.3, -5.2), lattice);
      c.drawRRect(sail, line(woodLine, 0.6));
      // spar
      final spar = RRect.fromRectAndRadius(const Rect.fromLTWH(-1, -23, 2, 22), const Radius.circular(1));
      c.drawRRect(spar, hGrad(spar.outerRect, const Color(0xFFC08A52), wood));
      c.drawRRect(spar, line(woodLine, 0.5));
      c.restore();
    }
    c.drawCircle(Offset.zero, 2.8, fill(woodLine));
    c.drawCircle(
      Offset.zero,
      2.2,
      Paint()..shader = Gradient.radial(const Offset(-0.7, -0.7), 2.8, [const Color(0xFFFFE08A), const Color(0xFFE59A1E)]),
    );
    c.drawCircle(const Offset(-0.7, -0.8), 0.6, fill(const Color(0xCCFFFFFF)));
  }

  // ------------------------------------------------------------- icons
  //
  // Icons are drawn in a box from -1 to 1 on both axes.

  static const _goldLine = Color(0xFFB0620C);

  static void coin(Canvas c) {
    // the coin edge gives it some thickness
    c.drawCircle(const Offset(0, 0.08), 0.9, fill(const Color(0xFFD8820E)));
    c.drawCircle(
      Offset.zero,
      0.88,
      Paint()..shader = Gradient.radial(const Offset(-0.3, -0.35), 1.2, [const Color(0xFFFFF29A), const Color(0xFFFFC52E), const Color(0xFFF09A12)], [0, 0.55, 1]),
    );
    c.drawCircle(const Offset(0, 0.04), 0.9, line(_goldLine, 0.1));
    c.drawCircle(Offset.zero, 0.6, line(const Color(0xFFE08A10), 0.1));
    c.drawCircle(const Offset(0, 0.05), 0.6, line(const Color(0x66FFF6C8), 0.06));
    // embossed star in the middle
    final star = _starPath(0.36, 0.17);
    c.drawPath(star.shift(const Offset(0, 0.04)), fill(const Color(0xFFD9850F)));
    c.drawPath(star, fill(const Color(0xFFFFE36A)));
    gloss(c, const Rect.fromLTWH(-0.62, -0.78, 0.8, 0.5), alpha: 0.75);
  }

  static Path _starPath(double outer, double inner) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -pi / 2 + i * pi / 5;
      final o = Offset(cos(a) * r, sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  static void star(Canvas c) {
    final s = _starPath(0.98, 0.5).shift(const Offset(0, 0.06));
    c.drawPath(s.shift(const Offset(0, 0.08)), fill(const Color(0x33000000)));
    c.drawPath(s, line(_goldLine, 0.22));
    c.drawPath(
      s,
      Paint()..shader = Gradient.radial(const Offset(-0.2, -0.3), 1.2, [const Color(0xFFFFF4A0), const Color(0xFFFFC72C), const Color(0xFFF29111)], [0, 0.5, 1]),
    );
    c.drawPath(s, line(const Color(0xFFD27A0D), 0.05));
    c.drawOval(const Rect.fromLTWH(-0.35, -0.6, 0.32, 0.42), fill(const Color(0xAAFFFFFF)));
  }

  static void gem(Canvas c) {
    final outline = Path()
      ..moveTo(-0.9, -0.28)
      ..lineTo(-0.48, -0.78)
      ..lineTo(0.48, -0.78)
      ..lineTo(0.9, -0.28)
      ..lineTo(0, 0.9)
      ..close();
    c.drawPath(outline.shift(const Offset(0, 0.08)), fill(const Color(0x33000000)));
    shape(
      c,
      outline,
      vGrad(const Rect.fromLTWH(-1, -0.8, 2, 1.7), const Color(0xFF8CF5D2), const Color(0xFF14A37A)),
      const Color(0xFF0B6B4F),
      0.12,
    );
    // facets
    final top = Path()
      ..moveTo(-0.9, -0.28)
      ..lineTo(-0.48, -0.78)
      ..lineTo(0.48, -0.78)
      ..lineTo(0.9, -0.28)
      ..close();
    c.drawPath(top, fill(const Color(0x66FFFFFF)));
    final f = line(const Color(0x88FFFFFF), 0.05);
    c.drawLine(const Offset(-0.9, -0.28), const Offset(0.9, -0.28), f);
    c.drawLine(const Offset(-0.25, -0.28), const Offset(0, 0.9), f);
    c.drawLine(const Offset(0.25, -0.28), const Offset(0, 0.9), f);
    c.drawLine(const Offset(-0.25, -0.28), const Offset(-0.1, -0.78), f);
    c.drawLine(const Offset(0.25, -0.28), const Offset(0.1, -0.78), f);
    final shine = Path()
      ..moveTo(-0.62, -0.22)
      ..lineTo(-0.32, -0.22)
      ..lineTo(-0.05, 0.55)
      ..close();
    c.drawPath(shine, fill(const Color(0x99FFFFFF)));
  }

  static void barnIcon(Canvas c) {
    c.drawOval(const Rect.fromLTWH(-0.9, 0.78, 1.8, 0.22), fill(const Color(0x33000000)));
    c.save();
    c.translate(-0.78, -0.92);
    c.scale(1.56 / 48, 1.78 / 64);
    barnFront(c);
    c.restore();
  }

  static void windmillIcon(Canvas c) {
    c.save();
    c.translate(-0.66, -0.55);
    c.scale(1.32 / 32);
    windmillTower(c);
    c.translate(16, 13);
    c.rotate(0.4);
    windmillSails(c);
    c.restore();
  }

  static void scroll(Canvas c) {
    const paper = Rect.fromLTWH(-0.62, -0.72, 1.24, 1.44);
    c.drawRect(paper.shift(const Offset(0.05, 0.08)), fill(const Color(0x33000000)));
    shape(c, Path()..addRect(paper), hGrad(paper, const Color(0xFFFFF8E2), const Color(0xFFF0D9A4)), const Color(0xFF8A5528), 0.08);
    final ink = line(const Color(0xFFB98A5A), 0.08);
    for (final y in [-0.4, -0.15, 0.1, 0.35]) {
      c.drawLine(Offset(-0.4, y), Offset(y == 0.35 ? 0.1 : 0.4, y), ink);
    }
    // rolls at the top and bottom
    for (final y in [-0.78, 0.78]) {
      final roll = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, y), width: 1.56, height: 0.34),
        const Radius.circular(0.17),
      );
      c.drawRRect(roll, vGrad(roll.outerRect, const Color(0xFFE6B877), const Color(0xFFB57A3C)));
      c.drawRRect(roll, line(const Color(0xFF7A4520), 0.08));
      c.drawLine(Offset(-0.6, y - 0.07), Offset(0.6, y - 0.07), line(const Color(0x77FFFFFF), 0.06));
    }
    // red wax seal
    c.drawCircle(const Offset(0.36, 0.38), 0.2, fill(const Color(0xFFD8352A)));
    c.drawCircle(const Offset(0.31, 0.33), 0.07, fill(const Color(0xAAFFFFFF)));
  }

  static void stall(Canvas c) {
    c.drawOval(const Rect.fromLTWH(-0.9, 0.8, 1.8, 0.2), fill(const Color(0x33000000)));
    const wood = Color(0xFFC98A4B);
    const woodLine = Color(0xFF6B3F1C);
    // posts
    for (final x in [-0.72, 0.6]) {
      final post = Rect.fromLTWH(x, -0.4, 0.12, 1.2);
      c.drawRect(post, fill(wood));
      c.drawRect(post, line(woodLine, 0.05));
    }
    // counter with produce
    const counter = Rect.fromLTWH(-0.88, 0.25, 1.76, 0.62);
    shape(c, Path()..addRRect(RRect.fromRectAndRadius(counter, const Radius.circular(0.08))), vGrad(counter, const Color(0xFFE2A866), const Color(0xFFAE6E35)), woodLine, 0.08);
    c.drawLine(const Offset(-0.85, 0.5), const Offset(0.85, 0.5), line(const Color(0x446B3F1C), 0.05));
    for (final (x, col) in [(-0.45, const Color(0xFFF2463A)), (0.0, const Color(0xFFFFC233)), (0.45, const Color(0xFF7BD045))]) {
      c.drawCircle(Offset(x, 0.16), 0.2, fill(col));
      c.drawCircle(Offset(x, 0.16), 0.2, line(const Color(0x66000000), 0.04));
      c.drawCircle(Offset(x - 0.06, 0.09), 0.06, fill(const Color(0xBBFFFFFF)));
    }
    // striped scalloped awning
    final awning = Path()
      ..moveTo(-0.95, -0.38)
      ..lineTo(-0.75, -0.88)
      ..lineTo(0.75, -0.88)
      ..lineTo(0.95, -0.38);
    for (var i = 4; i >= 0; i--) {
      final x = 0.95 - i * 0.38;
      awning.arcToPoint(Offset(x - 0.38, -0.38), radius: const Radius.circular(0.19));
    }
    awning.close();
    c.save();
    c.clipPath(awning);
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(-0.95 + i * 0.38, -1, 0.38, 1), fill(i.isEven ? const Color(0xFFEE4B3B) : const Color(0xFFFFFBF2)));
    }
    gloss(c, const Rect.fromLTWH(-0.9, -0.9, 1.8, 0.5), alpha: 0.45);
    c.restore();
    c.drawPath(awning, line(const Color(0xFF7A1A12), 0.07));
  }

  static void bag(Canvas c) {
    c.drawOval(const Rect.fromLTWH(-0.8, 0.8, 1.6, 0.2), fill(const Color(0x33000000)));
    // handle
    final handle = Path()
      ..moveTo(-0.35, -0.35)
      ..cubicTo(-0.35, -1.0, 0.35, -1.0, 0.35, -0.35);
    c.drawPath(handle, line(const Color(0xFF7A3E14), 0.2));
    c.drawPath(handle, line(const Color(0xFFD98A3A), 0.1));
    final body = Path()
      ..moveTo(-0.72, -0.4)
      ..lineTo(0.72, -0.4)
      ..lineTo(0.84, 0.82)
      ..quadraticBezierTo(0.84, 0.9, 0.76, 0.9)
      ..lineTo(-0.76, 0.9)
      ..quadraticBezierTo(-0.84, 0.9, -0.84, 0.82)
      ..close();
    shape(c, body, vGrad(const Rect.fromLTWH(-0.84, -0.4, 1.68, 1.3), const Color(0xFFFFA347), const Color(0xFFE0611C)), const Color(0xFF8A3A0E), 0.08);
    c.drawRect(const Rect.fromLTWH(-0.72, -0.4, 1.44, 0.2), fill(const Color(0x33FFFFFF)));
    // little coin badge on the bag
    c.save();
    c.translate(0, 0.28);
    c.scale(0.34);
    coin(c);
    c.restore();
    gloss(c, const Rect.fromLTWH(-0.66, -0.32, 0.4, 0.9), alpha: 0.45);
  }

  static void gift(Canvas c) {
    c.drawOval(const Rect.fromLTWH(-0.85, 0.82, 1.7, 0.18), fill(const Color(0x33000000)));
    const red = [Color(0xFFFF6A57), Color(0xFFD12D22)];
    const redLine = Color(0xFF7A1A12);
    const box = Rect.fromLTWH(-0.72, -0.2, 1.44, 1.1);
    shape(c, Path()..addRect(box), vGrad(box, red[0], red[1]), redLine, 0.08);
    const lid = Rect.fromLTWH(-0.86, -0.46, 1.72, 0.34);
    shape(c, Path()..addRRect(RRect.fromRectAndRadius(lid, const Radius.circular(0.08))), vGrad(lid, red[0], red[1]), redLine, 0.08);
    // ribbon
    final ribbon = vGrad(const Rect.fromLTWH(0, -0.5, 0, 1.4), const Color(0xFFFFE680), const Color(0xFFF2B21E));
    c.drawRect(const Rect.fromLTWH(-0.14, -0.46, 0.28, 1.36), ribbon);
    c.drawRect(const Rect.fromLTWH(-0.14, -0.46, 0.28, 1.36), line(const Color(0xFFB57514), 0.05));
    // bow
    for (final s in [-1.0, 1.0]) {
      final loop = Path()
        ..moveTo(0, -0.48)
        ..cubicTo(s * 0.3, -1.05, s * 0.8, -0.85, s * 0.5, -0.5)
        ..close();
      shape(c, loop, ribbon, const Color(0xFFB57514), 0.06);
    }
    c.drawCircle(const Offset(0, -0.5), 0.12, fill(const Color(0xFFFFD447)));
    gloss(c, const Rect.fromLTWH(-0.8, -0.44, 0.6, 0.2), alpha: 0.6);
    gloss(c, const Rect.fromLTWH(-0.64, -0.12, 0.3, 0.8), alpha: 0.35);
  }

  /// Icon names handled by [icon]; others still use the old sprites.
  static const Set<String> iconNames = {
    'coin', 'star', 'gem', 'barn', 'windmill', 'scroll', 'stall', 'bag', 'gift',
  };

  /// Draws the icon called [name] centered in [rect]. Returns false if
  /// there is no cartoon version yet.
  static bool icon(Canvas c, Rect rect, String name, {double opacity = 1}) {
    final draw = switch (name) {
      'coin' => coin,
      'star' => star,
      'gem' => gem,
      'barn' => barnIcon,
      'windmill' => windmillIcon,
      'scroll' => scroll,
      'stall' => stall,
      'bag' => bag,
      'gift' => gift,
      _ => null,
    };
    if (draw == null) return false;
    final k = min(rect.width, rect.height) / 2;
    layered(c, rect, null, opacity, () {
      c.save();
      c.translate(rect.center.dx, rect.center.dy);
      c.scale(k);
      draw(c);
      c.restore();
    });
    return true;
  }
}
