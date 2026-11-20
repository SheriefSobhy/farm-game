import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../art/palette.dart';
import '../art/sprites.dart';
import '../art/text_styles.dart';
import '../models/item.dart';
import 'farm_game.dart';
import 'farm_layout.dart';

/// One field plot (32x32 units): two soil beds with four plants.
/// Shows a "for sale" sign for the next plot and a lock for later ones.
class PlotComponent extends PositionComponent with TapCallbacks, HasGameReference<FarmGame> {
  PlotComponent({required this.index})
    : super(
        position: Vector2(
          FarmLayout.plotTopLeft(index).dx + FarmLayout.plotSize / 2,
          FarmLayout.plotTopLeft(index).dy + FarmLayout.plotSize / 2,
        ),
        size: Vector2.all(FarmLayout.plotSize),
        anchor: Anchor.center,
        priority: 0,
      );

  final int index;

  double _t = 0;
  double _press = 0;
  double _tilePop = 1;
  double _plantPop = 1;
  bool _initialized = false;
  bool _wasOwned = false;
  bool _wasPlanted = false;

  static final TextPaint _priceText = TextPaint(
    style: AppText.style(7, weight: 700, color: Palette.text),
  );

  void press() => _press = 1;

  @override
  void onTapDown(TapDownEvent event) => game.handlePlotTap(this);

  @override
  void update(double dt) {
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
    _tilePop = min(1, _tilePop + dt / 0.5);
    _plantPop = min(1, _plantPop + dt / 0.45);
    _press = max(0, _press - dt * 6);
    final pop = Curves.elasticOut.transform(_tilePop);
    final sc = (0.6 + 0.4 * pop) * (1 - 0.08 * _press);
    scale = Vector2(sc * (1 + 0.04 * _press), sc);
  }

  @override
  void render(Canvas canvas) {
    final s = game.state;
    final owned = index < s.plots.length;
    if (owned) {
      _renderOwned(canvas);
    } else if (index == s.plots.length) {
      _renderForSale(canvas, s.nextPlotPrice);
    } else {
      _renderLocked(canvas);
    }
  }

  void _beds(Canvas c, {required bool wet, double opacity = 1}) {
    for (final y in [0.0, 16.0]) {
      Art.at(c, wet ? S.bedLeftWet : S.bedLeftDry, 0, y, opacity: opacity);
      Art.at(c, wet ? S.bedRightWet : S.bedRightDry, 16, y, opacity: opacity);
    }
  }

  void _renderOwned(Canvas c) {
    final s = game.state;
    final plot = s.plots[index];
    final now = s.nowMs;
    _beds(c, wet: !plot.isEmpty);
    if (plot.isEmpty) return;

    final p = plot.progress(now);
    final stage = plot.isReady(now) ? 2 : (p < 0.5 ? 0 : 1);
    final sprite = (plot.crop == Item.corn ? S.cornStages : S.wheatStages)[stage];
    final grow = Curves.easeOutBack.transform(_plantPop);
    for (var k = 0; k < 4; k++) {
      final cx = (k % 2) * 16.0 + 8;
      final base = (k ~/ 2) * 16.0 + 13;
      c.save();
      c.translate(cx, base);
      if (stage == 2) {
        // ripe wheat sways in the breeze
        c.skew(sin(_t * 2.4 + index * 0.9 + k * 0.7) * 0.12, 0);
      }
      c.scale(grow, grow);
      Art.at(c, sprite, -8, -13);
      c.restore();
    }

    if (stage == 2) {
      // twinkling sparkles on ripe crops
      final tw = (_t * 1.6 + index * 0.37) % 1.0;
      if (tw < 0.5) {
        final a = sin(tw / 0.5 * pi);
        final sx = 6 + ((index * 7 + (_t * 1.6).floor() * 11) % 20).toDouble();
        final sy = 2 + ((index * 5 + (_t * 1.6).floor() * 7) % 20).toDouble();
        final paint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: a);
        c.drawRect(Rect.fromLTWH(sx, sy - 1, 1, 3), paint);
        c.drawRect(Rect.fromLTWH(sx - 1, sy, 3, 1), paint);
      }
    } else {
      // growth bar along the bottom edge
      const bar = Rect.fromLTWH(4, 28, 24, 4);
      c.drawRect(bar, Paint()..color = Palette.outline);
      c.drawRect(
        Rect.fromLTWH(bar.left + 1, bar.top + 1, (bar.width - 2) * p, bar.height - 2),
        Paint()..color = Palette.gold,
      );
    }
  }

  void _renderForSale(Canvas c, int price) {
    _beds(c, wet: false, opacity: 0.35);
    final bob = sin(_t * 3 + index) * 1.0;
    // a little price sign with a plus badge
    const sign = Rect.fromLTWH(3, 9, 26, 13);
    c.save();
    c.translate(0, bob);
    c.drawRect(sign.inflate(1), Paint()..color = Palette.outline);
    c.drawRect(sign, Paint()..color = Palette.cream);
    c.drawRect(
      Rect.fromLTWH(sign.left, sign.bottom - 2, sign.width, 2),
      Paint()..color = Palette.paperDark,
    );
    c.drawRect(const Rect.fromLTWH(15, 22, 2, 8), Paint()..color = Palette.outline);
    Art.draw(c, S.coin, const Rect.fromLTWH(4, 11, 9, 9));
    _priceText.render(c, '$price', Vector2(21, 15.5), anchor: Anchor.center);
    Art.draw(c, S.plus, const Rect.fromLTWH(20, 0, 12, 12));
    c.restore();
  }

  void _renderLocked(Canvas c) {
    Art.at(c, S.grassTufts, 0, 0, opacity: 0.8);
    Art.at(c, S.grassTufts, 16, 16, opacity: 0.8);
    Art.draw(c, S.lock, const Rect.fromLTWH(9, 9, 14, 14), opacity: 0.75);
  }
}
