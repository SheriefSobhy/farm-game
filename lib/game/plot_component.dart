import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../models/item.dart';
import 'farm_game.dart';

/// One square in the 3x3 farm grid. Depending on the game state it is drawn
/// as an owned plot, the next plot you can buy, or a locked plot.
class PlotComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FarmGame> {
  PlotComponent({required this.index});

  final int index;

  static const double _topSpace = 56;
  static const double _padding = 16;
  static const double _gap = 12;

  double _time = 0;
  TextPaint _bigEmoji = TextPaint();
  TextPaint _label = TextPaint();
  TextPaint _lockEmoji = TextPaint();

  final Paint _soil = Paint()..color = const Color(0xFF8D6E63);
  final Paint _soilDark = Paint()..color = const Color(0xFF6D4C41);
  final Paint _furrow = Paint()
    ..color = const Color(0x33000000)
    ..strokeWidth = 3;
  final Paint _readyBorder = Paint()
    ..color = const Color(0xFFFFD54F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  final Paint _buyFill = Paint()..color = const Color(0x66FFFFFF);
  final Paint _buyBorder = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _lockedFill = Paint()..color = const Color(0x2233691E);
  final Paint _barBack = Paint()..color = const Color(0x88000000);
  final Paint _barFill = Paint()..color = const Color(0xFF7CB342);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    const cols = GameConfig.gridColumns;
    final rows = (GameConfig.maxPlots / cols).ceil();
    final cell = max(
      20.0,
      min(
        (size.x - _padding * 2 - _gap * (cols - 1)) / cols,
        (size.y - _topSpace - _padding - _gap * (rows - 1)) / rows,
      ),
    );
    final gridW = cell * cols + _gap * (cols - 1);
    final gridH = cell * rows + _gap * (rows - 1);
    final left = (size.x - gridW) / 2;
    final top =
        _topSpace + max(0.0, (size.y - _topSpace - _padding - gridH) / 2);

    final col = index % cols;
    final row = index ~/ cols;
    position = Vector2(left + col * (cell + _gap), top + row * (cell + _gap));
    this.size = Vector2.all(cell);

    _bigEmoji = TextPaint(style: TextStyle(fontSize: cell * 0.4));
    _lockEmoji = TextPaint(
      style: TextStyle(fontSize: cell * 0.25, color: const Color(0x88000000)),
    );
    _label = TextPaint(
      style: TextStyle(
        fontSize: cell * 0.12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void onTapDown(TapDownEvent event) => game.handlePlotTap(this);

  @override
  void render(Canvas canvas) {
    final state = game.state;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.14));

    if (index < state.plots.length) {
      _renderOwned(canvas, rrect);
    } else if (index == state.plots.length) {
      _renderBuyable(canvas, rrect);
    } else {
      canvas.drawRRect(rrect, _lockedFill);
      _lockEmoji.render(canvas, '🔒', size / 2, anchor: Anchor.center);
    }
  }

  void _renderOwned(Canvas canvas, RRect rrect) {
    final state = game.state;
    final plot = state.plots[index];
    final now = state.nowMs;
    final w = size.x;
    final h = size.y;

    canvas.drawRRect(rrect.shift(const Offset(0, 4)), _soilDark);
    canvas.drawRRect(rrect, _soil);
    for (var i = 1; i <= 3; i++) {
      final y = h * i / 4;
      canvas.drawLine(Offset(w * 0.15, y), Offset(w * 0.85, y), _furrow);
    }

    if (plot.isEmpty) {
      _label.render(canvas, 'Tap to plant', Vector2(w / 2, h * 0.38),
          anchor: Anchor.center);
      _label.render(canvas, '-${GameConfig.wheatSeedCost} $coinEmoji',
          Vector2(w / 2, h * 0.62),
          anchor: Anchor.center);
      return;
    }

    final progress = plot.progress(now);
    if (progress >= 1) {
      canvas.drawRRect(rrect, _readyBorder);
      final bounce = sin(_time * 6) * h * 0.03;
      _bigEmoji.render(
          canvas, Item.wheat.emoji, Vector2(w / 2, h * 0.42 + bounce),
          anchor: Anchor.center);
      _label.render(canvas, 'Harvest!', Vector2(w / 2, h * 0.82),
          anchor: Anchor.center);
      return;
    }

    _bigEmoji.render(
        canvas, progress < 0.5 ? '🌱' : '🌿', Vector2(w / 2, h * 0.4),
        anchor: Anchor.center);

    // Progress bar
    final barRect = Rect.fromLTWH(w * 0.12, h * 0.76, w * 0.76, h * 0.1);
    final radius = Radius.circular(barRect.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, radius), _barBack);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            barRect.left, barRect.top, barRect.width * progress, barRect.height),
        radius,
      ),
      _barFill,
    );
    final secs = (plot.remainingMs(now) / 1000).ceil();
    _label.render(canvas, '${secs}s', Vector2(w / 2, h * 0.64),
        anchor: Anchor.center);
  }

  void _renderBuyable(Canvas canvas, RRect rrect) {
    final state = game.state;
    canvas.drawRRect(rrect, _buyFill);
    canvas.drawRRect(rrect, _buyBorder);
    _bigEmoji.render(canvas, '➕', Vector2(size.x / 2, size.y * 0.4),
        anchor: Anchor.center);
    _label.render(canvas, '${state.nextPlotPrice} $coinEmoji',
        Vector2(size.x / 2, size.y * 0.78),
        anchor: Anchor.center);
  }
}
