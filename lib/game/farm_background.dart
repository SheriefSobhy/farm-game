import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../art/farm_art.dart';
import '../art/palette.dart';
import 'farm_game.dart';

/// Sky, hills, farmhouse, trees, fence and flowers behind the plots.
class FarmBackground extends Component with HasGameReference<FarmGame> {
  FarmBackground() : super(priority: -10);

  double _t = 0;
  final List<(Offset, Color, double)> _flowers = [];
  final List<(Offset, double)> _tufts = [];

  static const _petals = [
    Color(0xFFFFFFFF),
    Color(0xFFFFB3C7),
    Color(0xFFFFE27A),
    Color(0xFFC9B6FF),
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final l = game.layout;
    final rnd = Random(11);
    _flowers.clear();
    _tufts.clear();
    final avoid = l.grid.inflate(12);
    final minY = l.topSpace * 0.84;
    for (var i = 0; i < 140 && (_flowers.length < 24 || _tufts.length < 36); i++) {
      final p = Offset(rnd.nextDouble() * l.width, minY + rnd.nextDouble() * (l.height - minY - 4));
      if (avoid.contains(p)) continue;
      if (i.isEven && _flowers.length < 24) {
        _flowers.add((p, _petals[rnd.nextInt(_petals.length)], 3.0 + rnd.nextDouble() * 2.5));
      } else if (_tufts.length < 36) {
        _tufts.add((p, 6 + rnd.nextDouble() * 6));
      }
    }
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final l = game.layout;
    final w = l.width;
    final h = l.height;
    final skyBottom = l.topSpace * 0.42;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.grassLight, Palette.grass, Palette.grassDark],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    drawSky(canvas, Rect.fromLTWH(0, 0, w, skyBottom + 20), t: _t);
    drawHills(canvas, Rect.fromLTWH(0, 0, w, h), skyBottom);

    // Grass texture
    for (final (p, s) in _tufts) {
      drawGrassTuft(canvas, p, s, Palette.grassDark);
    }

    // Scenery along the top
    final ground = l.topSpace * 0.8;
    final sceneH = l.topSpace * 0.62;
    drawTree(canvas, Offset(w * 0.93, ground - sceneH * 0.08), sceneH * 0.85);
    drawFarmhouse(canvas, Offset(w * 0.22, ground), sceneH);
    drawBush(canvas, Offset(w * 0.47, ground + 2), sceneH * 0.34);
    drawTree(canvas, Offset(w * 0.72, ground + 4), sceneH * 1.02);
    drawBush(canvas, Offset(w * 0.04, ground + 6), sceneH * 0.4);

    // Fence just above the field
    final fenceH = (l.topSpace * 0.17).clamp(14.0, 26.0);
    drawFence(canvas, 4, w - 4, l.grid.top - 8, fenceH);

    for (final (p, c, r) in _flowers) {
      drawFlower(canvas, p, r, c);
    }
  }
}
