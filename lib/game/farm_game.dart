import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/sprites.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/defs.dart';
import '../models/game_state.dart';
import '../models/plot.dart';
import '../services/sound_service.dart';
import '../ui/widgets/icon_text.dart';
import 'animal_component.dart';
import 'building_component.dart';
import 'effects.dart';
import 'farm_ground.dart';
import 'farm_layout.dart';
import 'plot_component.dart';
import 'tutorial_arrow.dart';

/// The Flame game: one farm scene with the field, buildings and animals.
class FarmGame extends FlameGame {
  FarmGame({
    required this.state,
    required this.sound,
    required this.onMessage,
    required this.onFly,
    required this.onOpenSpot,
  });

  final GameState state;
  final SoundService sound;

  /// Shows a message (e.g. "Not enough coins") in the Flutter UI.
  final void Function(ActionResult result) onMessage;

  /// Flies [count] icons from a point (widget coordinates) to a UI target
  /// such as "barn" or "coin".
  final void Function(Offset from, GameIconType icon, String target, int count) onFly;

  /// Called when the player taps a building and its panel should open.
  final void Function(FarmSpot spot) onOpenSpot;

  final Map<AnimalKind, List<AnimalComponent>> _animals = {
    for (final k in AnimalKind.values) k: [],
  };

  @override
  Color backgroundColor() => Palette.grass;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(FarmLayout.worldWidth / 2, FarmLayout.worldHeight / 2);
    world.add(FarmGround());
    for (var i = 0; i < GameConfig.maxPlots; i++) {
      world.add(PlotComponent(index: i));
    }
    for (final spot in FarmSpot.values) {
      final animal = spot.animal;
      world.add(animal == null ? BuildingComponent(spot) : PenComponent(animal, spot));
    }
    world.add(TutorialArrow());
    _fit(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncAnimals();
  }

  /// Keeps one walking animal on the farm for each animal the player owns.
  void _syncAnimals() {
    for (final kind in AnimalKind.values) {
      final list = _animals[kind]!;
      final want = state.pens[kind]!.animals.length;
      while (list.length < want) {
        final pen = FarmLayout.spots[FarmSpot.forAnimal(kind)]!;
        final c = AnimalComponent(
          sprite: kind == AnimalKind.chicken ? S.chicken : S.cow,
          area: Rect.fromLTWH(pen.left + 12, pen.top + 22, pen.width - 58, pen.height - 34),
          seed: list.length * 13 + kind.index,
          pen: kind,
          index: list.length,
        );
        list.add(c);
        world.add(c);
      }
      while (list.length > want) {
        list.removeLast().removeFromParent();
      }
    }
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
    return Offset((p.x - vf.position.x) * z + size.x / 2, (p.y - vf.position.y) * z + size.y / 2);
  }

  /// A building or pen was tapped: collect / feed when possible, otherwise
  /// open its panel.
  void tapSpot(FarmSpot spot) {
    sound.unlock();
    final rect = FarmLayout.spots[spot]!;
    final top = Vector2(rect.center.dx, rect.top + min(20, rect.height / 3));

    final kind = spot.building;
    if (kind != null) {
      final b = state.buildings[kind]!;
      if (b.owned && b.readyCount(state.nowMs) > 0) {
        final out = state.collect(b);
        if (!out.result.ok) {
          sound.play(Sfx.error);
          onMessage(out.result);
          return;
        }
        sound.play(Sfx.harvest);
        world.add(sparkleBurst(top));
        var dy = 0.0;
        for (final e in out.items.entries) {
          world.add(
            FloatingLabel(
              text: '+${e.value}',
              icon: itemIcon(e.key),
              start: top - Vector2(0, 6 + dy),
            ),
          );
          onFly(worldToWidget(top), itemIcon(e.key), 'barn', min(e.value, 4));
          dy += 10;
        }
        if (out.result.message?.contains('full') ?? false) onMessage(out.result);
        return;
      }
    }

    final animal = spot.animal;
    if (animal != null) {
      final pen = state.pens[animal]!;
      final now = state.nowMs;
      final canTend =
          pen.readyCount(now) > 0 || (pen.hungryCount() > 0 && state.count(pen.def.feed) > 0);
      if (pen.animals.isNotEmpty && canTend) {
        final out = state.tendPen(animal);
        if (!out.result.ok) {
          sound.play(Sfx.error);
          onMessage(out.result);
          return;
        }
        sound.play(out.collected > 0 ? Sfx.harvest : Sfx.plant);
        final center = Vector2(rect.left + 34, rect.top + 30);
        if (out.collected > 0) {
          world.add(sparkleBurst(center));
          world.add(
            FloatingLabel(
              text: '+${out.collected}',
              icon: itemIcon(pen.def.product),
              start: center,
            ),
          );
          onFly(worldToWidget(center), itemIcon(pen.def.product), 'barn', min(out.collected, 4));
        }
        if (out.fed > 0) {
          world.add(
            pixelBurst(
              center + Vector2(0, 8),
              colors: const [Palette.gold, Palette.goldDark],
              count: 8,
              speed: 20,
            ),
          );
        }
        onMessage(out.result);
        return;
      }
    }

    sound.play(Sfx.tap);
    onOpenSpot(spot);
  }

