import '../game_config.dart';

/// Things the player can own and sell.
enum Item { wheat, flour, bread }

extension ItemInfo on Item {
  String get emoji => switch (this) {
        Item.wheat => '🌾',
        Item.flour => '🥣',
        Item.bread => '🍞',
      };

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

/// Emoji used for coins everywhere in the game.
const String coinEmoji = '💰';
