import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import '../services/sound_service.dart';
import 'effects.dart';
import 'farm_background.dart';
import 'farm_layout.dart';
import 'plot_component.dart';

/// The Flame game that draws the farm field and handles taps on plots.
class FarmGame extends FlameGame {
  FarmGame({
    required this.state,
    required this.sound,
    required this.onMessage,
    required this.onHarvest,
  });

  final GameState state;
  final SoundService sound;

  /// Shows a message (e.g. "Not enough coins") in the Flutter UI.
  final void Function(ActionResult result) onMessage;

  /// Called after a harvest with the plot center (game coordinates), so the
  /// UI can fly wheat icons up to the top bar.
  final void Function(Vector2 from) onHarvest;

  FarmLayout? _layout;
  FarmLayout get layout => _layout ??= FarmLayout(size);

  @override
  Color backgroundColor() => Palette.grass;

  @override
  void onGameResize(Vector2 size) {
    _layout = FarmLayout(size);
    super.onGameResize(size);
  }

  @override
  Future<void> onLoad() async {
    add(FarmBackground());
    for (var i = 0; i < GameConfig.maxPlots; i++) {
      add(PlotComponent(index: i));
    }
  }

  void handlePlotTap(PlotComponent plot) {
    sound.unlock();
    plot.press();
    final index = plot.index;
    final owned = state.plots.length;
    final center = plot.position.clone();
    final cell = layout.cell;

    if (index < owned) {
      final wasEmpty = state.plots[index].isEmpty;
      final result = state.tapPlot(index);
      if (!result.ok) {
        sound.play(Sfx.error);
        onMessage(result);
        return;
      }
      if (wasEmpty) {
        sound.play(Sfx.plant);
        add(dirtPuff(center, cell));
        add(FloatingLabel(
          text: '-${GameConfig.wheatSeedCost}',
          icon: GameIconType.coin,
          start: center - Vector2(0, cell * 0.15),
          fontSize: cell * 0.2,
        ));
      } else {
        sound.play(Sfx.harvest);
        add(grainBurst(center, cell));
        add(FloatingLabel(
          text: '+${GameConfig.wheatPerHarvest}',
          icon: GameIconType.wheat,
          start: center - Vector2(0, cell * 0.15),
          fontSize: cell * 0.22,
        ));
        onHarvest(center);
      }
    } else if (index == owned) {
      final result = state.buyPlot();
      sound.play(result.ok ? Sfx.coin : Sfx.error);
      if (result.ok) add(sparkleBurst(center, cell));
      onMessage(result);
    } else {
      sound.play(Sfx.error);
      onMessage(const ActionResult.fail('Buy the plot with the + sign first.'));
    }
  }
}
