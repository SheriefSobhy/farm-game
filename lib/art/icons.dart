import 'package:flutter/widgets.dart';

import 'sprites.dart';

/// Every icon used by the UI. All of them are pixel-art sprites.
enum GameIconType {
  coin,
  gem,
  star,
  wheat,
  corn,
  flour,
  bread,
  popcorn,
  chickenFeed,
  egg,
  cake,
  cowFeed,
  milk,
  cheese,
  lock,
  barn,
  windmill,
  oven,
  stall,
  popcornMachine,
  feedMill,
  dairy,
  coop,
  cowShed,
  chicken,
  cow,
  bag,
  plot,
  soundOn,
  soundOff,
  check,
  plus,
  cross,
  warning,
  arrow,
  clock,
  bolt,
  gift,
  trophy,
  scroll,
  wheatSeeds,
  cornSeeds,
}

Spr? _single(GameIconType t) => switch (t) {
  GameIconType.coin => S.coin,
  GameIconType.gem => S.gem,
  GameIconType.star => S.star,
  GameIconType.wheat => S.wheat,
  GameIconType.corn => S.corn,
  GameIconType.flour => S.flour,
  GameIconType.bread => S.bread,
  GameIconType.popcorn => S.popcorn,
  GameIconType.chickenFeed => S.chickenFeed,
  GameIconType.egg => S.egg,
  GameIconType.cake => S.cake,
  GameIconType.cowFeed => S.cowFeed,
  GameIconType.milk => S.milk,
  GameIconType.cheese => S.cheese,
  GameIconType.lock => S.lock,
  GameIconType.barn => S.barnIcon,
  GameIconType.oven => S.oven,
  GameIconType.stall => S.stall,
  GameIconType.popcornMachine => S.popcornMachine,
  GameIconType.feedMill => S.feedMill,
  GameIconType.dairy => S.dairy,
  GameIconType.coop => S.coop,
  GameIconType.cowShed => S.cowShed,
  GameIconType.chicken => S.chicken,
  GameIconType.cow => S.cow,
  GameIconType.bag => S.bag,
  GameIconType.plot => S.wheatStages[2],
  GameIconType.soundOn => S.soundOn,
  GameIconType.soundOff => S.soundOff,
  GameIconType.check => S.check,
  GameIconType.plus => S.plus,
  GameIconType.cross => S.cross,
  GameIconType.warning => S.cross,
  GameIconType.arrow => S.arrowDown,
  GameIconType.clock => S.clock,
  GameIconType.bolt => S.bolt,
  GameIconType.gift => S.gift,
  GameIconType.trophy => S.trophy,
  GameIconType.scroll => S.scroll,
  GameIconType.wheatSeeds => S.wheatSeeds,
  GameIconType.cornSeeds => S.cornSeeds,
  GameIconType.windmill => null,
};

/// Paints icon [type] centered inside [rect]. Used by Flutter and Flame.
void paintGameIcon(
  Canvas canvas,
  Rect rect,
  GameIconType type, {
  double opacity = 1,
}) {
  if (type == GameIconType.windmill) {
    // tower with its sails, as one picture (48 x 58 units)
    final k = (rect.width / 48) < (rect.height / 58)
        ? rect.width / 48
        : rect.height / 58;
    canvas.save();
    canvas.translate(rect.center.dx - 24 * k, rect.center.dy - 29 * k);
    canvas.scale(k);
    Art.at(canvas, S.windmillTower, 8, 12, opacity: opacity);
    Art.at(canvas, S.windmillBlades, 0, 0, opacity: opacity);
    canvas.restore();
    return;
  }
  if (type == GameIconType.arrow) {
    // the arrow sprite points down; icons want it pointing right
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-1.5707963);
    Art.fit(
      canvas,
      S.arrowDown,
      Rect.fromCenter(
        center: Offset.zero,
        width: rect.width,
        height: rect.height,
      ),
      opacity: opacity,
    );
    canvas.restore();
    return;
  }
  Art.fit(canvas, _single(type)!, rect, opacity: opacity);
}

/// A pixel-art icon widget.
class GameIcon extends StatelessWidget {
  const GameIcon(this.type, {super.key, this.size = 32, this.opacity = 1});

  final GameIconType type;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(type, opacity)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.type, this.opacity);
  final GameIconType type;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) =>
      paintGameIcon(canvas, Offset.zero & size, type, opacity: opacity);

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.type != type || old.opacity != opacity;
}
