import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import 'floating_text.dart';
import 'plot_component.dart';

/// The Flame game that draws the farm field and handles taps on plots.
class FarmGame extends FlameGame {
  FarmGame({required this.state, required this.onResult});

  final GameState state;

  /// Used to show messages (e.g. "Not enough coins") in the Flutter UI.
  final void Function(ActionResult result) onResult;

  @override
  Color backgroundColor() => const Color(0xFF9CCC65);

  @override
  Future<void> onLoad() async {
    add(_HintText());
    for (var i = 0; i < GameConfig.maxPlots; i++) {
      add(PlotComponent(index: i));
    }
  }

  void handlePlotTap(PlotComponent plot) {
    final index = plot.index;
    final owned = state.plots.length;
    final center = plot.position + plot.size / 2;

    if (index < owned) {
      final result = state.tapPlot(index);
      if (result.ok) {
        final harvested = result.message!.startsWith('+');
        add(FloatingText(
          text: result.message!,
          start: center,
          fontSize: plot.size.x * 0.18,
          color: harvested ? const Color(0xFFFFF59D) : Colors.white,
        ));
      } else {
        onResult(result);
      }
    } else if (index == owned) {
      onResult(state.buyPlot());
    } else {
      onResult(const ActionResult.fail('Buy the plot with ➕ first.'));
    }
  }
}

class _HintText extends TextComponent {
  _HintText()
      : super(
          text: 'Tap soil to plant • Tap 🌾 to harvest',
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF33691E),
            ),
          ),
        );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, 18);
  }
}
