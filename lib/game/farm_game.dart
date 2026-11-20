import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import '../services/sound_service.dart';
import '../art/sprites.dart';
import 'animal_component.dart';
import 'building_component.dart';
import 'effects.dart';
import 'farm_ground.dart';
import 'farm_layout.dart';
import 'plot_component.dart';

/// The Flame game: one farm scene with the field and all buildings.
class FarmGame extends FlameGame {
  FarmGame({
    required this.state,
    required this.sound,
    required this.onMessage,
    required this.onHarvest,
    required this.onOpenSpot,
  });

  final GameState state;
  final SoundService sound;

  /// Shows a message (e.g. "Not enough coins") in the Flutter UI.
  final void Function(ActionResult result) onMessage;

  /// Called after a harvest with the plot center in widget coordinates,
  /// so the UI can fly item icons to the top bar.
  final void Function(Offset from, Item item, int count) onHarvest;

  /// Called when the player taps a building.
  final void Function(FarmSpot spot) onOpenSpot;

  @override
  Color backgroundColor() => Palette.grass;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(
      FarmLayout.worldWidth / 2,
      FarmLayout.worldHeight / 2,
    );
    world.add(FarmGround());
    for (var i = 0; i < GameConfig.maxPlots; i++) {
      world.add(PlotComponent(index: i));
    }
    for (final spot in FarmSpot.values) {
      world.add(BuildingComponent(spot));
    }
    for (var i = 0; i < 3; i++) {
      world.add(
        AnimalComponent(
          sprite: S.sheep,
          area: const Rect.fromLTWH(22, 312, 150, 30),
          seed: i + 1,
        ),
      );
    }
    _fit(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _fit(size);
  }

  /// Zooms so the whole farm fits on screen.
  void _fit(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = min(
      size.x / (FarmLayout.worldWidth + 4),
      size.y / (FarmLayout.worldHeight + 4),
    );
  }

  /// Converts a world position to a position inside the game widget.
  Offset worldToWidget(Vector2 p) {
    final vf = camera.viewfinder;
    final z = vf.zoom;
    return Offset(
      (p.x - vf.position.x) * z + size.x / 2,
      (p.y - vf.position.y) * z + size.y / 2,
    );
  }

  void openSpot(FarmSpot spot) {
    sound.unlock();
    sound.play(Sfx.tap);
    onOpenSpot(spot);
  }

  void handlePlotTap(PlotComponent plot) {
    sound.unlock();
    plot.press();
    final index = plot.index;
    final owned = state.plots.length;
    final center = plot.position.clone();

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
        world.add(dirtPuff(center + Vector2(0, 6)));
        world.add(
          FloatingLabel(
            text: '-${GameConfig.wheatSeedCost}',
            icon: GameIconType.coin,
            start: center - Vector2(0, 8),
          ),
        );
      } else {
        sound.play(Sfx.harvest);
        world.add(grainBurst(center));
        world.add(
          FloatingLabel(
            text: '+${GameConfig.wheatPerHarvest}',
            icon: GameIconType.wheat,
            start: center - Vector2(0, 8),
            fontSize: 10,
          ),
        );
        onHarvest(
          worldToWidget(center),
          Item.wheat,
          GameConfig.wheatPerHarvest,
        );
      }
    } else if (index == owned) {
      final result = state.buyPlot();
      sound.play(result.ok ? Sfx.coin : Sfx.error);
      if (result.ok) world.add(sparkleBurst(center));
      onMessage(result);
    } else {
      sound.play(Sfx.error);
      onMessage(
        const ActionResult.fail('Buy the plot with the price sign first.'),
      );
    }
  }
}
