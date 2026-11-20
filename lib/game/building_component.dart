import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/sprites.dart';
import '../art/text_styles.dart';
import '../models/defs.dart';
import '../models/production_building.dart';
import '../ui/widgets/icon_text.dart';
import 'farm_game.dart';
import 'farm_layout.dart';
import 'tutorial_arrow.dart';

/// Washed-out colors for buildings the player doesn't own yet.
final Paint fadedPaint = Paint()
  ..filterQuality = FilterQuality.none
  ..colorFilter = const ColorFilter.matrix(<double>[
    0.45, 0.35, 0.1, 0, 40, //
    0.25, 0.55, 0.1, 0, 40, //
    0.25, 0.35, 0.3, 0, 40, //
    0, 0, 0, 0.85, 0, //
  ]);

final TextPaint _signText = TextPaint(style: AppText.style(6.5, weight: 700));

/// A small cream sign with an icon and a text, e.g. [coin] 400 or [lock] Lv 3.
void drawSign(Canvas c, Offset center, GameIconType icon, String text) {
  final w = 14 + text.length * 4.0;
  final r = Rect.fromCenter(center: center, width: w, height: 12);
  c.drawRect(r.inflate(1), Paint()..color = Palette.outline);
  c.drawRect(r, Paint()..color = Palette.cream);
  paintGameIcon(c, Rect.fromLTWH(r.left + 2, r.top + 2, 8, 8), icon);
  _signText.render(
    c,
    text,
    Vector2(r.left + 11 + (w - 13) / 2, r.center.dy),
    anchor: Anchor.center,
  );
}

/// A speech bubble with an icon (and count) that bobs above things that are
/// ready to collect.
void drawBubble(Canvas c, Offset bottomCenter, GameIconType icon, double t, {int count = 0}) {
  final bob = (sin(t * 4) * 1.5).roundToDouble();
  final r = Rect.fromCenter(center: bottomCenter.translate(0, -9 + bob), width: 16, height: 15);
  c.drawRect(r.inflate(1), Paint()..color = Palette.outline);
  c.drawRect(r, Paint()..color = const Color(0xFFFFFFFF));
  c.drawRect(Rect.fromLTWH(r.center.dx - 1, r.bottom, 3, 2), Paint()..color = Palette.outline);
  paintGameIcon(c, r.deflate(1.5), icon);
  if (count > 0) drawBadge(c, Offset(r.right + 1, r.top), count);
}

/// A building placed on the farm. Tapping it opens its panel, or collects
/// finished goods when there are some.
class BuildingComponent extends PositionComponent with TapCallbacks, HasGameReference<FarmGame> {
  BuildingComponent(this.spot)
    : super(
        position: Vector2(FarmLayout.spots[spot]!.left, FarmLayout.spots[spot]!.top),
        size: Vector2(FarmLayout.spots[spot]!.width, FarmLayout.spots[spot]!.height),
        priority: FarmLayout.spots[spot]!.bottom.toInt(),
      );

  final FarmSpot spot;

  double _t = 0;
  double _press = 0;
  double _angle = 0.4;
  double _speed = 0;
  double _smokeTimer = 0;

  ProductionBuilding? get _building {
    final k = spot.building;
    return k == null ? null : game.state.buildings[k];
  }

  @override
  void onTapDown(TapDownEvent event) {
    _press = 1;
    game.tapSpot(spot);
  }

  @override
  void update(double dt) {
    _t += dt;
    _press = max(0, _press - dt * 5);
    final b = _building;
    final working = b != null && b.owned && b.isWorking(game.state.nowMs);
    if (spot == FarmSpot.mill) {
      final target = working ? 5.0 : (b?.owned == true ? 0.35 : 0.0);
      _speed += (target - _speed) * min(1.0, dt * 2);
      _angle += _speed * dt;
    }
    if (working && (spot == FarmSpot.oven || spot == FarmSpot.dairy)) {
      _smokeTimer -= dt;
      if (_smokeTimer <= 0) {
        _smokeTimer = 0.3;
        _puff(spot == FarmSpot.oven ? FarmLayout.ovenChimney : const Offset(22, 6));
      }
    }
  }

