import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game_config.dart';
import 'action_result.dart';
import 'item.dart';
import 'plot.dart';
import 'production_building.dart';

/// The whole game: money, items, land and buildings, plus every rule.
/// UI widgets and the Flame game both read from and call into this class.
class GameState extends ChangeNotifier {
  GameState({int Function()? clock})
      : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch) {
    _resetValues();
  }

  final int Function() _clock;

  int coins = 0;
  final Map<Item, int> _items = {};
  final List<Plot> plots = [];
  final ProductionBuilding mill = ProductionBuilding(Recipe.mill);
  final ProductionBuilding oven = ProductionBuilding(Recipe.oven);

  bool _dirty = false;

  /// Optional hook, called when the mill or oven finishes a batch
  /// (used by the UI for a sound and a message).
  void Function(ProductionBuilding building)? onProductionDone;

  int get nowMs => _clock();

  int count(Item item) => _items[item] ?? 0;

  // ---------------------------------------------------------------- Land

  bool get canBuyMorePlots => plots.length < GameConfig.maxPlots;

  int get nextPlotPrice {
    final bought = plots.length - GameConfig.startingPlots;
    return (GameConfig.firstPlotPrice *
            pow(GameConfig.plotPriceMultiplier, max(0, bought)))
        .round();
  }

  /// Plants on an empty plot, or harvests a ready one.
  ActionResult tapPlot(int index) {
    if (index < 0 || index >= plots.length) {
      return const ActionResult.fail('That plot is not yours yet.');
    }
    final plot = plots[index];
    final now = nowMs;

    if (plot.isEmpty) {
      const cost = GameConfig.wheatSeedCost;
      if (coins < cost) {
        return const ActionResult.fail(
            'Not enough coins! Planting costs $cost $coinToken');
      }
      coins -= cost;
      plot.plantedAtMs = now;
      _changed();
      return const ActionResult.ok('-$cost $coinToken');
    }

    if (!plot.isReady(now)) {
      final secs = (plot.remainingMs(now) / 1000).ceil();
      return ActionResult.fail('Still growing... ${secs}s left');
    }

    plot.plantedAtMs = null;
    _add(Item.wheat, GameConfig.wheatPerHarvest);
    _changed();
    return ActionResult.ok('+${GameConfig.wheatPerHarvest} ${Item.wheat.token}');
  }

  ActionResult buyPlot() {
    if (!canBuyMorePlots) {
      return const ActionResult.fail('Your farm is full! (max ${GameConfig.maxPlots} plots)');
    }
    final price = nextPlotPrice;
    if (coins < price) {
      return ActionResult.fail(
          'Not enough coins! A new plot costs $price $coinToken');
    }
    coins -= price;
    plots.add(Plot());
    _changed();
    return const ActionResult.ok('New plot bought! 🌱');
  }

  // ----------------------------------------------------------- Buildings

  ActionResult buyBuilding(ProductionBuilding building) {
    final recipe = building.recipe;
    if (building.owned) {
      return ActionResult.fail('You already own the ${recipe.buildingName}.');
    }
    if (coins < recipe.price) {
      return ActionResult.fail(
          'Not enough coins! The ${recipe.buildingName} costs ${recipe.price} $coinToken');
    }
    coins -= recipe.price;
    building.owned = true;
    _changed();
    return ActionResult.ok('${recipe.buildingName} built!');
  }

  ActionResult startProduction(ProductionBuilding building) {
    final recipe = building.recipe;
    if (!building.owned) {
      return ActionResult.fail(
          'Buy the ${recipe.buildingName} in the Shop first.');
    }
    if (building.isWorking) {
      return ActionResult.fail('The ${recipe.buildingName} is busy. Please wait!');
    }
    if (count(recipe.input) < recipe.inputAmount) {
      return ActionResult.fail(
          'Not enough ${recipe.input.label.toLowerCase()}! '
          'You need ${recipe.inputAmount} ${recipe.input.token}');
    }
    _add(recipe.input, -recipe.inputAmount);
    building.jobStartedAtMs = nowMs;
    _changed();
    return const ActionResult.ok();
  }

  // -------------------------------------------------------------- Market

  ActionResult sell(Item item, int amount) {
    if (amount <= 0 || count(item) < amount) {
      return ActionResult.fail(
          'You have no ${item.label.toLowerCase()} to sell ${item.token}');
    }
    final earned = amount * item.sellPrice;
    _add(item, -amount);
    coins += earned;
    _changed();
    return ActionResult.ok('Sold $amount ${item.token} for $earned $coinToken');
  }

  ActionResult sellAll(Item item) => sell(item, count(item));

  // --------------------------------------------------------------- Clock

  /// Called several times per second. Finishes buildings whose timer is done
  /// and refreshes any visible progress bars.
  void tick() {
    var changed = false;
    final now = nowMs;
    for (final b in [mill, oven]) {
      if (b.isWorking && b.progress(now) >= 1) {
        b.jobStartedAtMs = null;
        _add(b.recipe.output, b.recipe.outputAmount);
        changed = true;
        onProductionDone?.call(b);
      }
    }
    if (changed) {
      _changed();
    } else if (mill.isWorking || oven.isWorking || plots.any((p) => !p.isEmpty)) {
      notifyListeners(); // progress bars only, nothing to save
    }
  }

  // ---------------------------------------------------------------- Save

  /// Returns true once after something changed, so it can be saved.
  bool consumeDirty() {
    final wasDirty = _dirty;
    _dirty = false;
    return wasDirty;
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'items': {for (final i in Item.values) i.name: count(i)},
        'plots': [for (final p in plots) p.plantedAtMs],
        'mill': mill.toJson(),
        'oven': oven.toJson(),
      };

  void loadFromJson(Map<String, dynamic> json) {
    _resetValues();
    final c = json['coins'];
    if (c is int) coins = c;

    final items = json['items'];
    if (items is Map) {
      for (final i in Item.values) {
        final v = items[i.name];
        if (v is int && v >= 0) _items[i] = v;
      }
    }

    final savedPlots = json['plots'];
    if (savedPlots is List && savedPlots.isNotEmpty) {
      plots
        ..clear()
        ..addAll(savedPlots
            .take(GameConfig.maxPlots)
            .map((t) => Plot(plantedAtMs: t is int ? t : null)));
    }

    final m = json['mill'];
    mill.loadFromJson(m is Map<String, dynamic> ? m : null);
    final o = json['oven'];
    oven.loadFromJson(o is Map<String, dynamic> ? o : null);

    tick(); // finish anything that completed while the app was closed
    notifyListeners();
  }

  void resetGame() {
    _resetValues();
    _changed();
  }

  // ------------------------------------------------------------- Helpers

  void _resetValues() {
    coins = GameConfig.startingCoins;
    _items
      ..clear()
      ..addAll({for (final i in Item.values) i: 0});
    plots
      ..clear()
      ..addAll(List.generate(GameConfig.startingPlots, (_) => Plot()));
    for (final b in [mill, oven]) {
      b.owned = false;
      b.jobStartedAtMs = null;
    }
  }

  void _add(Item item, int amount) => _items[item] = count(item) + amount;

  void _changed() {
    _dirty = true;
    notifyListeners();
  }
}
