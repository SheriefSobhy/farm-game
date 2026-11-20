import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';

final Random _rnd = Random();

/// Square "pixel" particles flying out from [at] (world units).
ParticleSystemComponent pixelBurst(
  Vector2 at, {
  required List<Color> colors,
  int count = 16,
  double speed = 40,
  double gravity = 120,
  double life = 0.8,
  double up = 30,
  double size = 2,
}) {
  return ParticleSystemComponent(
    position: at.clone(),
    priority: 1000,
    particle: Particle.generate(
      count: count,
      lifespan: life,
      generator: (i) {
        final a = _rnd.nextDouble() * 2 * pi;
        final v = speed * (0.5 + _rnd.nextDouble() * 0.8);
        final color = colors[i % colors.length];
        final s = size * (0.8 + _rnd.nextDouble() * 0.6);
        return AcceleratedParticle(
          speed: Vector2(cos(a) * v, sin(a) * v - up),
          acceleration: Vector2(0, gravity),
          child: ComputedParticle(
            renderer: (c, p) {
              final o = (1 - p.progress * p.progress).clamp(0.0, 1.0);
              c.drawRect(
                Rect.fromCenter(center: Offset.zero, width: s + 1, height: s + 1),
                Paint()..color = Palette.outline.withValues(alpha: o),
              );
              c.drawRect(
                Rect.fromCenter(center: Offset.zero, width: s, height: s),
                Paint()..color = color.withValues(alpha: o),
              );
            },
          ),
        );
      },
    ),
  );
}

/// Golden grains bursting out of a harvested plot.
ParticleSystemComponent grainBurst(Vector2 at) =>
    pixelBurst(at, colors: const [Palette.gold, Palette.goldDark, Color(0xFFF7C282)], count: 18);

/// Little clods of dirt hopping up when seeds are planted.
ParticleSystemComponent dirtPuff(Vector2 at) => pixelBurst(
  at,
  colors: const [Palette.soil, Palette.soilDark, Color(0xFFCF8254)],
  count: 10,
  speed: 22,
  up: 24,
  life: 0.5,
  size: 1.6,
);

/// Golden sparkles when something new is bought.
ParticleSystemComponent sparkleBurst(Vector2 at) => pixelBurst(
  at,
  colors: const [Color(0xFFFFFFFF), Palette.gold, Palette.goldLight],
  count: 20,
  speed: 50,
  gravity: 20,
  up: 10,
  life: 0.8,
);

/// "+3 [wheat]" or "-5 [coin]" that pops, floats up and fades out.
class FloatingLabel extends PositionComponent {
  FloatingLabel({required this.text, required this.icon, required Vector2 start, this.fontSize = 9})
    : super(position: start.clone(), anchor: Anchor.center, priority: 1100) {
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
    position.y = _startY - fontSize * 2.4 * k;
    if (_age >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = _age < _life * 0.6 ? 1.0 : 1 - (_age - _life * 0.6) / (_life * 0.4);
    final pop = Curves.elasticOut.transform((_age / 0.4).clamp(0.0, 1.0));
    final metrics = _paint.getLineMetrics(text);
    final iconSize = fontSize * 1.3;
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
