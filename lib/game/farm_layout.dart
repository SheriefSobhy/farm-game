import 'dart:ui';

import '../models/defs.dart';

/// Places on the farm that can be tapped.
enum FarmSpot {
  barn,
  orders,
  market,
  mill,
  oven,
  popcorn,
  feedMill,
  dairy,
  chickens,
  cows;

  /// The production building at this spot, if any.
  BuildingKind? get building => switch (this) {
    FarmSpot.mill => BuildingKind.mill,
    FarmSpot.oven => BuildingKind.oven,
    FarmSpot.popcorn => BuildingKind.popcorn,
    FarmSpot.feedMill => BuildingKind.feedMill,
    FarmSpot.dairy => BuildingKind.dairy,
    _ => null,
  };

  /// The animal pen at this spot, if any.
  AnimalKind? get animal => switch (this) {
    FarmSpot.chickens => AnimalKind.chicken,
    FarmSpot.cows => AnimalKind.cow,
    _ => null,
  };

  static FarmSpot forBuilding(BuildingKind k) => values.firstWhere((s) => s.building == k);
  static FarmSpot forAnimal(AnimalKind k) => values.firstWhere((s) => s.animal == k);
}

/// Where everything sits on the farm, in "world units" (1 unit = 1 pixel of
/// the 16px pixel art). The camera scales the whole world to fit the screen.
abstract final class FarmLayout {
  static const double worldWidth = 192;
  static const double worldHeight = 352;

  static const double plotSize = 32;
  static const double plotGap = 4;
  static const Offset fieldOrigin = Offset(8, 118);

  /// Top-left corner of plot [i] (3 columns).
  static Offset plotTopLeft(int i) => Offset(
    fieldOrigin.dx + (i % 3) * (plotSize + plotGap),
    fieldOrigin.dy + (i ~/ 3) * (plotSize + plotGap),
  );

  static Rect plotRect(int i) => plotTopLeft(i) & const Size(plotSize, plotSize);

  /// Area of each building on the farm (top-left + size of its picture).
  static const Map<FarmSpot, Rect> spots = {
    FarmSpot.barn: Rect.fromLTWH(6, -6, 48, 112),
    FarmSpot.orders: Rect.fromLTWH(62, 42, 46, 40),
    FarmSpot.market: Rect.fromLTWH(136, 58, 48, 42),
    FarmSpot.mill: Rect.fromLTWH(140, 112, 32, 46),
    FarmSpot.oven: Rect.fromLTWH(134, 176, 44, 42),
    FarmSpot.popcorn: Rect.fromLTWH(16, 236, 30, 40),
    FarmSpot.feedMill: Rect.fromLTWH(66, 230, 36, 46),
    FarmSpot.dairy: Rect.fromLTWH(140, 234, 44, 42),
    FarmSpot.chickens: Rect.fromLTWH(4, 288, 96, 64),
    FarmSpot.cows: Rect.fromLTWH(108, 288, 80, 64),
  };

  /// Blade hub of the windmill, relative to the tower's top-left.
  static const Offset millHub = Offset(16, 13);

  /// Fire opening and chimney top of the oven, relative to its top-left.
  static const Rect ovenMouth = Rect.fromLTWH(15, 23, 14, 13);
  static const Offset ovenChimney = Offset(34, 1);
}