  // ---------------------------------------------------------------- Field

  /// What the last tap on a plot did, so a drag that starts there keeps
  /// doing the same thing.
  ({int index, _PlotAction action})? _lastTap;
  _PlotAction? _swipeAction;
  final Set<int> _swiped = {};
  bool _swipeStopped = false;

  void beginSwipe(int startIndex) {
    _swiped
      ..clear()
      ..add(startIndex);
    _swipeStopped = false;
    final last = _lastTap;
    _swipeAction = last != null && last.index == startIndex ? last.action : null;
    if (_swipeAction == _PlotAction.none) _swipeAction = null;
  }

  void swipeAt(Vector2 worldPoint) {
    if (_swipeStopped) return;
    for (final plot in world.children.whereType<PlotComponent>()) {
      final i = plot.index;
      if (_swiped.contains(i) || i >= state.plots.length) continue;
      if (!plot.toRect().contains(worldPoint.toOffset())) continue;
      _swiped.add(i);
      final p = state.plots[i];
      final action =
          _swipeAction ??
          (p.isEmpty ? _PlotAction.plant : (p.isReady(state.nowMs) ? _PlotAction.harvest : null));
      if (action == null) return;
      final wantsEmpty = action == _PlotAction.plant;
      if (wantsEmpty != p.isEmpty) return; // not the same kind of plot
      if (action == _PlotAction.harvest && !p.isReady(state.nowMs)) return;
      _swipeAction = action;
      plot.press();
      final done = _actOnPlot(plot, quiet: true);
      if (done == _PlotAction.none) _swipeStopped = true; // no coins / barn full
      return;
    }
  }

  void endSwipe() => _swipeAction = null;

  void handlePlotTap(PlotComponent plot) {
    sound.unlock();
    plot.press();
    final action = _actOnPlot(plot, quiet: false);
    _lastTap = (index: plot.index, action: action);
  }

  /// Plants, harvests or buys [plot]. Returns what happened.
  _PlotAction _actOnPlot(PlotComponent plot, {required bool quiet}) {
    final index = plot.index;
    final owned = state.plots.length;
    final center = plot.position.clone();

    if (index < owned) {
      final p = state.plots[index];
      final wasEmpty = p.isEmpty;
      final cropBefore = p.crop;
      final result = state.tapPlot(index);
      if (!result.ok) {
        sound.play(Sfx.error);
        onMessage(result);
        return _PlotAction.none;
      }
      if (wasEmpty) {
        sound.play(Sfx.plant);
        world.add(dirtPuff(center + Vector2(0, 6)));
        world.add(
          FloatingLabel(
            text: '-${cropFor(p.crop).seedCost}',
            icon: GameIconType.coin,
            start: center - Vector2(0, 8),
          ),
        );
      } else {
        final crop = cropFor(cropBefore);
        sound.play(Sfx.harvest);
        world.add(grainBurst(center));
        world.add(
          FloatingLabel(
            text: '+${crop.harvest}',
            icon: itemIcon(crop.item),
            start: center - Vector2(0, 8),
            fontSize: 10,
          ),
        );
        onFly(worldToWidget(center), itemIcon(crop.item), 'barn', quiet ? 1 : crop.harvest);
        return _PlotAction.harvest;
      }
      return _PlotAction.plant;
    } else if (index == owned) {
      final result = state.buyPlot();
      sound.play(result.ok ? Sfx.coin : Sfx.error);
      if (result.ok) world.add(sparkleBurst(center));
      onMessage(result);
    } else {
      sound.play(Sfx.error);
      onMessage(const ActionResult.fail('Buy the plot with the price sign first.'));
    }
    return _PlotAction.none;
  }
}

enum _PlotAction { plant, harvest, none }
