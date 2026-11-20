/// All game balance numbers live here.
/// Change a value, then hot-restart the app to try it out.
class GameConfig {
  GameConfig._();

  // --- Start of a new game ---
  static const int startingCoins = 100;
  static const int startingPlots = 1;

  // --- Land ---
  static const int maxPlots = 9;
  static const int gridColumns = 3;

  /// Price of the 2nd plot. Each further plot costs [plotPriceMultiplier] times more.
  static const int firstPlotPrice = 50;
  static const double plotPriceMultiplier = 1.5;

  // --- Wheat ---
  static const int wheatSeedCost = 5;
  static const Duration wheatGrowTime = Duration(seconds: 10);
  static const int wheatPerHarvest = 3;

  // --- Mill (wheat -> flour) ---
  static const int millPrice = 200;
  static const int millWheatInput = 2;
  static const int millFlourOutput = 1;
  static const Duration millTime = Duration(seconds: 5);

  // --- Oven (flour -> bread) ---
  static const int ovenPrice = 400;
  static const int ovenFlourInput = 2;
  static const int ovenBreadOutput = 1;
  static const Duration ovenTime = Duration(seconds: 8);

  // --- Market sell prices (coins per item) ---
  static const int wheatSellPrice = 2;
  static const int flourSellPrice = 8;
  static const int breadSellPrice = 25;

  // --- Technical ---
  /// How often progress is written to the phone's storage.
  static const Duration autoSaveInterval = Duration(seconds: 2);
}
