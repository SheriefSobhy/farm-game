import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';

final Random _rnd = Random();

/// Golden grains and straw bursting out of a harvested plot.
ParticleSystemComponent grainBurst(Vector2 at, double cell) {
  return ParticleSystemComponent(
    position: at.clone(),
    priority: 20,
    particle: Particle.generate(
      count: 18,
      lifespan: 0.9,
      generator: (i) {
        final a = _rnd.nextDouble() * 2 * pi;
        final speed = cell * (0.8 + _rnd.nextDouble() * 1.4);
        final spin = (_rnd.nextDouble() - 0.5) * 14;
        final s = cell * (0.04 + _rnd.nextDouble() * 0.03);
        final straw = i % 4 == 0;
        return AcceleratedParticle(
          speed: Vector2(cos(a) * speed, sin(a) * speed - cell * 1.3),
          acceleration: Vector2(0, cell * 5.5),
          child: ComputedParticle(renderer: (c, p) {
            final o = (1 - p.progress * p.progress).clamp(0.0, 1.0);
            c.save();
            c.rotate(spin * p.progress);
            if (straw) {
              c.drawLine(
                Offset(-s * 1.6, 0),
                Offset(s * 1.6, 0),
                Paint()
                  ..color = Palette.wheatDark.withValues(alpha: o)
                  ..strokeWidth = s * 0.45
                  ..strokeCap = StrokeCap.round,
              );
            } else {
              final r = Rect.fromCenter(center: Offset.zero, width: s, height: s * 1.7);
              c.drawOval(r.inflate(s * 0.18), Paint()..color = Palette.wheatDark.withValues(alpha: o));
              c.drawOval(r, Paint()..color = Palette.wheat.withValues(alpha: o));
            }
            c.restore();
          }),
        );
      },
    ),
  );
}

/// Little clods of dirt hopping up when a seed is planted.
ParticleSystemComponent dirtPuff(Vector2 at, double cell) {
  return ParticleSystemComponent(
    position: at.clone(),
    priority: 20,
    particle: Particle.generate(
      count: 10,
      lifespan: 0.5,
      generator: (i) {
        final a = -pi / 2 + (_rnd.nextDouble() - 0.5) * 2.2;
        final speed = cell * (0.6 + _rnd.nextDouble() * 0.8);
        final r = cell * (0.02 + _rnd.nextDouble() * 0.025);
        return AcceleratedParticle(
          position: Vector2((_rnd.nextDouble() - 0.5) * cell * 0.5, cell * 0.1),
          speed: Vector2(cos(a) * speed, sin(a) * speed),
          acceleration: Vector2(0, cell * 4),
          child: ComputedParticle(renderer: (c, p) {
            c.drawCircle(Offset.zero, r * (1 - p.progress * 0.5),
                Paint()..color = Palette.soilDark.withValues(alpha: 1 - p.progress));
          }),
        );
      },
    ),
  );
}

/// Golden sparkles when a new plot is bought.
ParticleSystemComponent sparkleBurst(Vector2 at, double cell) {
  return ParticleSystemComponent(
    position: at.clone(),
    priority: 20,
    particle: Particle.generate(
      count: 14,
      lifespan: 0.7,
      generator: (i) {
        final a = i * 2 * pi / 14;
        final speed = cell * 1.1;
        return AcceleratedParticle(
          speed: Vector2(cos(a) * speed, sin(a) * speed),
          acceleration: Vector2(cos(a), sin(a)) * (-cell * 1.2),
          child: ComputedParticle(renderer: (c, p) {
            final s = cell * 0.05 * (1 - p.progress);
            final paint = Paint()..color = Palette.goldLight.withValues(alpha: 1 - p.progress);
            c.drawPath(
              Path()
                ..moveTo(0, -s * 2)
                ..lineTo(s * 0.5, -s * 0.5)
                ..lineTo(s * 2, 0)
                ..lineTo(s * 0.5, s * 0.5)
                ..lineTo(0, s * 2)
                ..lineTo(-s * 0.5, s * 0.5)
                ..lineTo(-s * 2, 0)
                ..lineTo(-s * 0.5, -s * 0.5)
                ..close(),
              paint,
            );
          }),
        );
      },
    ),
  );
}

/// "+3 [wheat]" or "-5 [coin]" that pops, floats up and fades out.
class FloatingLabel extends PositionComponent {
  FloatingLabel({
    required this.text,
    required this.icon,
    required Vector2 start,
    required this.fontSize,
  }) : super(position: start.clone(), anchor: Anchor.center, priority: 30) {
    _startY = start.y;
    _paint = TextPaint(style: AppText.light(fontSize, weight: 700));
  }

  final String text;
  final GameIconType icon;
  final double fontSize;
  late final double _startY;
  late final TextPaint _paint;
  double _age = 0;

  static const double _life = 1.0;

  @override
  void update(double dt) {
    _age += dt;
    final k = Curves.easeOutCubic.transform((_age / _life).clamp(0.0, 1.0));
    position.y = _startY - fontSize * 2.6 * k;
    if (_age >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = _age < _life * 0.6 ? 1.0 : 1 - (_age - _life * 0.6) / (_life * 0.4);
    final pop = Curves.elasticOut.transform((_age / 0.4).clamp(0.0, 1.0));
    final metrics = _paint.getLineMetrics(text);
    final iconSize = fontSize * 1.25;
    final total = metrics.width + iconSize * 1.1;

    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, fade.clamp(0.0, 1.0)));
    canvas.scale(pop, pop);
    _paint.render(canvas, text, Vector2(-total / 2, 0), anchor: Anchor.centerLeft);
    paintGameIcon(
      canvas,
      Rect.fromCenter(
        center: Offset(-total / 2 + metrics.width + iconSize * 0.6, 0),
        width: iconSize,
        height: iconSize,
      ),
      icon,
    );
    canvas.restore();
  }
}
