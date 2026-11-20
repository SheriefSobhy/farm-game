import '../game_config.dart';

/// Things the player can own and sell.
enum Item { wheat, flour, bread }

extension ItemInfo on Item {
  /// Placeholder in messages that the UI replaces with this item's icon,
  /// e.g. "Sold 3 {wheat}".
  String get token => '{$name}';

  String get label => switch (this) {
    Item.wheat => 'Wheat',
    Item.flour => 'Flour',
    Item.bread => 'Bread',
  };

  int get sellPrice => switch (this) {
    Item.wheat => GameConfig.wheatSellPrice,
    Item.flour => GameConfig.flourSellPrice,
    Item.bread => GameConfig.breadSellPrice,
  };
}

/// Placeholder in messages that the UI replaces with a coin icon.
const String coinToken = '{coin}';
