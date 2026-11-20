import 'models/defs.dart';
import 'models/item.dart';

/// All game balance numbers live here: prices, times, recipes, levels.
/// Change a value, then hot-restart the app to try it out.
class GameConfig {
  GameConfig._();

  // --- Start of a new game ---
  static const int startingCoins = 150;
  static const int startingPlots = 1;

  /// Buildings a brand-new farm already has.
  static const List<BuildingKind> startingBuildings = [BuildingKind.oven];

  // --- Land ---
  static const int maxPlots = 9;
  static const int gridColumns = 3;

  /// Price of the 2nd plot. Each further plot costs [plotPriceMultiplier] times more.
  static const int firstPlotPrice = 50;
  static const double plotPriceMultiplier = 1.5;

  // --- Old names kept for the first crop and buildings ---
  static const int wheatSeedCost = 5;
  static const Duration wheatGrowTime = Duration(seconds: 5);
  static const int wheatPerHarvest = 3;
  static const int millPrice = 100;
  static const Duration millTime = Duration(seconds: 3);
  static const int ovenPrice = 250;
  static const Duration ovenTime = Duration(seconds: 5);

  // --- Crops ---
  static const List<CropDef> crops = [
    CropDef(
      item: Item.wheat,
      seedCost: wheatSeedCost,
      growTime: wheatGrowTime,
      harvest: wheatPerHarvest,
      xp: 1,
      unlockLevel: 1,
    ),
    CropDef(
      item: Item.corn,
      seedCost: 10,
      growTime: Duration(seconds: 15),
      harvest: 3,
      xp: 2,
      unlockLevel: 3,
    ),
  ];

  // --- Buildings ---
  static const List<BuildingDef> buildings = [
    BuildingDef(
      kind: BuildingKind.mill,
      name: 'Mill',
      verb: 'Grinding',
      price: millPrice,
      unlockLevel: 1,
    ),
    BuildingDef(
      kind: BuildingKind.oven,
      name: 'Oven',
      verb: 'Baking',
      price: ovenPrice,
      unlockLevel: 1,
    ),
    BuildingDef(
      kind: BuildingKind.popcorn,
      name: 'Popcorn Pot',
      verb: 'Popping',
      price: 450,
      unlockLevel: 3,
    ),
    BuildingDef(
      kind: BuildingKind.feedMill,
      name: 'Feed Mill',
      verb: 'Mixing',
      price: 400,
      unlockLevel: 5,
    ),
    BuildingDef(
      kind: BuildingKind.dairy,
      name: 'Dairy',
      verb: 'Churning',
      price: 900,
      unlockLevel: 7,
    ),
  ];

  /// How many jobs a building can hold at once (working + waiting + done).
  static const int queueSlots = 3;

  /// Extra queue slots: price in coins of each upgrade (the list length is
  /// the maximum number of upgrades).
  static const List<int> queueUpgradePrices = [150, 400, 900];

  // --- Recipes ---
  static const List<RecipeDef> recipes = [
    RecipeDef(
      id: 'flour',
      building: BuildingKind.mill,
      inputs: {Item.wheat: 2},
      output: Item.flour,
      time: millTime,
      xp: 2,
      unlockLevel: 1,
    ),
    RecipeDef(
      id: 'bread',
      building: BuildingKind.oven,
      inputs: {Item.flour: 2},
      output: Item.bread,
      time: ovenTime,
      xp: 4,
      unlockLevel: 1,
    ),
    RecipeDef(
      id: 'popcorn',
      building: BuildingKind.popcorn,
      inputs: {Item.corn: 2},
      output: Item.popcorn,
      time: Duration(seconds: 12),
      xp: 5,
      unlockLevel: 3,
    ),
    RecipeDef(
      id: 'chickenFeed',
      building: BuildingKind.feedMill,
      inputs: {Item.corn: 1},
      output: Item.chickenFeed,
      outputAmount: 3,
      time: Duration(seconds: 6),
      xp: 1,
      unlockLevel: 5,
    ),
    RecipeDef(
      id: 'cake',
      building: BuildingKind.oven,
      inputs: {Item.flour: 1, Item.egg: 2},
      output: Item.cake,
      time: Duration(seconds: 30),
      xp: 10,
      unlockLevel: 5,
    ),
    RecipeDef(
      id: 'cowFeed',
      building: BuildingKind.feedMill,
      inputs: {Item.corn: 1, Item.wheat: 2},
      output: Item.cowFeed,
      outputAmount: 3,
      time: Duration(seconds: 10),
      xp: 2,
      unlockLevel: 7,
    ),
    RecipeDef(
      id: 'cheese',
      building: BuildingKind.dairy,
      inputs: {Item.milk: 2},
      output: Item.cheese,
      time: Duration(seconds: 50),
      xp: 12,
      unlockLevel: 7,
    ),
  ];

