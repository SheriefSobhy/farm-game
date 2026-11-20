import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../art/sprites.dart';

/// An animal that strolls around inside [area], hopping a little while it
/// walks and pausing now and then.
class AnimalComponent extends PositionComponent {
  AnimalComponent({required this.sprite, required this.area, int seed = 0})
    : _rnd = Random(seed),
      super(size: Vector2.all(16), anchor: Anchor.bottomCenter) {
    position = Vector2(
      area.left + _rnd.nextDouble() * area.width,
      area.top + _rnd.nextDouble() * area.height,
    );
    _pickTarget();
  }

  final Spr sprite;
  final Rect area;
  final Random _rnd;

  late Vector2 _target;
  double _wait = 0;
  double _t = 0;
  bool _facingLeft = false;

  void _pickTarget() {
    _target = Vector2(
      area.left + _rnd.nextDouble() * area.width,
      area.top + _rnd.nextDouble() * area.height,
    );
  }

  @override
  void update(double dt) {
    priority = position.y.toInt();
    if (_wait > 0) {
      _wait -= dt;
      return;
    }
    _t += dt;
    final d = _target - position;
    if (d.length < 1) {
      _wait = 1 + _rnd.nextDouble() * 3;
      _pickTarget();
      return;
    }
    if (d.x.abs() > 0.5) _facingLeft = d.x < 0;
    position += d.normalized() * (8 * dt);
  }

  @override
  void render(Canvas canvas) {
    final hop = _wait > 0 ? 0.0 : (sin(_t * 12).abs() * 1.5).roundToDouble();
    canvas.save();
    if (_facingLeft) {
      canvas.translate(16, 0);
      canvas.scale(-1, 1);
    }
    Art.at(canvas, sprite, 0, -hop);
    canvas.restore();
  }
}
