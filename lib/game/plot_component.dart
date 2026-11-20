import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../art/farm_art.dart';
import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../art/wheat_art.dart';
import '../game_config.dart';
import 'farm_game.dart';

/// One square of the 3x3 field. Drawn as tilled soil (owned), a "buy me"
/// tile with its price (the next plot), or wild grass with a lock sign.
class PlotComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FarmGame> {
  PlotComponent({required this.index}) : super(anchor: Anchor.center);

  final int index;

  double _t = 0;
  double _press = 0;
  double _tilePop = 1;
  double _plantPop = 1;
  bool _initialized = false;
  bool _wasOwned = false;
  bool _wasPlanted = false;

  TextPaint _label = TextPaint();
  TextPaint _tagText = TextPaint();
  final List<Offset> _pebbles = [];
  final List<Offset> _tufts = [];

  /// Small squash when tapped.
  void press() => _press = 1;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final l = game.layout;
    position = l.cellCenter(index);
    this.size = Vector2.all(l.cell);
    final cell = l.cell;
    _label = TextPaint(style: AppText.light(cell * 0.11, weight: 650));
    _tagText = TextPaint(style: AppText.style(cell * 0.12, weight: 650));

    final rnd = Random(index * 31 + 7);
    _pebbles
      ..clear()
      ..addAll(List.generate(
          5, (_) => Offset(0.12 + rnd.nextDouble() * 0.76, 0.12 + rnd.nextDouble() * 0.76)));
    _tufts
      ..clear()
      ..addAll(List.generate(
          7, (_) => Offset(0.12 + rnd.nextDouble() * 0.76, 0.2 + rnd.nextDouble() * 0.7)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final s = game.state;
    final owned = index < s.plots.length;
    final planted = owned && !s.plots[index].isEmpty;
    if (_initialized) {
      if (owned && !_wasOwned) _tilePop = 0;
      if (planted && !_wasPlanted) _plantPop = 0;
    }
    _initialized = true;
    _wasOwned = owned;
    _wasPlanted = planted;

    _tilePop = min(1, _tilePop + dt / 0.6);
    _plantPop = min(1, _plantPop + dt / 0.55);
    _press = max(0, _press - dt * 6);

    var sc = 1 - 0.07 * _press;
    if (_tilePop < 1) sc *= Curves.elasticOut.transform(_tilePop);
    if (index == s.plots.length) sc *= 1 + 0.025 * sin(_t * 3);
    scale.setAll(sc);
  }

  @override
  void onTapDown(TapDownEvent event) => game.handlePlotTap(this);

  // ---------------------------------------------------------------- render

  RRect get _shape =>
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), Radius.circular(size.x * 0.17));

  @override
  void render(Canvas canvas) {
    final s = game.state;
    if (index < s.plots.length) {
      _renderOwned(canvas);
    } else if (index == s.plots.length) {
      _renderBuyable(canvas);
    } else {
      _renderLocked(canvas);
    }
  }

  void _shadow(Canvas c) {
    c.drawRRect(_shape.shift(Offset(0, size.y * 0.05)), Paint()..color = const Color(0x40331A08));
  }

  void _renderOwned(Canvas c) {
    final w = size.x;
    final h = size.y;
    final u = w / 100;
    final rr = _shape;
    _shadow(c);
    c.drawRRect(rr.inflate(u * 1.2), Paint()..color = Palette.soilDeep);
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.soilLight, Palette.soil],
        ).createShader(rr.outerRect),
    );

    final rowsY = [h * 0.28, h * 0.51, h * 0.74];
    for (final cy in rowsY) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.1, cy + h * 0.04, w * 0.9, cy + h * 0.1),
            Radius.circular(h * 0.03)),
        Paint()..color = const Color(0x88553118),
      );
      final ridge = RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.09, cy - h * 0.065, w * 0.91, cy + h * 0.055),
          Radius.circular(h * 0.06));
      c.drawRRect(
        ridge,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC79466), Palette.soil],
          ).createShader(ridge.outerRect),
      );
    }
    final pebble = Paint()..color = const Color(0x667A4A2A);
    for (final p in _pebbles) {
      c.drawOval(Rect.fromCenter(center: Offset(p.dx * w, p.dy * h), width: u * 2.6, height: u * 1.8),
          pebble);
    }

    final plot = game.state.plots[index];
    final now = game.state.nowMs;

    if (plot.isEmpty) {
      _tag(c, Offset(w / 2, h * 0.5), 'Plant ${GameConfig.wheatSeedCost}', GameIconType.coin);
      return;
    }

    final progress = plot.progress(now);
    final ripe = progress >= 1;

    if (ripe) {
      final glow = 0.55 + 0.45 * sin(_t * 4);
      c.drawRRect(
        rr.inflate(u * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 4
          ..color = Palette.goldLight.withValues(alpha: glow),
      );
    }

    // Plants, back row first. They pop in with a bounce after planting.
    final pop = Curves.elasticOut.transform(_plantPop);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final base = Offset(w * (0.25 + col * 0.25), rowsY[row] + h * 0.01);
        c.save();
        c.translate(base.dx, base.dy);
        c.scale(pop, pop);
        c.translate(-base.dx, -base.dy);
        if (ripe) {
          final sway = sin(_t * 2.2 + col * 0.8 + row * 1.4) * 0.13;
          drawRipeWheat(c, base, u, sway);
        } else if (progress < 0.35) {
          drawSprout(c, base, u, progress / 0.35);
        } else {
          final sway = sin(_t * 1.8 + col + row) * 0.04;
          drawYoungWheat(c, base, u, (progress - 0.35) / 0.65, sway);
        }
        c.restore();
      }
    }

    if (ripe) {
      _sparkle(c, Offset(w * 0.84, h * 0.14), u * (3 + 2 * sin(_t * 5).abs()));
      _sparkle(c, Offset(w * 0.16, h * 0.2), u * (2 + 2 * sin(_t * 4 + 1).abs()));
      return;
    }

    // Growth progress bar
    final bar = Rect.fromLTWH(w * 0.12, h * 0.85, w * 0.76, h * 0.105);
    final radius = Radius.circular(bar.height / 2);
    c.drawRRect(RRect.fromRectAndRadius(bar.inflate(u * 1.2), radius), Paint()..color = Palette.outline);
    c.drawRRect(RRect.fromRectAndRadius(bar, radius), Paint()..color = const Color(0xFF5E3A20));
    if (progress > 0) {
      final fill = Rect.fromLTWH(bar.left, bar.top, max(bar.height, bar.width * progress), bar.height);
      c.drawRRect(
        RRect.fromRectAndRadius(fill, radius),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.leafLight, Palette.leaf],
          ).createShader(fill),
      );
    }
    final secs = (plot.remainingMs(now) / 1000).ceil();
    _label.render(c, '${secs}s', Vector2(bar.center.dx, bar.center.dy), anchor: Anchor.center);
  }

  void _renderBuyable(Canvas c) {
    final w = size.x;
    final h = size.y;
    final u = w / 100;
    final rr = _shape;
    _shadow(c);
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC2E890), Palette.grassLight],
        ).createShader(rr.outerRect),
    );
    _dashedBorder(c, rr.deflate(u * 4), u);
    paintGameIcon(
      c,
      Rect.fromCenter(center: Offset(w / 2, h * 0.4), width: w * 0.34, height: w * 0.34),
      GameIconType.plus,
    );
    _tag(c, Offset(w / 2, h * 0.78), '${game.state.nextPlotPrice}', GameIconType.coin, wood: true);
  }

  void _renderLocked(Canvas c) {
    final w = size.x;
    final h = size.y;
    final u = w / 100;
    final rr = _shape;
    _shadow(c);
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.grassDark, Palette.grassDeep],
        ).createShader(rr.outerRect),
    );
    for (final p in _tufts) {
      drawGrassTuft(c, Offset(p.dx * w, p.dy * h), h * 0.1, const Color(0xFF8BBF55));
    }
    drawFlower(c, Offset(w * 0.2, h * 0.78), u * 2.4, const Color(0xFFFFFFFF));
    drawFlower(c, Offset(w * 0.82, h * 0.3), u * 2.2, const Color(0xFFFFE27A));

    // Little wooden sign with a lock
    shape(c, rrectPath(w * 0.47, h * 0.5, w * 0.06, h * 0.32, u), color: Palette.woodDark, ow: u * 2);
    final board = rrectPath(w * 0.28, h * 0.3, w * 0.44, h * 0.27, u * 4);
    shape(c, board, color: Palette.woodLight, ow: u * 2.5);
    paintGameIcon(
      c,
      Rect.fromCenter(center: Offset(w / 2, h * 0.435), width: h * 0.2, height: h * 0.2),
      GameIconType.lock,
    );
  }

  // --------------------------------------------------------------- helpers

  /// A small paper (or wooden) tag showing "text + icon".
  void _tag(Canvas c, Offset center, String text, GameIconType icon, {bool wood = false}) {
    final u = size.x / 100;
    final paint = wood ? _label : _tagText;
    final m = paint.getLineMetrics(text);
    final iconSize = size.x * 0.16;
    final contentW = m.width + u * 2 + iconSize;
    final tag = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: contentW + u * 12, height: size.y * 0.2),
      Radius.circular(size.y * 0.1),
    );
    c.drawRRect(tag.inflate(u * 1.3), Paint()..color = wood ? Palette.woodDeep : const Color(0x995A3A22));
    c.drawRRect(tag, Paint()..color = wood ? Palette.wood : const Color(0xEEFFF8E7));
    final left = center.dx - contentW / 2;
    paint.render(c, text, Vector2(left, center.dy), anchor: Anchor.centerLeft);
    paintGameIcon(
      c,
      Rect.fromCenter(
        center: Offset(left + m.width + u * 2 + iconSize / 2, center.dy),
        width: iconSize,
        height: iconSize,
      ),
      icon,
    );
  }

  void _dashedBorder(Canvas c, RRect rr, double u) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 2.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xE6FFFFFF);
    final dash = u * 7;
    final gap = u * 5;
    for (final metric in (Path()..addRRect(rr)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        c.drawPath(metric.extractPath(d, min(d + dash, metric.length)), paint);
      }
    }
  }

  void _sparkle(Canvas c, Offset p, double s) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s * 2)
      ..lineTo(p.dx + s * 0.45, p.dy - s * 0.45)
      ..lineTo(p.dx + s * 2, p.dy)
      ..lineTo(p.dx + s * 0.45, p.dy + s * 0.45)
      ..lineTo(p.dx, p.dy + s * 2)
      ..lineTo(p.dx - s * 0.45, p.dy + s * 0.45)
      ..lineTo(p.dx - s * 2, p.dy)
      ..lineTo(p.dx - s * 0.45, p.dy - s * 0.45)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFFFFDE8));
  }
}
