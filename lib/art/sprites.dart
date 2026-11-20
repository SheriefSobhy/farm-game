import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'extra_atlas.dart';

/// The three sprite sheets used by the game.
///  * farm  - Kenney "Tiny Farm" (CC0)
///  * town  - Kenney "Tiny Town" (CC0)
///  * extra - our own CC0 sprites in the same style (tool/make_sprites.dart)
enum Sheet { farm, town, extra }

/// One sprite: a rectangle inside a sheet (in sheet pixels).
class Spr {
  const Spr(this.sheet, this.src);

  /// A 16x16 tile by its index in a Kenney "Tiny" sheet (12 tiles per row).
  Spr.tile(this.sheet, int index)
    : src = ui.Rect.fromLTWH((index % 12) * 16.0, (index ~/ 12) * 16.0, 16, 16);

  final Sheet sheet;
  final ui.Rect src;

  double get width => src.width;
  double get height => src.height;
}

Spr _f(int i) => Spr.tile(Sheet.farm, i);
Spr _t(int i) => Spr.tile(Sheet.town, i);

/// Named sprites used around the game.
abstract final class S {
  // --- products
  static final wheat = _f(68);
  static final corn = _f(32);
  static final flour = _f(74);
  static final egg = _f(125);
  static final milk = _f(123);
  static final chickenFeed = _f(34);
  static const bread = Spr(Sheet.extra, ExtraAtlas.bread);
  static const popcorn = Spr(Sheet.extra, ExtraAtlas.popcorn);
  static const cake = Spr(Sheet.extra, ExtraAtlas.cake);
  static const cheese = Spr(Sheet.extra, ExtraAtlas.cheese);
  static const cowFeed = Spr(Sheet.extra, ExtraAtlas.cowFeed);

  // --- crops: [sprout, young, ripe]
  static final wheatStages = [_f(64), _f(65), _f(66)];
  static final cornStages = [_f(28), _f(29), _f(30)];
  static final wheatSeeds = _f(69);
  static final cornSeeds = _f(33);
  static final wheatCrate = _f(71);
  static final cornCrate = _f(35);

  // --- soil beds (wet = planted, dry = empty)
  static final bedLeftWet = _f(48);
  static final bedRightWet = _f(50);
  static final bedLeftDry = _f(60);
  static final bedRightDry = _f(62);

  // --- animals and animal things
  static final chicken = _f(122);
  static final cow = _f(121);
  static final sheep = _f(120);
  static final feedTroughL = _f(112);
  static final feedTroughR = _f(113);
  static final waterTroughL = _f(110);
  static final waterTroughR = _f(111);
  static final hayBale = _f(96);

  // --- nature and props
  static final grass = _t(0);
  static final grassTufts = _t(1);
  static final grassFlowers = _t(2);
  static final pine = _f(15);
  static final smallPine = _f(27);
  static final roundTree = _t(16);
  static final bigTree = _t(5);
  static final autumnTree = _t(3);
  static final sprout = _t(17);
  static final mushrooms = _t(29);
  static final bush = _f(39);
  static final berryBush = _f(78);
  static final sunflower = _f(83);
  static final rock = _f(77);
  static final bigRock = _f(89);
  static final barrel = _f(85);
  static final sack = _f(74);
  static final crate = _f(75);
  static final sign = _t(83);
  static final coin = _t(93);
  static final beehive = _t(94);
  static final bag = _t(107);
  static final bucketWater = _f(73);
  static final farmer = _f(109);

  // --- fence (Tiny Town)
  static final fenceTL = _t(44);
  static final fenceTR = _t(46);
  static final fenceBL = _t(68);
  static final fenceBR = _t(70);
  static final fenceH = _t(81);
  static final fenceV = _t(56);
  static final fenceVR = _t(58);
  static final fenceGate = _t(69);
  static final fenceLeftEnd = _t(80);
  static final fenceRightEnd = _t(82);

  // --- dirt path (Tiny Town)
  static final path = _t(25);

