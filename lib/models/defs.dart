import 'item.dart';

/// A crop that grows on a field plot.
class CropDef {
  const CropDef({
    required this.item,
    required this.seedCost,
    required this.growTime,
    required this.harvest,
    required this.xp,
    required this.unlockLevel,
  });

  /// What you get when harvesting (and what the crop is called).
  final Item item;
  final int seedCost;
  final Duration growTime;

  /// How many items one plot gives.
  final int harvest;

  /// XP for harvesting one plot.
  final int xp;
  final int unlockLevel;
}

/// Buildings that turn items into other items.
enum BuildingKind { mill, oven, popcorn, feedMill, dairy }

/// One thing a building can make.
class RecipeDef {
  const RecipeDef({
    required this.id,
    required this.building,
    required this.inputs,
    required this.output,
    this.outputAmount = 1,
    required this.time,
    required this.xp,
    required this.unlockLevel,
  });

  final String id;
  final BuildingKind building;
  final Map<Item, int> inputs;
  final Item output;
  final int outputAmount;
  final Duration time;

  /// XP when the product is collected.
  final int xp;
  final int unlockLevel;
}

class BuildingDef {
  const BuildingDef({
    required this.kind,
    required this.name,
    required this.verb,
    required this.price,
    required this.unlockLevel,
  });

  final BuildingKind kind;
  final String name;

  /// Shown while working, e.g. "Grinding".
  final String verb;
  final int price;
  final int unlockLevel;
}

/// Animals that live in a pen, eat feed and give a product.
enum AnimalKind { chicken, cow }

class AnimalDef {
  const AnimalDef({
    required this.kind,
    required this.name,
    required this.penName,
    required this.feed,
    required this.product,
    required this.time,
    required this.price,
    required this.maxCount,
    required this.xp,
    required this.unlockLevel,
  });

  final AnimalKind kind;
  final String name;
  final String penName;
  final Item feed;
  final Item product;
  final Duration time;

  /// Price of one animal; the pen itself comes free with the first one.
  final int price;
  final int maxCount;

  /// XP for collecting one product.
  final int xp;
  final int unlockLevel;
}

/// What a daily goal counts.
enum GoalType { harvest, make, collect, fillOrders, sell }

/// A daily goal template, e.g. "Harvest 20 wheat".
class GoalDef {
  const GoalDef(this.type, this.target, {this.item, this.unlockLevel = 1});

  final GoalType type;
  final Item? item;
  final int target;
  final int unlockLevel;
}
