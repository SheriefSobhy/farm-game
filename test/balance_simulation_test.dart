// Plays the game from a new save with a simple "sensible player" bot and a
// fake clock, to check that the whole flow works and that early levels come
// about every 3-5 minutes.
//
// Run:  flutter test test/balance_simulation_test.dart

import 'dart:math';

import 'package:farm_game/game_config.dart';
import 'package:farm_game/models/animal_pen.dart';
import 'package:farm_game/models/defs.dart';
import 'package:farm_game/models/game_state.dart';
import 'package:farm_game/models/item.dart';
import 'package:farm_game/models/plot.dart';
import 'package:farm_game/models/production_building.dart';
import 'package:flutter_test/flutter_test.dart';

class Bot {
  Bot(this.s);
  final GameState s;
  final Map<int, int> orderSeenAt = {};
  int actions = 0;

  bool act(bool ok) {
    if (ok) actions++;
    return ok;
  }

  /// Items needed by open orders that are not in the barn yet.
  Map<Item, int> missing() {
    final need = <Item, int>{};
    for (final o in s.orders) {
      if (o.isWaiting(s.nowMs)) continue;
      for (final e in o.items.entries) {
        need[e.key] = (need[e.key] ?? 0) + e.value;
      }
    }
    return {
      for (final e in need.entries)
        if (s.count(e.key) < e.value) e.key: e.value - s.count(e.key),
    };
  }

  /// One "turn": the player does at most [budget] useful taps.
  void turn(int budget) {
    final now = s.nowMs;
    var left = budget;
    bool spend(bool ok) {
      if (ok) left--;
      return act(ok);
    }

    if (s.canClaimDaily) spend(s.claimDaily().ok);
    for (var i = 0; i < s.todaysGoals.length; i++) {
      if (s.goalDone(s.goals[i]) && !s.goals[i].claimed) spend(s.claimGoal(i).ok);
    }

    // deliver orders
    for (var i = 0; i < s.orders.length && left > 0; i++) {
      if (s.canFill(s.orders[i])) spend(s.fillOrder(i).ok);
    }

    // collect from buildings and pens
    for (final b in s.buildings.values) {
      if (left <= 0) break;
      if (b.owned && b.readyCount(now) > 0) spend(s.collect(b).result.ok);
    }
    for (final k in AnimalKind.values) {
      final pen = s.pens[k]!;
      if (left <= 0 || pen.animals.isEmpty) continue;
      if (pen.readyCount(now) > 0 || (pen.hungryCount() > 0 && s.count(pen.def.feed) > 0)) {
        spend(s.tendPen(k).result.ok);
      }
    }

    // the field: one swipe harvests or plants everything (1 action)
    final miss = missing();
    final wantCorn =
        s.unlockedCrops.length > 1 &&
        (miss.keys.any((i) => i == Item.corn || i == Item.popcorn || i == Item.chickenFeed) ||
            s.count(Item.corn) < 6);
    s.selectCrop(wantCorn ? Item.corn : Item.wheat);
    var fieldWork = false;
    for (var i = 0; i < s.plots.length; i++) {
      final p = s.plots[i];
      if (p.isReady(now) || p.isEmpty) {
        final r = s.tapPlot(i);
        fieldWork |= r.ok;
        if (p.isEmpty && !r.ok) break;
      }
      // mix crops: alternate when corn is wanted
      if (wantCorn) s.selectCrop(s.selectedCrop == Item.corn ? Item.wheat : Item.corn);
    }
    if (fieldWork) spend(true);

    // start production for what orders need, then useful defaults
    for (final b in s.buildings.values) {
      if (!b.owned || left <= 0) continue;
      for (final r in s.unlockedRecipes(b).reversed) {
        if (b.isFull) break;
        final needed =
            miss.containsKey(r.output) ||
            _feedNeeded(r.output) ||
            (r.output == Item.flour && s.count(Item.flour) < 6) ||
            (r.output == Item.bread && s.count(Item.bread) < 3);
        if (!needed) continue;
        if (r.inputs.entries.every((e) => s.count(e.key) >= e.value)) {
          spend(s.startProduction(b, r).ok);
        }
      }
    }

    // spending
    _shop(spend);

    // skip orders that have been stuck for a long time
    for (var i = 0; i < s.orders.length; i++) {
      final o = s.orders[i];
      final key = o.hashCode;
      orderSeenAt.putIfAbsent(key, () => now);
      if (now - orderSeenAt[key]! > 150000) spend(s.skipOrder(i).ok);
    }

    // keep the barn from filling up with wheat
    if (s.stored > s.barnCapacity * 0.85 && s.count(Item.wheat) > 10) {
      spend(s.sell(Item.wheat, s.count(Item.wheat) - 10).ok);
    }
  }

