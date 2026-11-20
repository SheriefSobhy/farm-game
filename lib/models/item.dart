import '../game_config.dart';

/// Things the player can store, use and sell.
enum Item { wheat, corn, flour, bread, popcorn, chickenFeed, egg, cake, cowFeed, milk, cheese }

extension ItemInfo on Item {
  /// Placeholder in messages that the UI replaces with this item's icon,
  /// e.g. "Sold 3 {wheat}".
  String get token => '{$name}';

  String get label => switch (this) {
    Item.wheat => 'Wheat',
    Item.corn => 'Corn',
    Item.flour => 'Flour',
    Item.bread => 'Bread',
    Item.popcorn => 'Popcorn',
    Item.chickenFeed => 'Chicken feed',
    Item.egg => 'Egg',
    Item.cake => 'Cake',
    Item.cowFeed => 'Cow feed',
    Item.milk => 'Milk',
    Item.cheese => 'Cheese',
  };

  int get sellPrice => GameConfig.sellPrices[this]!;
}

/// Placeholder in messages that the UI replaces with a coin icon.
const String coinToken = '{coin}';
const String xpToken = '{star}';
const String gemToken = '{gem}';
