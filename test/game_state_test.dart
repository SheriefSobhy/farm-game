import 'dart:math';

import 'package:farm_game/game_config.dart';
import 'package:farm_game/models/defs.dart';
import 'package:farm_game/models/game_state.dart';
import 'package:farm_game/models/item.dart';
import 'package:farm_game/models/production_building.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int now;
  late GameState state;

  setUp(() {
    now = DateTime(2026, 11, 20, 12).millisecondsSinceEpoch;
    state = GameState(clock: () => now, random: Random(1));
  });

  /// Gives items without touching anything else.
  void give(Map<Item, int> items) {
    final json = state.toJson();
    final current = Map<String, dynamic>.from(json['items'] as Map);
    for (final e in items.entries) {
      current[e.key.name] = (current[e.key.name] as int) + e.value;
    }
    state.loadFromJson({...json, 'items': current});
  }

  final wheat = GameConfig.crops.first;

  test('starts with configured coins, plots and 3 orders', () {
    expect(state.coins, GameConfig.startingCoins);
    expect(state.plots.length, GameConfig.startingPlots);
    expect(state.orders.length, GameConfig.orderSlots);
    expect(state.level, 1);
  });

  test('plant, wait, harvest gives items and XP', () {
    expect(state.tapPlot(0).ok, isTrue);
    expect(state.coins, GameConfig.startingCoins - wheat.seedCost);
    expect(state.tapPlot(0).ok, isFalse); // still growing
    now += wheat.growTime.inMilliseconds;
    expect(state.tapPlot(0).ok, isTrue);
    expect(state.count(Item.wheat), wheat.harvest);
    expect(state.xp, wheat.xp);
    expect(state.plots[0].isEmpty, isTrue);
  });

  test('cannot plant without coins', () {
    state.coins = 0;
    expect(state.tapPlot(0).ok, isFalse);
  });

  test('plot price increases and is capped', () {
    state.coins = 1000000;
    final first = state.nextPlotPrice;
    state.buyPlot();
    expect(state.nextPlotPrice, greaterThan(first));
    while (state.canBuyMorePlots) {
      state.buyPlot();
    }
    expect(state.plots.length, GameConfig.maxPlots);
    expect(state.buyPlot().ok, isFalse);
  });

  test('mill makes flour; it waits in the building until collected', () {
    final mill = state.mill;
    final flour = recipeById('flour')!;
    expect(state.startProduction(mill, flour).ok, isFalse); // not built
    state.coins = mill.def.price;
    expect(state.buyBuilding(mill).ok, isTrue);
    expect(state.startProduction(mill, flour).ok, isFalse); // no wheat
    give({Item.wheat: 2});
    expect(state.startProduction(mill, flour).ok, isTrue);
    expect(state.count(Item.wheat), 0);
    now += flour.time.inMilliseconds;
    state.tick();
    expect(mill.readyCount(now), 1);
    expect(state.count(Item.flour), 0);
    final out = state.collect(mill);
    expect(out.result.ok, isTrue);
    expect(state.count(Item.flour), flour.outputAmount);
    expect(state.xp, flour.xp);
  });

  test('buildings are locked until their level', () {
    state.coins = 100000;
    final pop = state.buildings[BuildingKind.popcorn]!;
    expect(state.buyBuilding(pop).ok, isFalse);
    state.xp = GameState.xpForLevel(pop.def.unlockLevel);
    expect(state.level, pop.def.unlockLevel);
    expect(state.buyBuilding(pop).ok, isTrue);
  });

  test('levelling up gives coins and reports unlocks', () {
    final got = <int>[];
    state.onLevelUp = (l, unlocks) => got.add(l);
    final coinsBefore = state.coins;
    state.xp = GameState.xpForLevel(3) - 1;
    give({}); // reload keeps xp
    state.onLevelUp = (l, unlocks) {
      got.add(l);
      expect(unlocks.any((u) => u.name.contains('Corn')), isTrue);
    };
    state.tapPlot(0);
    now += wheat.growTime.inMilliseconds;
    state.tapPlot(0); // +1 xp → level 3
    expect(got, [3]);
    expect(state.coins, greaterThan(coinsBefore - wheat.seedCost));
  });

  test('filling an order pays coins and XP and brings a new order', () {
    final o = state.orders.first;
    give(o.items);
    final coins = state.coins;
    final r = state.fillOrder(0);
    expect(r.ok, isTrue);
    expect(state.coins, coins + o.coins);
    expect(state.xp, o.xp);
    expect(state.orders.length, GameConfig.orderSlots);
    expect(identical(state.orders.first, o), isFalse);
  });

  test('orders only ask for things the player can make', () {
    for (var i = 0; i < 20; i++) {
      state.skipOrder(0);
      now += GameConfig.orderSkipWait.inMilliseconds;
      expect(state.orders[0].items.keys, everyElement(Item.wheat));
    }
  });

  test('barn capacity blocks harvests and can be upgraded', () {
    give({Item.flour: GameConfig.barnStartCapacity});
    state.tapPlot(0);
    now += wheat.growTime.inMilliseconds;
    expect(state.tapPlot(0).ok, isFalse);
    state.coins = state.barnUpgradePrice;
    expect(state.upgradeBarn().ok, isTrue);
    expect(state.tapPlot(0).ok, isTrue);
  });

  test('daily reward builds a streak and resets after a missed day', () {
    expect(state.claimDaily().ok, isTrue);
    expect(state.claimDaily().ok, isFalse);
    now += const Duration(days: 1).inMilliseconds;
    expect(state.nextStreakDay, 2);
    expect(state.claimDaily().ok, isTrue);
    now += const Duration(days: 2).inMilliseconds;
    expect(state.nextStreakDay, 1);
  });

  test('daily goals track progress and can be claimed', () {
    final goals = state.todaysGoals;
    expect(goals.length, 3);
    final g = goals.first;
    g.progress = state.goalDef(g).target;
    final coins = state.coins;
    expect(state.claimGoal(0).ok, isTrue);
    expect(state.coins, coins + GameConfig.goalRewardCoins);
    expect(state.claimGoal(0).ok, isFalse);
  });

  test('chickens eat feed and lay eggs', () {
    state.coins = 100000;
    state.xp = GameState.xpForLevel(5);
    expect(state.buyAnimal(AnimalKind.chicken).ok, isTrue);
    expect(state.tendPen(AnimalKind.chicken).result.ok, isFalse); // no feed
    give({Item.chickenFeed: 1});
    expect(state.tendPen(AnimalKind.chicken).fed, 1);
    now += GameConfig.animals.first.time.inMilliseconds;
    final out = state.tendPen(AnimalKind.chicken);
    expect(out.collected, 1);
    expect(state.count(Item.egg), 1);
  });

  test('selling adds coins', () {
    state.loadFromJson({
      'coins': 0,
      'items': {'bread': 2},
    });
    expect(state.sellAll(Item.bread).ok, isTrue);
    expect(state.coins, 2 * GameConfig.breadSellPrice);
    expect(state.sell(Item.bread, 1).ok, isFalse);
  });

  test('save and load round-trip keeps everything', () {
    state.tapPlot(0);
    state.coins = 5000;
    state.buyBuilding(state.mill);
    give({Item.wheat: 4});
    state.startProduction(state.mill);
    state.claimDaily();
    final saved = state.toJson();
    final loaded = GameState(clock: () => now)..loadFromJson(saved);
    expect(loaded.plots[0].plantedAtMs, now);
    expect(loaded.coins, state.coins);
    expect(loaded.mill.owned, isTrue);
    expect(loaded.mill.jobs.length, 1);
    expect(loaded.orders.map((o) => o.coins), state.orders.map((o) => o.coins));
    expect(loaded.canClaimDaily, isFalse);
  });

  test('old version 1 saves still load', () {
    final v1 = {
      'coins': 321,
      'items': {'wheat': 5, 'flour': 2, 'bread': 1},
      'plots': [now - 1000, null, now - 99999],
      'mill': {'owned': true, 'jobStartedAtMs': now - 1000},
      'oven': {'owned': false, 'jobStartedAtMs': null},
    };
    state.loadFromJson(v1);
    expect(state.coins, 321);
    expect(state.count(Item.wheat), 5);
    expect(state.plots.length, 3);
    expect(state.plots[0].crop, Item.wheat);
    expect(state.plots[2].isReady(now), isTrue);
    expect(state.mill.owned, isTrue);
    expect(state.mill.jobs.single.recipe.output, Item.flour);
    expect(state.oven.owned, isFalse);
    expect(state.level, 1);
    expect(state.orders.length, GameConfig.orderSlots);
  });

  test('the tutorial walks a new player from planting to the first order', () {
    expect(state.tutorial, TutorialStep.plant);
    expect(state.oven.owned, isTrue, reason: 'new farms start with an oven');
    void growAndHarvest() {
      state.tapPlot(0);
      now += wheat.growTime.inMilliseconds;
      expect(state.tapPlot(0).ok, isTrue);
    }

    state.tapPlot(0);
    expect(state.tutorial, TutorialStep.harvest);
    now += wheat.growTime.inMilliseconds;
    state.tapPlot(0);
    growAndHarvest();
    expect(state.tutorial, TutorialStep.buildMill);
    expect(state.buyBuilding(state.mill).ok, isTrue, reason: 'starting coins buy the mill');
    expect(state.tutorial, TutorialStep.makeFlour);
    final flour = recipeById('flour')!;
    expect(state.startProduction(state.mill, flour).ok, isTrue);
    expect(state.startProduction(state.mill, flour).ok, isTrue);
    now += flour.time.inMilliseconds * 2;
    state.collect(state.mill);
    expect(state.tutorial, TutorialStep.bakeBread);
    final bread = recipeById('bread')!;
    expect(state.startProduction(state.oven, bread).ok, isTrue);
    now += bread.time.inMilliseconds;
    state.collect(state.oven);
    expect(state.tutorial, TutorialStep.deliver);
    expect(state.orders.first.items, {Item.bread: 1});
    expect(state.fillOrder(0).ok, isTrue);
    expect(state.tutorial, TutorialStep.done);

    final again = GameState(clock: () => now)..loadFromJson(state.toJson());
    expect(again.tutorial, TutorialStep.done);
  });

  test('old saves skip the tutorial', () {
    state.loadFromJson({'coins': 10});
    expect(state.tutorial, TutorialStep.done);
  });
}
