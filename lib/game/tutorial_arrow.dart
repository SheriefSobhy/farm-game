import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../art/palette.dart';
import '../art/sprites.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import 'farm_game.dart';
import 'farm_layout.dart';

/// Where the tutorial arrow points for each step (world units: the point
/// the arrow tip touches).
Offset? tutorialTarget(TutorialStep step) {
  Offset topOf(FarmSpot s, [double dy = 0]) {
    final r = FarmLayout.spots[s]!;
    return Offset(r.center.dx, r.top + dy);
  }

  final plot = FarmLayout.plotRect(0);
  return switch (step) {
    TutorialStep.plant || TutorialStep.harvest => Offset(plot.center.dx, plot.top + 12),
    TutorialStep.buildMill || TutorialStep.makeFlour => topOf(FarmSpot.mill, -10),
    TutorialStep.bakeBread => topOf(FarmSpot.oven, 2),
    TutorialStep.deliver => topOf(FarmSpot.orders, 4),
    TutorialStep.done => null,
  };
}

/// A big yellow arrow bouncing above whatever the tutorial wants tapped.
class TutorialArrow extends PositionComponent with HasGameReference<FarmGame> {
  TutorialArrow() : super(priority: 2000);

  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final target = tutorialTarget(game.state.tutorial);
    if (target == null) return;
    final bounce = (sin(_t * 6).abs() * 6).roundToDouble();
    final tip = target.translate(0, -bounce);
    // soft shadow ring on the ground
    canvas.drawOval(
      Rect.fromCenter(center: target.translate(0, 3), width: 14 - bounce, height: 4),
      Paint()..color = const Color(0x553F2631),
    );
    Art.draw(canvas, S.arrowDown, Rect.fromLTWH(tip.dx - 10, tip.dy - 20, 20, 20));
  }
}

/// A red circle with a white number, drawn on the farm.
void drawBadge(Canvas c, Offset center, int count) {
  final text = count > 9 ? '9+' : '$count';
  final w = text.length > 1 ? 11.0 : 9.0;
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: w, height: 9),
    const Radius.circular(4.5),
  );
  c.drawRRect(r.inflate(1), Paint()..color = Palette.outline);
  c.drawRRect(r, Paint()..color = Palette.red);
  _badgeText.render(c, text, Vector2(center.dx, center.dy + 0.3), anchor: Anchor.center);
}

final TextPaint _badgeText = TextPaint(
  style: AppText.style(6.5, weight: 700, color: const Color(0xFFFFFFFF)),
);