  // --- our own sprites
  static const windmillTower = Spr(Sheet.extra, ExtraAtlas.windmillTower);
  static const windmillBlades = Spr(Sheet.extra, ExtraAtlas.windmillBlades);
  static const oven = Spr(Sheet.extra, ExtraAtlas.oven);
  static const stall = Spr(Sheet.extra, ExtraAtlas.stall);
  static const popcornMachine = Spr(Sheet.extra, ExtraAtlas.popcornMachine);
  static const feedMill = Spr(Sheet.extra, ExtraAtlas.feedMill);
  static const dairy = Spr(Sheet.extra, ExtraAtlas.dairy);
  static const ordersBoard = Spr(Sheet.extra, ExtraAtlas.ordersBoard);
  static const coop = Spr(Sheet.extra, ExtraAtlas.coop);
  static const cowShed = Spr(Sheet.extra, ExtraAtlas.cowShed);
  static const note = Spr(Sheet.extra, ExtraAtlas.note);
  static const gem = Spr(Sheet.extra, ExtraAtlas.gem);
  static const star = Spr(Sheet.extra, ExtraAtlas.star);
  static const lock = Spr(Sheet.extra, ExtraAtlas.lock);
  static const check = Spr(Sheet.extra, ExtraAtlas.check);
  static const plus = Spr(Sheet.extra, ExtraAtlas.plus);
  static const cross = Spr(Sheet.extra, ExtraAtlas.cross);
  static const arrowDown = Spr(Sheet.extra, ExtraAtlas.arrowDown);
  static const soundOn = Spr(Sheet.extra, ExtraAtlas.soundOn);
  static const soundOff = Spr(Sheet.extra, ExtraAtlas.soundOff);
  static const scroll = Spr(Sheet.extra, ExtraAtlas.scroll);
  static const gift = Spr(Sheet.extra, ExtraAtlas.gift);
  static const trophy = Spr(Sheet.extra, ExtraAtlas.trophy);
  static const bolt = Spr(Sheet.extra, ExtraAtlas.bolt);
  static const barnIcon = Spr(Sheet.extra, ExtraAtlas.barnIcon);
  static const clock = Spr(Sheet.extra, ExtraAtlas.clock);

  /// The red barn, built from Tiny Farm tiles: [tile index, column, row].
  /// Walls are listed first because the roof's lower edge overlaps them.
  static final List<List<int>> barnTiles = [
    [90, 0, 4], [91, 1, 4], [92, 2, 4], //
    [102, 0, 5], [103, 1, 5], [104, 2, 5], //
    [126, 0, 6], [127, 1, 6], [128, 2, 6], //
    [82, 1, 0], //
    [93, 0, 1], [94, 1, 1], [95, 2, 1], //
    [105, 0, 2], [106, 1, 2], [107, 2, 2], //
    [117, 0, 3], [118, 1, 3], [119, 2, 3], //
    [129, 0, 4], [130, 1, 4], [131, 2, 4],
  ];
}

/// Loads the sheets once at startup and draws sprites pixel-sharp.
abstract final class Art {
  static final Map<Sheet, ui.Image> _images = {};

  static bool get isLoaded => _images.length == Sheet.values.length;

  static const Map<Sheet, String> _files = {
    Sheet.farm: 'assets/images/kenney_tiny_farm.png',
    Sheet.town: 'assets/images/kenney_tiny_town.png',
    Sheet.extra: 'assets/images/extra.png',
  };

  static Future<void> load() async {
    for (final e in _files.entries) {
      if (_images.containsKey(e.key)) continue;
      final data = await rootBundle.load(e.value);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      _images[e.key] = (await codec.getNextFrame()).image;
    }
  }

  static final ui.Paint _paint = ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false;

  /// Draws [s] into [dst]. Nearest-neighbour scaling keeps pixels crisp.
  static void draw(
    ui.Canvas canvas,
    Spr s,
    ui.Rect dst, {
    double opacity = 1,
    ui.Paint? paint,
  }) {
    final img = _images[s.sheet];
    if (img == null) return;
    var p = paint ?? _paint;
    if (opacity < 1) {
      p = ui.Paint()
        ..filterQuality = ui.FilterQuality.none
        ..color = ui.Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0))
        ..colorFilter = paint?.colorFilter;
    }
    canvas.drawImageRect(img, s.src, dst, p);
  }

  /// Draws [s] at its natural size (1 sheet pixel = 1 unit) with its
  /// top-left corner at [x], [y].
  static void at(
    ui.Canvas canvas,
    Spr s,
    double x,
    double y, {
    double opacity = 1,
    ui.Paint? paint,
  }) => draw(
    canvas,
    s,
    ui.Rect.fromLTWH(x, y, s.width, s.height),
    opacity: opacity,
    paint: paint,
  );

  /// Draws [s] so it fits inside [box] (keeping its shape), centered.
  static void fit(ui.Canvas canvas, Spr s, ui.Rect box, {double opacity = 1}) {
    final k = (box.width / s.width) < (box.height / s.height)
        ? box.width / s.width
        : box.height / s.height;
    final w = s.width * k;
    final h = s.height * k;
    draw(
      canvas,
      s,
      ui.Rect.fromLTWH(box.center.dx - w / 2, box.center.dy - h / 2, w, h),
      opacity: opacity,
    );
  }

  /// Draws the composed barn (48x112 units) with its top-left at [x], [y].
  static void barn(ui.Canvas canvas, double x, double y, {ui.Paint? paint}) {
    for (final t in S.barnTiles) {
      at(
        canvas,
        Spr.tile(Sheet.farm, t[0]),
        x + t[1] * 16,
        y + t[2] * 16,
        paint: paint,
      );
    }
  }
}
