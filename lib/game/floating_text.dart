import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Short text (like "+3 🌾") that floats up and disappears.
class FloatingText extends TextComponent {
  FloatingText({
    required String text,
    required Vector2 start,
    required double fontSize,
    required Color color,
  }) : super(
          text: text,
          position: start.clone(),
          anchor: Anchor.center,
          priority: 10,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        );

  static const double _lifetime = 0.9;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 60 * dt;
    if (_age >= _lifetime) removeFromParent();
  }
}
