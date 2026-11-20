import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../art/farm_art.dart';
import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../../services/sound_service.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Screen for the Mill or the Oven, with an animated illustration.
class BuildingPanel extends StatefulWidget {
  const BuildingPanel({
    super.key,
    required this.state,
    required this.building,
    required this.onGoToShop,
  });

  final GameState state;
  final ProductionBuilding building;
  final VoidCallback onGoToShop;

  @override
  State<BuildingPanel> createState() => _BuildingPanelState();
}

/// Animation time for the scene; repaints only the illustration.
class _SceneClock extends ChangeNotifier {
  double t = 0;
  double angle = 0.3;
  double speed = 0;

  void tick() => notifyListeners();
}

class _BuildingPanelState extends State<BuildingPanel> with SingleTickerProviderStateMixin {
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
    final target = widget.building.isWorking ? 4.5 : 0.0;
    _clock.speed += (target - _clock.speed) * min(1.0, dt * 2.5);
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
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SceneFrame(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: b.owned ? _identity : _faded,
                  child: CustomPaint(
                    painter: _BuildingScenePainter(_clock, b, isMill: _isMill),
                  ),
                ),
                Positioned(left: 12, top: 12, child: _NamePlaque(recipe.buildingName)),
                if (!b.owned)
                  const Positioned(right: 14, bottom: 14, child: _ForSaleSign()),
              ],
            ),
          ),
          PaperCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RecipeChip(item: recipe.input, amount: recipe.inputAmount),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: GameIcon(GameIconType.arrow, size: 40),
                    ),
                    _RecipeChip(item: recipe.output, amount: recipe.outputAmount),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${recipe.inputAmount} ${recipe.input.label.toLowerCase()} becomes '
                  '${recipe.outputAmount} ${recipe.output.label.toLowerCase()} '
                  'in ${recipe.duration.inSeconds} seconds',
                  textAlign: TextAlign.center,
                  style: AppText.style(15, weight: 500, color: Palette.textSoft),
                ),
                const SizedBox(height: 16),
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
      IconText('You have ${state.count(r.input)} ${r.input.token}',
          style: AppText.style(18, weight: 600)),
      const SizedBox(height: 12),
      SizedBox(
        height: 28,
        width: double.infinity,
        child: CustomPaint(painter: _ProgressPainter(_clock, b, state)),
      ),
      const SizedBox(height: 6),
      Text(
        working ? '${r.busyLabel}  ${secs}s left' : 'Ready to work!',
        style: AppText.style(16, weight: 500, color: Palette.textSoft),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          label: working ? r.busyLabel : '${r.actionVerb}  ${r.inputAmount} ${r.input.token}',
          color: Palette.orange,
          darkColor: Palette.orangeDark,
          onPressed: working
              ? null
              : () => showGameMessage(context, state.startProduction(b), successSound: Sfx.tap),
        ),
      ),
    ];
  }

  List<Widget> _notOwned(BuildContext context) {
    final b = widget.building;
    return [
      Text("You don't own the ${b.recipe.buildingName} yet.", style: AppText.style(18)),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ChunkyButton(
          label: 'Buy for ${b.recipe.price} $coinToken',
          onPressed: () => showGameMessage(context, widget.state.buyBuilding(b)),
        ),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: widget.onGoToShop,
        child: Text('Open Shop', style: AppText.style(16, color: Palette.woodDark)),
      ),
    ];
  }
}

const ColorFilter _identity = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Washed-out colors for buildings you don't own yet.
const ColorFilter _faded = ColorFilter.matrix(<double>[
  0.55, 0.35, 0.1, 0, 20, //
  0.25, 0.65, 0.1, 0, 20, //
  0.25, 0.35, 0.4, 0, 20, //
  0, 0, 0, 1, 0, //
]);

class _BuildingScenePainter extends CustomPainter {
  _BuildingScenePainter(this.clock, this.building, {required this.isMill})
      : super(repaint: clock);

  final _SceneClock clock;
  final ProductionBuilding building;
  final bool isMill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;
    drawSky(canvas, Rect.fromLTWH(0, 0, w, h * 0.7), t: clock.t);
    drawHills(canvas, full, h * 0.6);
    drawTree(canvas, Offset(w * 0.86, h * 0.9), h * 0.55);
    drawBush(canvas, Offset(w * 0.13, h * 0.96), h * 0.26);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.9), width: h * 0.7, height: h * 0.1),
      Paint()..color = const Color(0x33000000),
    );
    final obj = Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: h * 0.92, height: h * 0.92);
    if (isMill) {
      drawWindmill(canvas, obj, angle: clock.angle);
    } else {
      drawOven(canvas, obj.shift(Offset(0, h * 0.04)), t: clock.t, working: building.isWorking);
    }
    for (final (x, c) in const [(0.3, Color(0xFFFFFFFF)), (0.66, Color(0xFFFFB3C7)), (0.22, Color(0xFFFFE27A))]) {
      drawFlower(canvas, Offset(w * x, h * 0.93), 4, c);
    }
  }

  @override
  bool shouldRepaint(_BuildingScenePainter old) => old.building != building || old.isMill != isMill;
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.clock, this.building, this.state) : super(repaint: clock);

  final _SceneClock clock;
  final ProductionBuilding building;
  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), Paint()..color = Palette.woodDeep);
    final inner = rect.deflate(3);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, radius), Paint()..color = const Color(0xFF7A5232));
    final p = building.progress(state.nowMs);
    if (p <= 0) return;
    final fill = Rect.fromLTWH(inner.left, inner.top, max(inner.height, inner.width * p), inner.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, radius),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.goldLight, Palette.orange],
        ).createShader(fill),
    );
    // moving shine stripes
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(fill, radius));
    final stripe = Paint()..color = const Color(0x33FFFFFF);
    final offset = (clock.t * 30) % 24;
    for (var x = fill.left - 24 + offset; x < fill.right; x += 24) {
      canvas.drawPath(
        Path()
          ..moveTo(x, fill.bottom)
          ..lineTo(x + 10, fill.top)
          ..lineTo(x + 20, fill.top)
          ..lineTo(x + 10, fill.bottom)
          ..close(),
        stripe,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProgressPainter old) => old.building != building;
}

class _RecipeChip extends StatelessWidget {
  const _RecipeChip({required this.item, required this.amount});

  final Item item;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Palette.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Palette.paperDark, width: 2.5),
            ),
            padding: const EdgeInsets.all(8),
            child: GameIcon(itemIcon(item), size: 54),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: Palette.woodDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.woodDeep, width: 2),
              ),
              child: Text('x$amount', style: AppText.light(16, weight: 700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NamePlaque extends StatelessWidget {
  const _NamePlaque(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return WoodPanel(
      radius: 14,
      planks: 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(name, style: AppText.light(22, weight: 700)),
    );
  }
}

class _ForSaleSign extends StatelessWidget {
  const _ForSaleSign();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Palette.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.red, width: 3),
        ),
        child: Text('For sale!', style: AppText.style(18, weight: 700, color: Palette.redDark)),
      ),
    );
  }
}
