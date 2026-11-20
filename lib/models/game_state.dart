import 'dart:math';

import 'package:flutter/foundation.dart';

import '../game_config.dart';
import 'action_result.dart';
import 'animal_pen.dart';
import 'defs.dart';
import 'item.dart';
import 'order.dart';
import 'plot.dart';
import 'production_building.dart';

/// Something new that a level unlocks (for the level-up screen).
class Unlock {
  const Unlock(this.icon, this.name);

  /// Icon name (see GameIconType), e.g. "corn".
  final String icon;
  final String name;
}

const List<String> customerNames = [
  'Farmer Joe',
  'Granny May',
  'Chef Leo',
  'Little Ana',
  'Mr. Baker',
  'Aunt Nora',
];

/// The whole game: money, items, land, buildings, animals, orders and
/// every rule. UI widgets and the Flame game both read from and call into
/// this class.
class GameState extends ChangeNotifier {
  GameState({int Function()? clock, Random? random})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
      _rnd = random ?? Random() {
    _resetValues();
  }

  final int Function() _clock;
  final Random _rnd;

  int coins = 0;
  int gems = 0;
  int xp = 0;
  final Map<Item, int> _items = {};
  final List<Plot> plots = [];
  final Map<BuildingKind, ProductionBuilding> buildings = {
    for (final k in BuildingKind.values) k: ProductionBuilding(k),
  };
  final Map<AnimalKind, AnimalPen> pens = {for (final k in AnimalKind.values) k: AnimalPen(k)};
  final List<Order> orders = [];
  int barnLevel = 0;
  Item selectedCrop = Item.wheat;

  /// First-time tutorial step (see [TutorialStep]); [TutorialStep.done] when finished.
  TutorialStep tutorial = TutorialStep.plant;

  // daily reward and goals
  int lastRewardDay = -1;
  int streak = 0;
  int goalsDay = -1;
  final List<Goal> goals = [];

  bool _dirty = false;
  final Set<Job> _announced = {};

  /// Called when a building finishes a job (sound + message in the UI).
  void Function(ProductionBuilding building, RecipeDef recipe)? onProductionDone;

  /// Called after reaching a new level, with what it unlocked.
  void Function(int level, List<Unlock> unlocks)? onLevelUp;

  int get nowMs => _clock();

  int count(Item item) => _items[item] ?? 0;

  ProductionBuilding get mill => buildings[BuildingKind.mill]!;
  ProductionBuilding get oven => buildings[BuildingKind.oven]!;

  // -------------------------------------------------------------- Levels

