import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../art/sprites.dart';
import 'farm_layout.dart';

/// Grass, paths, flowers and the tree border around the farm.
///
/// Drawn once into an image at 1 unit = 1 pixel, then scaled up with
/// nearest-neighbour filtering. That keeps tile edges seamless.
class FarmGround extends PositionComponent {
  FarmGround() : super(priority: -100);

  static const double _margin = 160;
  ui.Image? _image;

  @override
  Future<void> onLoad() async {
    const w = FarmLayout.worldWidth + _margin * 2;
    const h = FarmLayout.worldHeight + _margin * 2;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.translate(_margin, _margin);
    _paintGround(c);
    _image = rec.endRecording().toImageSync(w.toInt(), h.toInt());
  }

  @override
  void onRemove() {
    _image?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final img = _image;
    if (img == null) return;
    canvas.drawImage(
      img,
      const Offset(-_margin, -_margin),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  static bool _blocked(Rect r) {
    if (r.overlaps(FarmLayout.plotRect(0).expandToInclude(FarmLayout.plotRect(8)).inflate(4))) {
      return true;
    }
    for (final s in FarmLayout.spots.values) {
      if (r.overlaps(s.deflate(2))) return true;
    }
    return false;
  }

  void _paintGround(Canvas c) {
    final rnd = Random(42);
    const m = _margin;
    // grass everywhere, with tufts and a few flowers sprinkled around
    for (var y = -m; y < FarmLayout.worldHeight + m; y += 16) {
      for (var x = -m; x < FarmLayout.worldWidth + m; x += 16) {
        final roll = rnd.nextDouble();
        final tile = roll < 0.18 ? S.grassTufts : (roll < 0.24 ? S.grassFlowers : S.grass);
        final r = Rect.fromLTWH(x, y, 16, 16);
        Art.draw(c, _blocked(r) && tile == S.grassFlowers ? S.grass : tile, r);
      }
    }

    // a dirt path from the barn door down between the field and buildings
    for (var y = 112.0; y < 284; y += 16) {
      Art.at(c, S.path, 118, y);
    }
    for (var x = 22.0; x < 118; x += 16) {
      Art.at(c, S.path, x, 102);
    }
    Art.at(c, S.path, 118, 102);

    // tree border outside the farm, drawn back to front
    final border = <(Spr, double, double)>[];
    final trees = [S.pine, S.roundTree, S.bigTree, S.pine, S.autumnTree];
    for (var x = -m; x < FarmLayout.worldWidth + m; x += 12) {
      for (final y in [-30.0, -18.0, FarmLayout.worldHeight + 2, FarmLayout.worldHeight + 14]) {
        border.add((
          trees[rnd.nextInt(trees.length)],
          x + rnd.nextDouble() * 5,
          y + rnd.nextDouble() * 5,
        ));
      }
    }
    for (var y = -30.0; y < FarmLayout.worldHeight + 10; y += 12) {
      for (final x in [-34.0, -20.0, FarmLayout.worldWidth + 4, FarmLayout.worldWidth + 18]) {
        border.add((
          trees[rnd.nextInt(trees.length)],
          x + rnd.nextDouble() * 5,
          y + rnd.nextDouble() * 5,
        ));
      }
    }
    border.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (s, x, y) in border) {
      Art.at(c, s, x, y);
    }

    // decorations that never sit on top of a building or the field
    final props = [
      (S.roundTree, 60.0, 2.0),
      (S.pine, 78.0, -2.0),
      (S.bigTree, 102.0, 4.0),
      (S.autumnTree, 120.0, -4.0),
      (S.pine, 160.0, 0.0),
      (S.roundTree, 176.0, 22.0),
      (S.beehive, 66.0, 22.0),
      (S.sunflower, 108.0, 64.0),
      (S.sunflower, 112.0, 80.0),
      (S.berryBush, 106.0, 34.0),
      (S.hayBale, 124.0, 38.0),
      (S.barrel, 66.0, 84.0),
      (S.bush, 2.0, 222.0),
      (S.rock, 100.0, 224.0),
      (S.mushrooms, 176.0, 160.0),
      (S.sunflower, 180.0, 222.0),
    ];
    for (final (s, x, y) in props) {
      Art.at(c, s, x, y);
    }

    // two fenced pens along the bottom: chickens (left) and cows (right)
    final chickens = FarmLayout.spots[FarmSpot.chickens]!;
    final cows = FarmLayout.spots[FarmSpot.cows]!;
    fence(c, chickens.left, chickens.top, (chickens.width / 16).round(), 4);
    fence(c, cows.left, cows.top, (cows.width / 16).round(), 4);

    // a little garden between the buildings and the pens
    final strip = [
      (S.sunflower, 0.0, 250.0),
      (S.berryBush, 48.0, 258.0),
      (S.bush, 104.0, 262.0),
      (S.mushrooms, 106.0, 236.0),
      (S.sprout, 50.0, 238.0),
      (S.sunflower, 186.0, 266.0),
    ];
    for (final (s, x, y) in strip) {
      Art.at(c, s, x, y);
    }
  }

  /// Draws a wooden fence rectangle of [cols] x [rows] tiles.
  static void fence(Canvas c, double x, double y, int cols, int rows) {
    for (var i = 0; i < cols; i++) {
      final top = i == 0 ? S.fenceTL : (i == cols - 1 ? S.fenceTR : S.fenceH);
      final bottom = i == 0 ? S.fenceBL : (i == cols - 1 ? S.fenceBR : S.fenceH);
      Art.at(c, top, x + i * 16, y);
      Art.at(c, bottom, x + i * 16, y + (rows - 1) * 16);
    }
    for (var j = 1; j < rows - 1; j++) {
      Art.at(c, S.fenceV, x, y + j * 16);
      Art.at(c, S.fenceVR, x + (cols - 1) * 16, y + j * 16);
    }
  }
}