  void _puff(Offset from) {
    final rnd = Random();
    game.world.add(
      ParticleSystemComponent(
        position: position + Vector2(from.dx, from.dy),
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
                Paint()..color = Palette.smoke.withValues(alpha: 0.85 * (1 - p.progress)),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final state = game.state;
    final now = state.nowMs;
    final b = _building;
    final owned = b?.owned ?? true;
    final unlocked = b == null || state.isUnlocked(b.kind);
    final working = b != null && owned && b.isWorking(now);
    final paint = owned ? null : fadedPaint;

    // a small squash when tapped, plus a little shake while machines work
    final sq = _press * 0.06;
    final shake = working && (spot == FarmSpot.feedMill || spot == FarmSpot.popcorn)
        ? sin(_t * 40) * 0.4
        : 0.0;
    canvas.save();
    canvas.translate(size.x / 2 + shake, size.y);
    canvas.scale(1 + sq, 1 - sq);
    canvas.translate(-size.x / 2, -size.y);

    switch (spot) {
      case FarmSpot.barn:
        Art.barn(canvas, 0, 0);
      case FarmSpot.orders:
        _ordersBoard(canvas);
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
        if (working) _fire(canvas);
      case FarmSpot.popcorn:
        Art.at(canvas, S.popcornMachine, 0, 0, paint: paint);
        if (working) _popping(canvas);
      case FarmSpot.feedMill:
        Art.at(canvas, S.feedMill, 0, 0, paint: paint);
      case FarmSpot.dairy:
        Art.at(canvas, S.dairy, 0, 0, paint: paint);
      case FarmSpot.chickens:
      case FarmSpot.cows:
        break;
    }
    canvas.restore();

    if (spot == FarmSpot.orders) {
      final n = state.fillableOrders;
      if (n > 0) drawBadge(canvas, Offset(size.x - 3, 4), n);
    }
    if (b == null) return;
    final signAt = Offset(size.x / 2, size.y - 9);
    if (!unlocked) {
      drawSign(canvas, signAt, GameIconType.lock, 'Lv ${b.def.unlockLevel}');
    } else if (!owned) {
      drawSign(canvas, signAt, GameIconType.coin, '${b.def.price}');
    } else {
      final ready = b.ready(now);
      final top = spot == FarmSpot.mill ? -12.0 : -2.0;
      if (ready.isNotEmpty) {
        drawBubble(
          canvas,
          Offset(size.x / 2, top),
          itemIcon(ready.first.recipe.output),
          _t,
          count: ready.length,
        );
      } else if (working) {
        _progressBar(canvas, b.working(now)!.progress(now), top - 6);
      }
    }
  }

  void _ordersBoard(Canvas c) {
    Art.at(c, S.ordersBoard, 0, 0);
    final s = game.state;
    for (var i = 0; i < s.orders.length && i < 3; i++) {
      final o = s.orders[i];
      if (o.isWaiting(s.nowMs)) continue;
      final x = 5.0 + i * 12.5;
      final fillable = s.canFill(o);
      final wiggle = fillable ? (sin(_t * 6 + i) * 1).roundToDouble() : 0.0;
      Art.at(c, S.note, x, 9 + wiggle);
      paintGameIcon(c, Rect.fromLTWH(x + 2, 13 + wiggle, 8, 8), itemIcon(o.items.keys.first));
      if (fillable) {
        paintGameIcon(c, Rect.fromLTWH(x + 5, 18 + wiggle, 8, 8), GameIconType.check);
      }
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

  void _popping(Canvas c) {
    // kernels jumping inside the glass case
    for (var i = 0; i < 6; i++) {
      final p = (_t * 2.2 + i / 6) % 1.0;
      final x = 7 + (i * 5) % 16;
      final y = 21 - sin(p * pi) * 10;
      c.drawRect(Rect.fromLTWH(x.toDouble(), y, 2, 2), Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  void _progressBar(Canvas c, double p, double y) {
    final r = Rect.fromLTWH(size.x / 2 - 13, y, 26, 5);
    c.drawRect(r, Paint()..color = Palette.outline);
    c.drawRect(
      Rect.fromLTWH(r.left + 1, r.top + 1, (r.width - 2) * p, r.height - 2),
      Paint()..color = Palette.gold,
    );
  }
}

/// Fence pen with animals (chickens or cows). Tapping collects products and
/// feeds hungry animals, or opens the pen panel when there's nothing to do.
class PenComponent extends PositionComponent with TapCallbacks, HasGameReference<FarmGame> {
  PenComponent(this.kind, this.spot)
    : super(
        position: Vector2(FarmLayout.spots[spot]!.left, FarmLayout.spots[spot]!.top),
        size: Vector2(FarmLayout.spots[spot]!.width, FarmLayout.spots[spot]!.height),
        priority: FarmLayout.spots[spot]!.top.toInt() + 20,
      );

  final AnimalKind kind;
  final FarmSpot spot;

  @override
  void onTapDown(TapDownEvent event) => game.tapSpot(spot);

  @override
  void render(Canvas canvas) {
    final s = game.state;
    final pen = s.pens[kind]!;
    final unlocked = s.isAnimalUnlocked(kind);
    final empty = pen.animals.isEmpty;
    final paint = empty ? fadedPaint : null;
    if (kind == AnimalKind.chicken) {
      Art.at(canvas, S.coop, size.x - 36, 4, paint: paint);
      Art.at(canvas, S.feedTroughL, 10, 42);
      Art.at(canvas, S.feedTroughR, 26, 42);
    } else {
      Art.at(canvas, S.cowShed, size.x - 42, 4, paint: paint);
      Art.at(canvas, S.waterTroughL, 8, 42);
      Art.at(canvas, S.waterTroughR, 24, 42);
    }
    final signAt = Offset(size.x / 2 - 8, 30);
    if (!unlocked) {
      drawSign(canvas, signAt, GameIconType.lock, 'Lv ${pen.def.unlockLevel}');
    } else if (empty) {
      drawSign(canvas, signAt, GameIconType.coin, '${pen.def.price}');
    }
    final ready = pen.readyCount(s.nowMs);
    if (ready > 0) {
      drawBadge(canvas, Offset(size.x - (kind == AnimalKind.chicken ? 8 : 6), 6), ready);
    }
  }
}
