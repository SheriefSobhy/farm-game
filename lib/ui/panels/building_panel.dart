import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/sprites.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../../services/sound_service.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Panel for the Mill or the Oven, with the animated building on top.
class BuildingPanel extends StatefulWidget {
  const BuildingPanel({super.key, required this.state, required this.building});

  final GameState state;
  final ProductionBuilding building;

  @override
  State<BuildingPanel> createState() => _BuildingPanelState();
}

/// Animation time for the scene; repaints only the picture.
class _SceneClock extends ChangeNotifier {
  double t = 0;
  double angle = 0.4;
  double speed = 0;
  void tick() => notifyListeners();
}

class _BuildingPanelState extends State<BuildingPanel>
    with SingleTickerProviderStateMixin {
  final _SceneClock _clock = _SceneClock();
  late final Ticker _ticker;
  double _last = 0;

  bool get _isMill => widget.building.recipe == Recipe.mill;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _last).clamp(0.0, 0.1);
    _last = now;
    final target = widget.building.isWorking ? 5.0 : 0.35;
    _clock.speed += (target - _clock.speed) * min(1.0, dt * 2);
    _clock.angle += _clock.speed * dt;
    _clock.t = now;
    _clock.tick();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final b = widget.building;
    final recipe = b.recipe;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SceneFrame(
            height: 150,
            child: CustomPaint(
              size: Size.infinite,
              painter: _ScenePainter(_clock, b, isMill: _isMill),
            ),
          ),
          PaperCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RecipeChip(item: recipe.input, amount: recipe.inputAmount),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: GameIcon(GameIconType.arrow, size: 34),
                    ),
                    RecipeChip(
                      item: recipe.output,
                      amount: recipe.outputAmount,
                    ),
                    const SizedBox(width: 10),
                    const GameIcon(GameIconType.clock, size: 24),
                    Text(
                      ' ${recipe.duration.inSeconds}s',
                      style: AppText.style(18, weight: 700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (b.owned) ..._owned(context) else ..._notOwned(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _owned(BuildContext context) {
    final state = widget.state;
    final b = widget.building;
    final r = b.recipe;
    final working = b.isWorking;
    final secs = (b.remainingMs(state.nowMs) / 1000).ceil();
    return [
      IconText(
        'You have ${state.count(r.input)} ${r.input.token}',
        style: AppText.style(18, weight: 600),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 22,
        width: double.infinity,
        child: CustomPaint(painter: _ProgressPainter(_clock, b, state)),
      ),
      const SizedBox(height: 4),
      Text(
        working ? '${r.busyLabel}  ${secs}s left' : 'Ready to work!',
        style: AppText.style(16, weight: 500, color: Palette.textSoft),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          label: working
              ? r.busyLabel
              : '${r.actionVerb}  ${r.inputAmount} ${r.input.token}',
          color: Palette.orange,
          darkColor: Palette.orangeDark,
          onPressed: working
              ? null
              : () => showGameMessage(
                  context,
                  state.startProduction(b),
                  successSound: Sfx.tap,
                ),
        ),
      ),
    ];
  }

  List<Widget> _notOwned(BuildContext context) {
    final b = widget.building;
    return [
      Text(
        "You don't own the ${b.recipe.buildingName} yet.",
        style: AppText.style(18),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          label: 'Build for ${b.recipe.price} $coinToken',
          onPressed: () =>
              showGameMessage(context, widget.state.buyBuilding(b)),
        ),
      ),
    ];
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.clock, this.building, {required this.isMill})
    : super(repaint: clock);

  final _SceneClock clock;
  final ProductionBuilding building;
  final bool isMill;

  @override
  void paint(Canvas canvas, Size size) {
    // grass tiles, then the building scaled up in the middle
    const k = 3.0;
    canvas.save();
    canvas.scale(k);
    final w = size.width / k;
    final h = size.height / k;
    for (var y = 0.0; y < h; y += 16) {
      for (var x = 0.0; x < w; x += 16) {
        final n = ((x * 7 + y * 13) ~/ 16) % 9;
        Art.at(
          canvas,
          n == 0 ? S.grassFlowers : (n < 3 ? S.grassTufts : S.grass),
          x,
          y,
        );
      }
    }
    final faded = building.owned ? null : _faded;
    if (isMill) {
      final x = w / 2 - 16;
      final y = h - 48;
      Art.at(canvas, S.windmillTower, x, y, paint: faded);
      canvas.save();
      canvas.translate(x + 16, y + 13);
      canvas.rotate(clock.angle);
      Art.at(canvas, S.windmillBlades, -24, -24, paint: faded);
      canvas.restore();
    } else {
      final x = w / 2 - 22;
      final y = h - 44;
      Art.at(canvas, S.oven, x, y, paint: faded);
      if (building.owned && building.isWorking) {
        final t = clock.t;
        for (var i = 0; i < 4; i++) {
          final fh = 3 + ((sin(t * 14 + i * 1.9) + 1) * 2.5).roundToDouble();
          canvas.drawRect(
            Rect.fromLTWH(x + 17 + i * 3, y + 34 - fh, 2, fh),
            Paint()..color = i.isEven ? Palette.fire : Palette.red,
          );
        }
        for (var i = 0; i < 3; i++) {
          final p = (t * 0.6 + i / 3) % 1.0;
          final s = 2 + p * 4;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x + 34 + p * 8, y - p * 24),
              width: s,
              height: s,
            ),
            Paint()..color = Palette.smoke.withValues(alpha: 1 - p),
          );
        }
      }
    }
    Art.at(canvas, S.sunflower, 4, h - 18);
    Art.at(canvas, S.bush, w - 20, h - 17);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.building != building || old.isMill != isMill;
}

final Paint _faded = Paint()
  ..filterQuality = FilterQuality.none
  ..colorFilter = const ColorFilter.matrix(<double>[
    0.45, 0.35, 0.1, 0, 40, //
    0.25, 0.55, 0.1, 0, 40, //
    0.25, 0.35, 0.3, 0, 40, //
    0, 0, 0, 0.85, 0, //
  ]);

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.clock, this.building, this.state)
    : super(repaint: clock);

  final _SceneClock clock;
  final ProductionBuilding building;
  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Palette.outline);
    final inner = rect.deflate(3);
    canvas.drawRect(inner, Paint()..color = Palette.woodDeep);
    final p = building.progress(state.nowMs);
    if (p <= 0) return;
    final fill = Rect.fromLTWH(
      inner.left,
      inner.top,
      inner.width * p,
      inner.height,
    );
    canvas.drawRect(fill, Paint()..color = Palette.gold);
    canvas.drawRect(
      Rect.fromLTWH(fill.left, fill.top, fill.width, 3),
      Paint()..color = const Color(0x66FFFFFF),
    );
    // moving stripes
    canvas.save();
    canvas.clipRect(fill);
    final stripe = Paint()..color = const Color(0x33FFFFFF);
    final offset = (clock.t * 30) % 16;
    for (var x = fill.left - 16 + offset; x < fill.right; x += 16) {
      canvas.drawRect(Rect.fromLTWH(x, fill.top, 6, fill.height), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.building != building;
}

/// An item icon in a little frame with an "xN" badge.
class RecipeChip extends StatelessWidget {
  const RecipeChip({
    super.key,
    required this.item,
    required this.amount,
    this.size = 60,
  });

  final Item item;
  final int amount;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Palette.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.outline, width: 3),
            ),
            padding: const EdgeInsets.all(6),
            child: GameIcon(itemIcon(item), size: size - 18),
          ),
          Positioned(right: 0, bottom: 0, child: CountPill('x$amount')),
        ],
      ),
    );
  }
}
