import '../game_config.dart';
import 'item.dart';

/// What a building costs and what it converts.
class Recipe {
  const Recipe({
    required this.buildingName,
    required this.emoji,
    required this.actionVerb,
    required this.price,
    required this.input,
    required this.inputAmount,
    required this.output,
    required this.outputAmount,
    required this.duration,
  });

  final String buildingName;
  final String emoji;
  final String actionVerb;
  final int price;
  final Item input;
  final int inputAmount;
  final Item output;
  final int outputAmount;
  final Duration duration;

  static const mill = Recipe(
    buildingName: 'Mill',
    emoji: '🏭',
    actionVerb: 'Grind',
    price: GameConfig.millPrice,
    input: Item.wheat,
    inputAmount: GameConfig.millWheatInput,
    output: Item.flour,
    outputAmount: GameConfig.millFlourOutput,
    duration: GameConfig.millTime,
  );

  static const oven = Recipe(
    buildingName: 'Oven',
    emoji: '🔥',
    actionVerb: 'Bake',
    price: GameConfig.ovenPrice,
    input: Item.flour,
    inputAmount: GameConfig.ovenFlourInput,
    output: Item.bread,
    outputAmount: GameConfig.ovenBreadOutput,
    duration: GameConfig.ovenTime,
  );
}

/// A building (mill or oven) that runs one batch at a time.
class ProductionBuilding {
  ProductionBuilding(this.recipe);

  final Recipe recipe;
  bool owned = false;

  /// Wall-clock time (ms since epoch) when the current batch started.
  int? jobStartedAtMs;

  bool get isWorking => jobStartedAtMs != null;

  int get _durationMs => recipe.duration.inMilliseconds;

  double progress(int nowMs) {
    if (jobStartedAtMs == null) return 0;
    return ((nowMs - jobStartedAtMs!) / _durationMs).clamp(0.0, 1.0);
  }

  int remainingMs(int nowMs) {
    if (jobStartedAtMs == null) return 0;
    return (jobStartedAtMs! + _durationMs - nowMs).clamp(0, _durationMs);
  }

  Map<String, dynamic> toJson() => {
        'owned': owned,
        'jobStartedAtMs': jobStartedAtMs,
      };

  void loadFromJson(Map<String, dynamic>? json) {
    owned = json?['owned'] == true;
    final started = json?['jobStartedAtMs'];
    jobStartedAtMs = owned && started is int ? started : null;
  }
}
