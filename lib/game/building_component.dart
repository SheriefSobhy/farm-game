import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';

import '../art/palette.dart';
import '../art/sprites.dart';
import '../art/text_styles.dart';
import '../models/production_building.dart';
import 'farm_game.dart';
import 'farm_layout.dart';

/// Washed-out colors for buildings the player doesn't own yet.
final Paint _fadedPaint = Paint()
  ..filterQuality = FilterQuality.none
  ..colorFilter = const ColorFilter.matrix(<double>[
    0.45, 0.35, 0.1, 0, 40, //
    0.25, 0.55, 0.1, 0, 40, //
    0.25, 0.35, 0.3, 0, 40, //
    0, 0, 0, 0.85, 0, //
  ]);

/// A building placed on the farm. Tapping it opens its panel.
class BuildingComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FarmGame> {
  BuildingComponent(this.spot)
    : super(
        position: Vector2(
          FarmLayout.spots[spot]!.left,
          FarmLayout.spots[spot]!.top,
        ),
        size: Vector2(
          FarmLayout.spots[spot]!.width,
          FarmLayout.spots[spot]!.height,
        ),
        priority: FarmLayout.spots[spot]!.bottom.toInt(),
      );

  final FarmSpot spot;

  double _t = 0;
  double _press = 0;
  double _angle = 0.4;
  double _speed = 0;
  double _smokeTimer = 0;

  static final TextPaint _signText = TextPaint(
    style: AppText.style(6.5, weight: 700),
  );

  ProductionBuilding? get _building => switch (spot) {
    FarmSpot.mill => game.state.mill,
    FarmSpot.oven => game.state.oven,
    _ => null,
  };

  @override
  void onTapDown(TapDownEvent event) {
    _press = 1;
    game.openSpot(spot);
  }

  @override
  void update(double dt) {
    _t += dt;
    _press = max(0, _press - dt * 5);
    final b = _building;
    final working = b != null && b.owned && b.isWorking;
    if (spot == FarmSpot.mill) {
      final target = working ? 5.0 : (b?.owned == true ? 0.35 : 0.0);
      _speed += (target - _speed) * min(1.0, dt * 2);
      _angle += _speed * dt;
    }
    if (spot == FarmSpot.oven && working) {
      _smokeTimer -= dt;
      if (_smokeTimer <= 0) {
        _smokeTimer = 0.28;
        _puff();
      }
    }
  }

  void _puff() {
    final rnd = Random();
    final start =
        position +
        Vector2(FarmLayout.ovenChimney.dx, FarmLayout.ovenChimney.dy);
    game.world.add(
      ParticleSystemComponent(
        position: start,
        priority: 900,
        particle: AcceleratedParticle(
          speed: Vector2(3 + rnd.nextDouble() * 4, -12 - rnd.nextDouble() * 4),
          acceleration: Vector2(2, 0),
          lifespan: 1.6,
          child: ComputedParticle(
            lifespan: 1.6,
            renderer: (c, p) {
              final s = 2 + p.progress * 4;
              c.drawRect(
                Rect.fromCenter(center: Offset.zero, width: s, height: s),
                Paint()
                  ..color = Palette.smoke.withValues(
                    alpha: 0.85 * (1 - p.progress),
                  ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // a small squash when tapped
    final sq = _press * 0.06;
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(1 + sq, 1 - sq);
    canvas.translate(-size.x / 2, -size.y);

    final b = _building;
    final owned = b?.owned ?? true;
    final paint = owned ? null : _fadedPaint;

    switch (spot) {
      case FarmSpot.barn:
        Art.barn(canvas, 0, 0);
      case FarmSpot.market:
        Art.at(canvas, S.stall, 0, 0);
        Art.at(canvas, S.wheatCrate, 4, 14);
        Art.at(canvas, S.sack, 18, 14);
        Art.at(canvas, S.bread, 30, 15);
      case FarmSpot.mill:
        Art.at(canvas, S.windmillTower, 0, 0, paint: paint);
        canvas.save();
        canvas.translate(FarmLayout.millHub.dx, FarmLayout.millHub.dy);
        canvas.rotate(_angle);
        Art.at(canvas, S.windmillBlades, -24, -24, paint: paint);
        canvas.restore();
      case FarmSpot.oven:
        Art.at(canvas, S.oven, 0, 0, paint: paint);
        if (b != null && b.owned && b.isWorking) _fire(canvas);
    }
    canvas.restore();

    if (b != null && !owned) _forSaleSign(canvas, b.recipe.price);
    if (b != null && owned && b.isWorking) {
      _progressBar(canvas, b.progress(game.state.nowMs));
    }
  }

  void _fire(Canvas c) {
    const m = FarmLayout.ovenMouth;
    final flick = sin(_t * 18) * 0.5 + 0.5;
    c.drawRect(
      Rect.fromLTWH(m.left + 1, m.bottom - 6, m.width - 2, 5),
      Paint()..color = Palette.fireDark,
    );
    for (var i = 0; i < 4; i++) {
      final h = 3 + ((sin(_t * 14 + i * 1.9) + 1) * 2.5).roundToDouble();
      c.drawRect(
        Rect.fromLTWH(m.left + 2 + i * 3, m.bottom - 2 - h, 2, h),
        Paint()..color = i.isEven ? Palette.fire : Palette.red,
      );
    }
    c.drawRect(
      Rect.fromLTWH(m.left - 2, m.top - 2, m.width + 4, m.height + 4),
      Paint()..color = Palette.fire.withValues(alpha: 0.12 + 0.1 * flick),
    );
  }

  void _forSaleSign(Canvas c, int price) {
    final bob = sin(_t * 2.5) * 1.0;
    final r = Rect.fromLTWH(size.x / 2 - 17, size.y - 16 + bob, 34, 12);
    c.drawRect(r.inflate(1), Paint()..color = Palette.outline);
    c.drawRect(r, Paint()..color = Palette.cream);
    Art.draw(c, S.coin, Rect.fromLTWH(r.left + 2, r.top + 2, 8, 8));
    _signText.render(
      c,
      '$price',
      Vector2(r.left + 21, r.center.dy),
      anchor: Anchor.center,
    );
  }

  void _progressBar(Canvas c, double p) {
    final r = Rect.fromLTWH(
      size.x / 2 - 13,
      spot == FarmSpot.mill ? -18 : -7,
      26,
      5,
    );
    c.drawRect(r, Paint()..color = Palette.outline);
    c.drawRect(
      Rect.fromLTWH(r.left + 1, r.top + 1, (r.width - 2) * p, r.height - 2),
      Paint()..color = Palette.gold,
    );
  }
}