  // --- Animals ---
  static const List<AnimalDef> animals = [
    AnimalDef(
      kind: AnimalKind.chicken,
      name: 'Chicken',
      penName: 'Chicken Coop',
      feed: Item.chickenFeed,
      product: Item.egg,
      time: Duration(seconds: 20),
      price: 60,
      maxCount: 5,
      xp: 2,
      unlockLevel: 5,
    ),
    AnimalDef(
      kind: AnimalKind.cow,
      name: 'Cow',
      penName: 'Cow Pasture',
      feed: Item.cowFeed,
      product: Item.milk,
      time: Duration(seconds: 40),
      price: 150,
      maxCount: 4,
      xp: 4,
      unlockLevel: 7,
    ),
  ];

  // --- Market: coins per item ---
  static const Map<Item, int> sellPrices = {
    Item.wheat: 2,
    Item.corn: 4,
    Item.flour: 8,
    Item.bread: 25,
    Item.popcorn: 22,
    Item.chickenFeed: 3,
    Item.egg: 10,
    Item.cake: 70,
    Item.cowFeed: 6,
    Item.milk: 18,
    Item.cheese: 60,
  };

  // Old names, used by older code and tests.
  static int get wheatSellPrice => sellPrices[Item.wheat]!;
  static int get flourSellPrice => sellPrices[Item.flour]!;
  static int get breadSellPrice => sellPrices[Item.bread]!;

  // --- Levels and XP ---
  /// Total XP needed to reach level 2, 3, 4, ... After the list ends each
  /// level needs [xpStepAfterTable] more than the one before.
  static const List<int> levelXp = [40, 300, 720, 1180, 1700, 2350, 3200, 4300, 5600, 7100];
  static const int xpStepAfterTable = 1800;

  /// Coins given on reaching a new level: base + perLevel * level.
  static const int levelUpCoinsBase = 20;
  static const int levelUpCoinsPerLevel = 10;

  /// Gems given on reaching a new level.
  static const int levelUpGems = 2;

  // --- Orders board ---
  static const int orderSlots = 3;

  /// Order rewards are the market value times this, rounded up to 5 coins.
  static const double orderCoinBonus = 1.5;

  /// Order XP = orderBaseXp + market value of the order x orderXpPerCoin.
  static const int orderBaseXp = 2;
  static const double orderXpPerCoin = 0.25;

  /// Wait before the next customer comes after an order is delivered.
  static const Duration orderRefillWait = Duration(seconds: 25);

  /// Wait before an empty order slot gets a new order after skipping.
  static const Duration orderSkipWait = Duration(seconds: 20);

  // --- Barn (storage) ---
  static const int barnStartCapacity = 50;
  static const int barnCapacityPerUpgrade = 25;
  static const int barnFirstUpgradePrice = 150;
  static const double barnUpgradePriceMultiplier = 1.6;

  // --- Daily reward: coins for streak day 1..7 (day 7 is the big one) ---
  static const List<int> dailyRewardCoins = [30, 40, 50, 60, 80, 100, 250];
  static const List<int> dailyRewardGems = [0, 0, 1, 0, 0, 1, 5];

  // --- Gems (second currency) ---
  static const int startingGems = 5;

  /// Speeding up costs 1 gem for every this many seconds left (at least 1).
  static const int speedUpSecondsPerGem = 20;

  /// Chance that an order also pays a gem.
  static const double orderGemChance = 0.25;

  // --- Daily goals (3 are picked each day from those unlocked) ---
  static const List<GoalDef> goals = [
    GoalDef(GoalType.harvest, 20, item: Item.wheat),
    GoalDef(GoalType.make, 5, item: Item.flour),
    GoalDef(GoalType.make, 3, item: Item.bread),
    GoalDef(GoalType.fillOrders, 2),
    GoalDef(GoalType.sell, 15),
    GoalDef(GoalType.harvest, 12, item: Item.corn, unlockLevel: 3),
    GoalDef(GoalType.make, 3, item: Item.popcorn, unlockLevel: 3),
    GoalDef(GoalType.fillOrders, 4, unlockLevel: 3),
    GoalDef(GoalType.collect, 6, item: Item.egg, unlockLevel: 5),
    GoalDef(GoalType.make, 2, item: Item.cake, unlockLevel: 5),
    GoalDef(GoalType.collect, 4, item: Item.milk, unlockLevel: 7),
    GoalDef(GoalType.make, 2, item: Item.cheese, unlockLevel: 7),
  ];
  static const int goalRewardCoins = 40;
  static const int goalRewardXp = 10;

  // --- Technical ---
  /// How often progress is written to the phone's storage.
  static const Duration autoSaveInterval = Duration(seconds: 2);
}
