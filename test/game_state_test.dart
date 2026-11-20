import 'package:farm_game/game_config.dart';
import 'package:farm_game/models/game_state.dart';
import 'package:farm_game/models/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int now;
  late GameState state;

  setUp(() {
    now = 1000000;
    state = GameState(clock: () => now);
  });

  test('starts with configured coins and plots', () {
    expect(state.coins, GameConfig.startingCoins);
    expect(state.plots.length, GameConfig.startingPlots);
  });

  test('plant, wait, harvest', () {
    expect(state.tapPlot(0).ok, isTrue);
    expect(state.coins, GameConfig.startingCoins - GameConfig.wheatSeedCost);

    expect(state.tapPlot(0).ok, isFalse); // still growing
    now += GameConfig.wheatGrowTime.inMilliseconds;
    expect(state.tapPlot(0).ok, isTrue);
    expect(state.count(Item.wheat), GameConfig.wheatPerHarvest);
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

  test('mill converts wheat to flour after its time', () {
    expect(state.startProduction(state.mill).ok, isFalse); // not owned
    state.coins = GameConfig.millPrice;
    expect(state.buyBuilding(state.mill).ok, isTrue);
    expect(state.startProduction(state.mill).ok, isFalse); // no wheat

    state.sell(Item.wheat, 0);
    state.loadFromJson({
      ...state.toJson(),
      'items': {'wheat': 2},
    });
    expect(state.startProduction(state.mill).ok, isTrue);
    expect(state.count(Item.wheat), 0);
    now += GameConfig.millTime.inMilliseconds;
    state.tick();
    expect(state.count(Item.flour), GameConfig.millFlourOutput);
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

  test('save and load round-trip keeps timers', () {
    state.tapPlot(0);
    final saved = state.toJson();
    final loaded = GameState(clock: () => now)..loadFromJson(saved);
    expect(loaded.plots[0].plantedAtMs, now);
    expect(loaded.coins, state.coins);
  });
}