  bool _feedNeeded(Item out) {
    if (out == Item.chickenFeed) {
      return s.pens[AnimalKind.chicken]!.animals.isNotEmpty && s.count(Item.chickenFeed) < 4;
    }
    if (out == Item.cowFeed) {
      return s.pens[AnimalKind.cow]!.animals.isNotEmpty && s.count(Item.cowFeed) < 4;
    }
    return false;
  }

  void _shop(bool Function(bool) spend) {
    for (final k in BuildingKind.values) {
      final b = s.buildings[k]!;
      if (!b.owned && s.isUnlocked(k) && s.coins >= b.def.price) spend(s.buyBuilding(b).ok);
    }
    if (s.isAnimalUnlocked(AnimalKind.chicken) &&
        s.buildings[BuildingKind.feedMill]!.owned &&
        s.pens[AnimalKind.chicken]!.animals.length < 3 &&
        s.coins >= animalDef(AnimalKind.chicken).price + 50) {
      spend(s.buyAnimal(AnimalKind.chicken).ok);
    }
    if (s.canBuyMorePlots && s.coins >= s.nextPlotPrice + 40) spend(s.buyPlot().ok);
    if (s.stored > s.barnCapacity * 0.8 && s.coins >= s.barnUpgradePrice + 50) {
      spend(s.upgradeBarn().ok);
    }
  }
}

void main() {
  test('a new player reaches level 5 with level-ups every few minutes', () {
    var now = DateTime(2026, 11, 20, 9).millisecondsSinceEpoch;
    final s = GameState(clock: () => now, random: Random(7));
    final bot = Bot(s);
    final levelAt = <int, double>{1: 0};
    var lastLevel = 1;
    s.onLevelUp = (l, _) => levelAt[l] = 0; // filled in below
    const step = 2; // seconds per bot turn (a player taps quickly)
    var t = 0;
    while (s.level < 8 && t < 60 * 60) {
      bot.turn(3);
      now += step * 1000;
      t += step;
      s.tick();
      if (t % 120 == 0) {
        // ignore: avoid_print
        print(
          't=${t ~/ 60}m lvl ${s.level} xp ${s.xp} coins ${s.coins} plots ${s.plots.length} '
          'owned ${s.buildings.values.where((b) => b.owned).length}',
        );
      }
      if (s.level != lastLevel) {
        for (var l = lastLevel + 1; l <= s.level; l++) {
          levelAt[l] = t / 60;
        }
        lastLevel = s.level;
      }
    }

    final lines = <String>[];
    for (var l = 2; l <= s.level; l++) {
      final gap = levelAt[l]! - levelAt[l - 1]!;
      lines.add(
        'level $l at ${levelAt[l]!.toStringAsFixed(1)} min '
        '(+${gap.toStringAsFixed(1)} min)',
      );
    }
    // ignore: avoid_print
    print(
      [
        ...lines,
        'coins ${s.coins}, gems ${s.gems}, plots ${s.plots.length}, '
            'barn ${s.stored}/${s.barnCapacity}, actions ${bot.actions}',
        'owned: ${s.buildings.values.where((b) => b.owned).map((b) => b.name).join(', ')}',
        'chickens ${s.pens[AnimalKind.chicken]!.animals.length}',
      ].join('\n'),
    );

    expect(s.level, greaterThanOrEqualTo(5), reason: 'should reach level 5 within an hour');
    for (var l = 3; l <= 5; l++) {
      final gap = levelAt[l]! - levelAt[l - 1]!;
      expect(gap, inInclusiveRange(1.5, 6.0), reason: 'level $l took $gap minutes');
    }
    // The first level should come fast so a new player feels progress.
    expect(levelAt[2], lessThan(4));
  });

  test('every recipe can actually be made from things the game gives', () {
    final makeable = <Item>{for (final c in GameConfig.crops) c.item};
    var changed = true;
    while (changed) {
      changed = false;
      for (final r in GameConfig.recipes) {
        if (!makeable.contains(r.output) && r.inputs.keys.every(makeable.contains)) {
          makeable.add(r.output);
          changed = true;
        }
      }
      for (final a in GameConfig.animals) {
        if (!makeable.contains(a.product) && makeable.contains(a.feed)) {
          makeable.add(a.product);
          changed = true;
        }
      }
    }
    expect(makeable, containsAll(Item.values));
    expect(cropFor(Item.wheat).unlockLevel, 1);
    expect(recipeById('bread')!.unlockLevel, 1);
  });
}