  /// Total XP needed to reach [level] (level 1 needs 0).
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    final table = GameConfig.levelXp;
    if (level - 2 < table.length) return table[level - 2];
    final extra = level - 1 - table.length;
    return table.last + extra * GameConfig.xpStepAfterTable;
  }

  int get level {
    var l = 1;
    while (xp >= xpForLevel(l + 1)) {
      l++;
    }
    return l;
  }

  /// Progress from 0 to 1 inside the current level.
  double get levelProgress {
    final l = level;
    final from = xpForLevel(l);
    final to = xpForLevel(l + 1);
    return ((xp - from) / (to - from)).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => xpForLevel(level + 1) - xp;

  static List<Unlock> unlocksAt(int level) => [
    for (final c in GameConfig.crops)
      if (c.unlockLevel == level) Unlock(c.item.name, '${c.item.label} seeds'),
    for (final b in GameConfig.buildings)
      if (b.unlockLevel == level) Unlock(_buildingIcon(b.kind), b.name),
    for (final a in GameConfig.animals)
      if (a.unlockLevel == level) Unlock(a.kind.name, '${a.name}s'),
    for (final r in GameConfig.recipes)
      if (r.unlockLevel == level) Unlock(r.output.name, r.output.label),
  ];

  static String _buildingIcon(BuildingKind k) => switch (k) {
    BuildingKind.mill => 'windmill',
    BuildingKind.oven => 'oven',
    BuildingKind.popcorn => 'popcornMachine',
    BuildingKind.feedMill => 'feedMill',
    BuildingKind.dairy => 'dairy',
  };

  void _addXp(int amount) {
    if (amount <= 0) return;
    final before = level;
    xp += amount;
    final after = level;
    for (var l = before + 1; l <= after; l++) {
      coins += GameConfig.levelUpCoinsBase + GameConfig.levelUpCoinsPerLevel * l;
      gems += GameConfig.levelUpGems;
      onLevelUp?.call(l, unlocksAt(l));
    }
    if (after > before) _refillOrders();
  }

  // --------------------------------------------------------------- Barn

  int get barnCapacity =>
      GameConfig.barnStartCapacity + barnLevel * GameConfig.barnCapacityPerUpgrade;

  int get stored => _items.values.fold(0, (a, b) => a + b);

  int get barnRoom => max(0, barnCapacity - stored);

  int get barnUpgradePrice =>
      (GameConfig.barnFirstUpgradePrice * pow(GameConfig.barnUpgradePriceMultiplier, barnLevel))
          .round();

  ActionResult upgradeBarn() {
    final price = barnUpgradePrice;
    if (coins < price) {
      return ActionResult.fail('Not enough coins! The upgrade costs $price $coinToken');
    }
    coins -= price;
    barnLevel++;
    _changed();
    return ActionResult.ok('Barn upgraded! Room for $barnCapacity items');
  }

  static const String _barnFull = 'Your barn is full! Sell or use some items first.';

  // ---------------------------------------------------------------- Land

  bool get canBuyMorePlots => plots.length < GameConfig.maxPlots;

  int get nextPlotPrice {
    final bought = plots.length - GameConfig.startingPlots;
    return (GameConfig.firstPlotPrice * pow(GameConfig.plotPriceMultiplier, max(0, bought)))
        .round();
  }

  List<CropDef> get unlockedCrops => GameConfig.crops.where((c) => c.unlockLevel <= level).toList();

  void selectCrop(Item crop) {
    if (!unlockedCrops.any((c) => c.item == crop)) return;
    selectedCrop = crop;
    _changed();
  }

  /// Plants on an empty plot, or harvests a ready one.
  ActionResult tapPlot(int index) {
    if (index < 0 || index >= plots.length) {
      return const ActionResult.fail('That plot is not yours yet.');
    }
    final plot = plots[index];
    final now = nowMs;

    if (plot.isEmpty) {
      final crop = unlockedCrops.any((c) => c.item == selectedCrop)
          ? cropFor(selectedCrop)
          : cropFor(Item.wheat);
      if (coins < crop.seedCost) {
        return ActionResult.fail(
          'Not enough coins! ${crop.item.label} seeds cost '
          '${crop.seedCost} $coinToken',
        );
      }
      coins -= crop.seedCost;
      plot.crop = crop.item;
      plot.plantedAtMs = now;
      _changed();
      return ActionResult.ok('-${crop.seedCost} $coinToken');
    }

    if (!plot.isReady(now)) {
      final secs = (plot.remainingMs(now) / 1000).ceil();
      return ActionResult.fail('Still growing... ${secs}s left');
    }

    final crop = cropFor(plot.crop);
    if (barnRoom < crop.harvest) return const ActionResult.fail(_barnFull);
    plot.plantedAtMs = null;
    _add(crop.item, crop.harvest);
    _progressGoals(GoalType.harvest, crop.item, crop.harvest);
    _addXp(crop.xp);
    _changed();
    return ActionResult.ok('+${crop.harvest} ${crop.item.token}');
  }

  ActionResult buyPlot() {
    if (!canBuyMorePlots) {
      return const ActionResult.fail('Your farm is full! (max ${GameConfig.maxPlots} plots)');
    }
    final price = nextPlotPrice;
    if (coins < price) {
      return ActionResult.fail('Not enough coins! A new plot costs $price $coinToken');
    }
    coins -= price;
    plots.add(Plot());
    _changed();
    return const ActionResult.ok('New field plot bought!');
  }

  // ----------------------------------------------------------- Buildings

  bool isUnlocked(BuildingKind kind) => buildingDef(kind).unlockLevel <= level;

  ActionResult buyBuilding(ProductionBuilding building) {
    final def = building.def;
    if (building.owned) return ActionResult.fail('You already own the ${def.name}.');
    if (!isUnlocked(building.kind)) {
      return ActionResult.fail('The ${def.name} unlocks at level ${def.unlockLevel}.');
    }
    if (coins < def.price) {
      return ActionResult.fail('Not enough coins! The ${def.name} costs ${def.price} $coinToken');
    }
    coins -= def.price;
    building.owned = true;
    _refillOrders();
    _changed();
    return ActionResult.ok('${def.name} built!');
  }

  List<RecipeDef> unlockedRecipes(ProductionBuilding b) =>
      b.recipes.where((r) => r.unlockLevel <= level).toList();

  /// Adds [recipe] to the building's queue (old name kept for the first recipe).
  ActionResult startProduction(ProductionBuilding building, [RecipeDef? recipe]) {
    final r = recipe ?? building.recipes.first;
    final name = building.name;
    if (!building.owned) return ActionResult.fail('Build the $name first.');
    if (r.unlockLevel > level) {
      return ActionResult.fail('${r.output.label} unlocks at level ${r.unlockLevel}.');
    }
    if (building.isFull) {
      return ActionResult.fail(
        building.readyCount(nowMs) > 0
            ? 'The $name is full. Collect the finished goods first!'
            : 'The $name is busy. Please wait!',
      );
    }
    for (final e in r.inputs.entries) {
      if (count(e.key) < e.value) {
        return ActionResult.fail(
          'Not enough ${e.key.label.toLowerCase()}! '
          'You need ${e.value} ${e.key.token}',
        );
      }
    }
    for (final e in r.inputs.entries) {
      _add(e.key, -e.value);
    }
    building.jobs.add(Job(r, building.nextEnd(nowMs, r)));
    _changed();
    return const ActionResult.ok();
  }

  /// Moves finished products from the building into the barn.
  /// Returns what was collected (empty when nothing fits).
  ({ActionResult result, Map<Item, int> items}) collect(ProductionBuilding building) {
    final now = nowMs;
    final got = <Item, int>{};
    var blocked = false;
    while (building.jobs.isNotEmpty && building.jobs.first.isReady(now)) {
      final j = building.jobs.first;
      if (barnRoom < j.recipe.outputAmount) {
        blocked = true;
        break;
      }
      building.jobs.removeAt(0);
      _announced.remove(j);
      _add(j.recipe.output, j.recipe.outputAmount);
      got[j.recipe.output] = (got[j.recipe.output] ?? 0) + j.recipe.outputAmount;
      _progressGoals(GoalType.make, j.recipe.output, j.recipe.outputAmount);
      _addXp(j.recipe.xp);
    }
    if (got.isEmpty) {
      return (result: ActionResult.fail(blocked ? _barnFull : 'Nothing is ready yet.'), items: got);
    }
    _changed();
    final text = got.entries.map((e) => '+${e.value} ${e.key.token}').join('  ');
    return (result: ActionResult.ok(blocked ? '$text  (barn is full!)' : text), items: got);
  }

  /// Gems needed to finish the current job right away.
  int speedUpCost(ProductionBuilding building) {
    final j = building.working(nowMs);
    if (j == null) return 0;
    final secs = ((j.endMs - nowMs) / 1000).ceil();
    return max(1, (secs / GameConfig.speedUpSecondsPerGem).ceil());
  }

  /// Finishes the current job now with gems; the jobs after it move up.
  ActionResult speedUp(ProductionBuilding building) {
    final now = nowMs;
    final j = building.working(now);
    if (j == null) return const ActionResult.fail('Nothing to speed up.');
    final cost = speedUpCost(building);
    if (gems < cost) return ActionResult.fail('Not enough gems! You need $cost $gemToken');
    gems -= cost;
    final saved = j.endMs - now;
    for (final other in building.jobs) {
      if (other.endMs >= j.endMs) other.endMs -= saved;
    }
    _changed();
    return ActionResult.ok('Done! -$cost $gemToken');
  }

  /// Price of the next extra queue slot, or null when maxed out.
  int? queueUpgradePrice(ProductionBuilding building) {
    final prices = GameConfig.queueUpgradePrices;
    return building.extraSlots < prices.length ? prices[building.extraSlots] : null;
  }

  ActionResult upgradeQueue(ProductionBuilding building) {
    final price = queueUpgradePrice(building);
    if (price == null) return const ActionResult.fail('This building has the most slots already.');
    if (coins < price) return ActionResult.fail('Not enough coins! It costs $price $coinToken');
    coins -= price;
    building.extraSlots++;
    _changed();
    return ActionResult.ok('${building.name} now holds ${building.slots} jobs!');
  }

  // ------------------------------------------------------------- Animals

  bool isAnimalUnlocked(AnimalKind kind) => animalDef(kind).unlockLevel <= level;

  ActionResult buyAnimal(AnimalKind kind) {
    final pen = pens[kind]!;
    final def = pen.def;
    if (!isAnimalUnlocked(kind)) {
      return ActionResult.fail('${def.name}s unlock at level ${def.unlockLevel}.');
    }
    if (pen.animals.length >= def.maxCount) {
      return ActionResult.fail('The ${def.penName} is full!');
    }
    if (coins < def.price) {
      return ActionResult.fail(
        'Not enough coins! A ${def.name.toLowerCase()} costs '
        '${def.price} $coinToken',
      );
    }
    coins -= def.price;
    pen.animals.add(Animal());
    _refillOrders();
    _changed();
    return ActionResult.ok('New ${def.name.toLowerCase()}!');
  }

  /// Collects ready products, then feeds every hungry animal there is feed for.
  ({ActionResult result, int collected, int fed}) tendPen(AnimalKind kind) {
    final pen = pens[kind]!;
    final def = pen.def;
    final now = nowMs;
    if (pen.animals.isEmpty) {
      return (
        result: ActionResult.fail('Buy a ${def.name.toLowerCase()} in the Shop first.'),
        collected: 0,
        fed: 0,
      );
    }
    var collected = 0;
    var full = false;
    for (final a in pen.animals) {
      if (pen.isReady(a, now)) {
        if (barnRoom < 1) {
          full = true;
          break;
        }
        a.fedAtMs = null;
        _add(def.product, 1);
        collected++;
      }
    }
    if (collected > 0) {
      _progressGoals(GoalType.collect, def.product, collected);
      _addXp(def.xp * collected);
    }
    var fed = 0;
    for (final a in pen.animals) {
      if (a.isHungry && count(def.feed) > 0) {
        _add(def.feed, -1);
        a.fedAtMs = now;
        fed++;
      }
    }
    if (collected == 0 && fed == 0) {
      if (full) return (result: const ActionResult.fail(_barnFull), collected: 0, fed: 0);
      final busy = pen.animals.any((a) => pen.isProducing(a, now));
      return (
        result: ActionResult.fail(
          busy && pen.hungryCount() == 0
              ? 'The ${def.name.toLowerCase()}s are busy. Come back soon!'
              : 'You need ${def.feed.label.toLowerCase()} ${def.feed.token} to feed them.',
        ),
        collected: 0,
        fed: 0,
      );
    }
    _changed();
    final parts = [
      if (collected > 0) '+$collected ${def.product.token}',
      if (fed > 0) 'Fed $fed ${def.name.toLowerCase()}${fed == 1 ? '' : 's'}',
      if (full) '(barn is full!)',
    ];
    return (result: ActionResult.ok(parts.join('  ')), collected: collected, fed: fed);
  }

  // -------------------------------------------------------------- Market

  ActionResult sell(Item item, int amount) {
    if (amount <= 0 || count(item) < amount) {
      return ActionResult.fail('You have no ${item.label.toLowerCase()} to sell ${item.token}');
    }
    final earned = amount * item.sellPrice;
    _add(item, -amount);
    coins += earned;
    _progressGoals(GoalType.sell, null, amount);
    _changed();
    return ActionResult.ok('Sold $amount ${item.token} for $earned $coinToken');
  }

  ActionResult sellAll(Item item) => sell(item, count(item));

  // -------------------------------------------------------------- Orders

  /// Items that orders may ask for: things the player can make right now.
  /// Only things whose whole chain is possible count (bread needs a mill
  /// for the flour, eggs need chickens and a feed mill...).
  List<Item> get orderableItems {
    final makeable = <Item>{for (final c in unlockedCrops) c.item};
    var grew = true;
    while (grew) {
      grew = false;
      for (final b in buildings.values) {
        if (!b.owned) continue;
        for (final r in unlockedRecipes(b)) {
          if (!makeable.contains(r.output) && r.inputs.keys.every(makeable.contains)) {
            makeable.add(r.output);
            grew = true;
          }
        }
      }
      for (final p in pens.values) {
        if (p.animals.isNotEmpty && makeable.contains(p.def.feed) && makeable.add(p.def.product)) {
          grew = true;
        }
      }
    }
    makeable.removeAll([Item.chickenFeed, Item.cowFeed]);
    return makeable.toList();
  }

  Order _newOrder({int readyAtMs = 0}) {
    final lvl = level;
    final pool = orderableItems..shuffle(_rnd);
    final maxLines = lvl < 3 ? 1 : (lvl < 6 ? 2 : 3);
    final lines = min(pool.length, 1 + _rnd.nextInt(maxLines));
    // prefer the most valuable things the player can make
    final items = <Item, int>{};
    for (final item in pool.take(lines)) {
      final isCrop = GameConfig.crops.any((c) => c.item == item);
      final maxQty = isCrop ? 3 + lvl : (item.sellPrice < 15 ? 2 + lvl ~/ 2 : 1 + lvl ~/ 3);
      final minQty = isCrop ? 3 : 1;
      items[item] = minQty + _rnd.nextInt(max(1, min(maxQty, 10) - minQty + 1));
    }
    final value = items.entries.fold<int>(0, (a, e) => a + e.key.sellPrice * e.value);
    final coinsReward = ((value * GameConfig.orderCoinBonus) / 5).ceil() * 5;
    final xpReward = GameConfig.orderBaseXp + (value * GameConfig.orderXpPerCoin).round();
    return Order(
      items: items,
      coins: coinsReward,
      xp: xpReward,
      gems: _rnd.nextDouble() < GameConfig.orderGemChance ? 1 : 0,
      customer: _rnd.nextInt(customerNames.length),
      readyAtMs: readyAtMs,
    );
  }

  void _refillOrders() {
    while (orders.length < GameConfig.orderSlots) {
      orders.add(_newOrder());
    }
  }

  bool canFill(Order o) =>
      !o.isWaiting(nowMs) && o.items.entries.every((e) => count(e.key) >= e.value);

  /// How many orders can be delivered right now.
  int get fillableOrders => orders.where(canFill).length;

  ActionResult fillOrder(int index) {
    if (index < 0 || index >= orders.length) return const ActionResult.fail('No such order.');
    final o = orders[index];
    if (o.isWaiting(nowMs)) return const ActionResult.fail('A new customer is on the way!');
    for (final e in o.items.entries) {
      if (count(e.key) < e.value) {
        return ActionResult.fail('You need ${e.value - count(e.key)} more ${e.key.token}');
      }
    }
    for (final e in o.items.entries) {
      _add(e.key, -e.value);
    }
    coins += o.coins;
    gems += o.gems;
    orders[index] = _newOrder(readyAtMs: nowMs + GameConfig.orderRefillWait.inMilliseconds);
    _progressGoals(GoalType.fillOrders, null, 1);
    if (tutorial == TutorialStep.deliver) tutorial = TutorialStep.done;
    _addXp(o.xp);
    _changed();
    return ActionResult.ok(
      'Order done! +${o.coins} $coinToken  +${o.xp} $xpToken'
      '${o.gems > 0 ? '  +${o.gems} $gemToken' : ''}',
    );
  }

  /// Throws an order away; a new customer arrives after a short wait.
  ActionResult skipOrder(int index) {
    if (index < 0 || index >= orders.length) return const ActionResult.fail('No such order.');
    orders[index] = _newOrder(readyAtMs: nowMs + GameConfig.orderSkipWait.inMilliseconds);
    _changed();
    return const ActionResult.ok('A new customer will come soon.');
  }

  // --------------------------------------------------------------- Daily

  /// Days since 1970 in the player's local calendar.
  int get today {
    final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
  }

  bool get canClaimDaily => lastRewardDay != today;

  /// Which day of the 7-day streak the next claim is (1..7).
  int get nextStreakDay {
    final continues = lastRewardDay == today - 1 || lastRewardDay == today;
    final s = continues ? streak : 0;
    if (lastRewardDay == today) return ((s - 1) % 7) + 1;
    return (s % 7) + 1;
  }

  int dailyCoinsFor(int day) => GameConfig.dailyRewardCoins[(day - 1) % 7];
  int dailyGemsFor(int day) => GameConfig.dailyRewardGems[(day - 1) % 7];

  ActionResult claimDaily() {
    if (!canClaimDaily) return const ActionResult.fail('Come back tomorrow for more!');
    final day = nextStreakDay;
    streak = lastRewardDay == today - 1 ? streak + 1 : 1;
    lastRewardDay = today;
    final c = dailyCoinsFor(day);
    final g = dailyGemsFor(day);
    coins += c;
    gems += g;
    _changed();
    return ActionResult.ok('Day $day reward: +$c $coinToken${g > 0 ? '  +$g $gemToken' : ''}');
  }

  /// Makes sure today's goals exist (new goals each day).
  void _ensureGoals() {
    final d = today;
    if (goalsDay == d && goals.isNotEmpty) return;
    goalsDay = d;
    goals.clear();
    final rnd = Random(d * 7919 + level);
    final open = [
      for (var i = 0; i < GameConfig.goals.length; i++)
        if (GameConfig.goals[i].unlockLevel <= level) i,
    ]..shuffle(rnd);
    goals.addAll(open.take(3).map(Goal.new));
  }

  List<Goal> get todaysGoals {
    _ensureGoals();
    return goals;
  }

  GoalDef goalDef(Goal g) => GameConfig.goals[g.defIndex];

  bool goalDone(Goal g) => g.progress >= goalDef(g).target;

  int get claimableGoals => todaysGoals.where((g) => goalDone(g) && !g.claimed).length;

  void _progressGoals(GoalType type, Item? item, int amount) {
    _ensureGoals();
    for (final g in goals) {
      final d = goalDef(g);
      if (d.type == type && (d.item == null || d.item == item) && !g.claimed) {
        g.progress = min(d.target, g.progress + amount);
      }
    }
  }

  ActionResult claimGoal(int index) {
    _ensureGoals();
    if (index < 0 || index >= goals.length) return const ActionResult.fail('No such goal.');
    final g = goals[index];
    if (g.claimed) return const ActionResult.fail('Already claimed.');
    if (!goalDone(g)) return const ActionResult.fail('Not finished yet. Keep going!');
    g.claimed = true;
    coins += GameConfig.goalRewardCoins;
    _addXp(GameConfig.goalRewardXp);
    _changed();
    return const ActionResult.ok(
      'Goal reward: +${GameConfig.goalRewardCoins} $coinToken  +${GameConfig.goalRewardXp} $xpToken',
    );
  }

  // --------------------------------------------------------------- Clock

  /// Called several times per second. Announces finished jobs and keeps
  /// progress bars moving.
  void tick() {
    final now = nowMs;
    for (final b in buildings.values) {
      for (final j in b.jobs) {
        if (j.isReady(now) && _announced.add(j)) {
          onProductionDone?.call(b, j.recipe);
        }
      }
    }
    _ensureGoals();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Save

  /// Returns true once after something changed, so it can be saved.
  bool consumeDirty() {
    final wasDirty = _dirty;
    _dirty = false;
    return wasDirty;
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'gems': gems,
    'coins': coins,
    'xp': xp,
    'items': {for (final i in Item.values) i.name: count(i)},
    'plots': [for (final p in plots) p.toJson()],
    'buildings': {for (final e in buildings.entries) e.key.name: e.value.toJson()},
    'pens': {for (final e in pens.entries) e.key.name: e.value.toJson()},
    'orders': [for (final o in orders) o.toJson()],
    'barnLevel': barnLevel,
    'tutorial': tutorial.name,
    'selectedCrop': selectedCrop.name,
    'daily': {
      'lastReward': lastRewardDay,
      'streak': streak,
      'goalsDay': goalsDay,
      'goals': [for (final g in goals) g.toJson()],
    },
  };

  /// Loads a save. Works with the first version of the game too
  /// (only coins, items, plots, mill and oven).
  void loadFromJson(Map<String, dynamic> json) {
    _resetValues();
    final c = json['coins'];
    if (c is int) coins = c;
    final gm = json['gems'];
    if (gm is int && gm >= 0) gems = gm;
    final x = json['xp'];
    if (x is int && x >= 0) xp = x;

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
        ..addAll(savedPlots.take(GameConfig.maxPlots).map(Plot.fromJson));
    }

    final b = json['buildings'];
    for (final kind in BuildingKind.values) {
      final data = b is Map ? b[kind.name] : null;
      buildings[kind]!.loadFromJson(data is Map<String, dynamic> ? data : null);
    }
    // version 1 saves kept the mill and oven at the top level
    for (final (key, kind) in [('mill', BuildingKind.mill), ('oven', BuildingKind.oven)]) {
      final data = json[key];
      if (data is Map<String, dynamic>) buildings[kind]!.loadFromJson(data);
    }

    final p = json['pens'];
    if (p is Map) {
      for (final kind in AnimalKind.values) {
        pens[kind]!.loadFromJson(p[kind.name]);
      }
    }

    final o = json['orders'];
    orders.clear();
    if (o is List) {
      for (final e in o.take(GameConfig.orderSlots)) {
        final order = Order.fromJson(e);
        if (order != null) orders.add(order);
      }
    }
    _refillOrders();

    // Saves from before the tutorial existed skip it.
    tutorial = TutorialStep.values.asNameMap()[json['tutorial']] ?? TutorialStep.done;
    final bl = json['barnLevel'];
    if (bl is int && bl >= 0) barnLevel = bl;
    final sc = Item.values.asNameMap()[json['selectedCrop']];
    if (sc != null && GameConfig.crops.any((d) => d.item == sc)) selectedCrop = sc;

    final d = json['daily'];
    if (d is Map) {
      if (d['lastReward'] is int) lastRewardDay = d['lastReward'] as int;
      if (d['streak'] is int) streak = d['streak'] as int;
      final gd = d['goalsDay'];
      final gl = d['goals'];
      if (gd is int && gl is List) {
        goalsDay = gd;
        for (final g in gl) {
          if (g is! Map) continue;
          final i = g['d'];
          final pr = g['p'];
          if (i is int && i >= 0 && i < GameConfig.goals.length) {
            goals.add(Goal(i, progress: pr is int ? pr : 0, claimed: g['c'] == true));
          }
        }
      }
    }

    // Jobs that finished while the app was closed don't need a message.
    _announced
      ..clear()
      ..addAll([
        for (final bld in buildings.values)
          for (final j in bld.jobs)
            if (j.isReady(nowMs)) j,
      ]);
    _ensureGoals();
    notifyListeners();
  }

  void resetGame() {
    _resetValues();
    _changed();
  }

  // ------------------------------------------------------------- Helpers

  void _resetValues() {
    coins = GameConfig.startingCoins;
    gems = GameConfig.startingGems;
    xp = 0;
    barnLevel = 0;
    selectedCrop = Item.wheat;
    tutorial = TutorialStep.plant;
    _items
      ..clear()
      ..addAll({for (final i in Item.values) i: 0});
    plots
      ..clear()
      ..addAll(List.generate(GameConfig.startingPlots, (_) => Plot()));
    for (final b in buildings.values) {
      b.owned = GameConfig.startingBuildings.contains(b.kind);
      b.jobs.clear();
      b.extraSlots = 0;
    }
    for (final p in pens.values) {
      p.animals.clear();
    }
    lastRewardDay = -1;
    streak = 0;
    goalsDay = -1;
    goals.clear();
    _announced.clear();
    orders.clear();
    _refillOrders();
  }

  void _add(Item item, int amount) => _items[item] = count(item) + amount;

  // ------------------------------------------------------------ Tutorial

  /// Moves the tutorial forward when the current step is done.
  void _advanceTutorial() {
    var moved = true;
    while (moved) {
      moved = false;
      final next = switch (tutorial) {
        TutorialStep.plant when plots.any((p) => !p.isEmpty) || count(Item.wheat) > 0 =>
          TutorialStep.harvest,
        TutorialStep.harvest when count(Item.wheat) >= tutorialWheatNeeded =>
          TutorialStep.buildMill,
        TutorialStep.buildMill when mill.owned => TutorialStep.makeFlour,
        TutorialStep.makeFlour when count(Item.flour) >= 2 => TutorialStep.bakeBread,
        TutorialStep.bakeBread when count(Item.bread) >= 1 => TutorialStep.deliver,
        _ => null,
      };
      if (next != null) {
        tutorial = next;
        moved = true;
        if (next == TutorialStep.deliver) _addTutorialOrder();
      }
    }
  }

  /// Wheat needed for two flour (= one bread).
  static const int tutorialWheatNeeded = 4;

  /// The first customer wants exactly the bread the player just baked.
  void _addTutorialOrder() {
    if (orders.any((o) => o.items.length == 1 && o.items[Item.bread] == 1)) return;
    final order = Order(items: {Item.bread: 1}, coins: 60, xp: 20, gems: 1, customer: 1);
    if (orders.isEmpty) {
      orders.add(order);
    } else {
      orders[0] = order;
    }
  }

  /// Skips the rest of the tutorial.
  void skipTutorial() {
    tutorial = TutorialStep.done;
    _changed();
  }

  void _changed() {
    _advanceTutorial();
    _dirty = true;
    notifyListeners();
  }
}

/// The steps of the first-time tutorial, in order.
enum TutorialStep { plant, harvest, buildMill, makeFlour, bakeBread, deliver, done }
