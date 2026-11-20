import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/sprites.dart';
import '../../art/text_styles.dart';
import '../../models/defs.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/pulse.dart';
import '../widgets/surfaces.dart';

/// Panel for a production building: the animated building, its job queue
/// and everything it can make.
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

class _BuildingPanelState extends State<BuildingPanel> with SingleTickerProviderStateMixin {
  final _SceneClock _clock = _SceneClock();
  late final Ticker _ticker;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _last).clamp(0.0, 0.1);
    _last = now;
    final target = widget.building.isWorking(widget.state.nowMs) ? 5.0 : 0.35;
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

  void _collect(BuildContext context) {
    final out = widget.state.collect(widget.building);
    showGameMessage(context, out.result, successSound: Sfx.harvest);
    for (final e in out.items.entries) {
      GameScope.of(context).fx.flyFrom(context, itemIcon(e.key), 'barn', count: min(e.value, 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final b = widget.building;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final unlocked = state.isUnlocked(b.kind);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SceneFrame(
              height: 130,
              child: CustomPaint(size: Size.infinite, painter: _ScenePainter(_clock, b, state)),
            ),
            if (!unlocked)
              PaperCard(
                child: Column(
                  children: [
                    const GameIcon(GameIconType.lock, size: 40),
                    Text(
                      'Unlocks at level ${b.def.unlockLevel}',
                      style: AppText.style(19, weight: 700),
                    ),
                  ],
                ),
              )
            else if (!b.owned)
              PaperCard(
                child: Column(
                  children: [
                    Text("You don't own the ${b.name} yet.", style: AppText.style(18)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Pulse(
                        enabled: state.tutorial == TutorialStep.buildMill,
                        child: ChunkyButton(
                          label: 'Build for ${b.def.price} $coinToken',
                          onPressed: () => showGameMessage(context, state.buyBuilding(b)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _QueueCard(state: state, building: b, onCollect: () => _collect(context)),
            for (final r in b.recipes) _RecipeCard(state: state, building: b, recipe: r),
          ],
        );
      },
    );
  }
}

/// The queue: one box per slot, showing what is being made or waiting.
class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.state, required this.building, required this.onCollect});

  final GameState state;
  final ProductionBuilding building;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final now = state.nowMs;
    final b = building;
    final working = b.working(now);
    final ready = b.readyCount(now);
    return PaperCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < b.slots; i++)
                Expanded(
                  child: _SlotBox(job: i < b.jobs.length ? b.jobs[i] : null, now: now),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            working != null
                ? '${b.def.verb}... ${((working.endMs - now) / 1000).ceil()}s left'
                : (ready > 0 ? 'All done!' : 'Pick something to make below.'),
            style: AppText.style(16, weight: 500, color: Palette.textSoft),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (ready > 0)
                Expanded(
                  child: Pulse(
                    enabled: state.tutorial != TutorialStep.done,
                    child: ChunkyButton(
                      label: 'Collect $ready',
                      height: 44,
                      fontSize: 18,
                      color: Palette.gold,
                      darkColor: Palette.goldDark,
                      onPressed: onCollect,
                    ),
                  ),
                ),
              if (ready > 0 && working != null) const SizedBox(width: 8),
              if (working != null)
                Expanded(
                  child: ChunkyButton(
                    label: 'Speed up ${state.speedUpCost(b)} $gemToken',
                    height: 44,
                    fontSize: 18,
                    color: Palette.purple,
                    darkColor: Palette.purpleDark,
                    onPressed: () =>
                        showGameMessage(context, state.speedUp(b), successSound: Sfx.done),
                  ),
                ),
            ],
          ),
          if (state.queueUpgradePrice(b) != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ChunkyButton(
                label: '+1 slot  ${state.queueUpgradePrice(b)} $coinToken',
                height: 40,
                fontSize: 16,
                color: Palette.blue,
                darkColor: Palette.blueDark,
                onPressed: () => showGameMessage(context, state.upgradeQueue(b)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotBox extends StatelessWidget {
  const _SlotBox({required this.job, required this.now});

  final Job? job;
  final int now;

  @override
  Widget build(BuildContext context) {
    final j = job;
    final ready = j != null && j.isReady(now);
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: ready ? Palette.grassLight : Palette.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline, width: 3),
      ),
      child: j == null
          ? Center(
              child: Text('empty', style: AppText.style(13, color: Palette.textSoft)),
            )
          : Stack(
              children: [
                Center(child: GameIcon(itemIcon(j.recipe.output), size: 36)),
                if (ready)
                  const Positioned(right: 2, top: 2, child: GameIcon(GameIconType.check, size: 18)),
                if (!ready)
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 4,
                    child: SizedBox(
                      height: 7,
                      child: CustomPaint(painter: _BarPainter(j.progress(now))),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.outline);
    canvas.drawRect(
      Rect.fromLTWH(1.5, 1.5, (size.width - 3) * p, size.height - 3),
      Paint()..color = Palette.gold,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.p != p;
}

/// One thing the building can make, with a "Make" button.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.state, required this.building, required this.recipe});

  final GameState state;
  final ProductionBuilding building;
  final RecipeDef recipe;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final locked = r.unlockLevel > state.level;
    final hasAll = r.inputs.entries.every((e) => state.count(e.key) >= e.value);
    final canPress = building.owned && !locked && !building.isFull;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: PaperCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            for (final e in r.inputs.entries) ...[
              RecipeChip(item: e.key, amount: e.value, size: 46, have: state.count(e.key)),
              const SizedBox(width: 2),
            ],
            const GameIcon(GameIconType.arrow, size: 22),
            const SizedBox(width: 2),
            RecipeChip(item: r.output, amount: r.outputAmount, size: 46),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameIcon(GameIconType.clock, size: 16),
                    Text(' ${_time(r.time)}', style: AppText.style(14, weight: 700)),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 86,
                  child: locked
                      ? Center(
                          child: Text('Lv ${r.unlockLevel}', style: AppText.style(17, weight: 700)),
                        )
                      : Pulse(
                          enabled: canPress && hasAll && _tutorialWants(state, r),
                          child: ChunkyButton(
                            label: 'Make',
                            height: 40,
                            fontSize: 17,
                            color: hasAll ? Palette.orange : Palette.disabled,
                            darkColor: hasAll ? Palette.orangeDark : Palette.disabledDark,
                            onPressed: canPress
                                ? () => showGameMessage(
                                    context,
                                    state.startProduction(building, r),
                                    successSound: Sfx.tap,
                                  )
                                : null,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _time(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  final s = d.inSeconds % 60;
  return s == 0 ? '${d.inMinutes}m' : '${d.inMinutes}m ${s}s';
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.clock, this.building, this.state) : super(repaint: clock);

  final _SceneClock clock;
  final ProductionBuilding building;
  final GameState state;

  @override
  void paint(Canvas canvas, Size size) {
    const k = 2.6;
    canvas.save();
    canvas.scale(k);
    final w = size.width / k;
    final h = size.height / k;
    for (var y = 0.0; y < h; y += 16) {
      for (var x = 0.0; x < w; x += 16) {
        final n = ((x * 7 + y * 13) ~/ 16) % 9;
        Art.at(canvas, n == 0 ? S.grassFlowers : (n < 3 ? S.grassTufts : S.grass), x, y);
      }
    }
    final faded = building.owned ? null : _faded;
    final working = building.owned && building.isWorking(state.nowMs);
    final t = clock.t;
    switch (building.kind) {
      case BuildingKind.mill:
        final x = w / 2 - 16;
        final y = h - 48;
        Art.at(canvas, S.windmillTower, x, y, paint: faded);
        canvas.save();
        canvas.translate(x + 16, y + 13);
        canvas.rotate(clock.angle);
        Art.at(canvas, S.windmillBlades, -24, -24, paint: faded);
        canvas.restore();
      case BuildingKind.oven:
        final x = w / 2 - 22;
        final y = h - 44;
        Art.at(canvas, S.oven, x, y, paint: faded);
        if (working) {
          for (var i = 0; i < 4; i++) {
            final fh = 3 + ((sin(t * 14 + i * 1.9) + 1) * 2.5).roundToDouble();
            canvas.drawRect(
              Rect.fromLTWH(x + 17 + i * 3, y + 34 - fh, 2, fh),
              Paint()..color = i.isEven ? Palette.fire : Palette.red,
            );
          }
          _smoke(canvas, x + 34, y, t);
        }
      case BuildingKind.popcorn:
        final x = w / 2 - 15;
        final y = h - 42;
        Art.at(canvas, S.popcornMachine, x, y, paint: faded);
        if (working) {
          for (var i = 0; i < 6; i++) {
            final p = (t * 2.2 + i / 6) % 1.0;
            canvas.drawRect(
              Rect.fromLTWH(x + 7 + (i * 5) % 16, y + 21 - sin(p * pi) * 10, 2, 2),
              Paint()..color = const Color(0xFFFFFFFF),
            );
          }
        }
      case BuildingKind.feedMill:
        final shake = working ? sin(t * 40) * 0.4 : 0.0;
        Art.at(canvas, S.feedMill, w / 2 - 18 + shake, h - 48, paint: faded);
      case BuildingKind.dairy:
        final x = w / 2 - 22;
        final y = h - 44;
        Art.at(canvas, S.dairy, x, y, paint: faded);
        if (working) _smoke(canvas, x + 22, y + 4, t);
    }
    Art.at(canvas, S.sunflower, 4, h - 18);
    Art.at(canvas, S.bush, w - 20, h - 17);
    canvas.restore();
  }

  void _smoke(Canvas canvas, double x, double y, double t) {
    for (var i = 0; i < 3; i++) {
      final p = (t * 0.6 + i / 3) % 1.0;
      final s = 2 + p * 4;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x + p * 8, y - p * 24), width: s, height: s),
        Paint()..color = Palette.smoke.withValues(alpha: 1 - p),
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.building != building;
}

final Paint _faded = Paint()
  ..filterQuality = FilterQuality.none
  ..colorFilter = const ColorFilter.matrix(<double>[
    0.45, 0.35, 0.1, 0, 40, //
    0.25, 0.55, 0.1, 0, 40, //
    0.25, 0.35, 0.3, 0, 40, //
    0, 0, 0, 0.85, 0, //
  ]);

/// An item icon in a little frame with an "xN" badge. When [have] is given,
/// the badge turns red if there is not enough.
class RecipeChip extends StatelessWidget {
  const RecipeChip({
    super.key,
    required this.item,
    required this.amount,
    this.size = 60,
    this.have,
  });

  final Item item;
  final int amount;
  final double size;
  final int? have;

  @override
  Widget build(BuildContext context) {
    final short = have != null && have! < amount;
    return SizedBox(
      width: size + 6,
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
            padding: const EdgeInsets.all(4),
            child: GameIcon(itemIcon(item), size: size - 14),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CountPill(
              have == null ? 'x$amount' : '${have!}/$amount',
              color: short ? Palette.redDark : Palette.woodDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// True when the tutorial is asking the player to make this recipe.
bool _tutorialWants(GameState s, RecipeDef r) =>
    (s.tutorial == TutorialStep.makeFlour && r.id == 'flour') ||
    (s.tutorial == TutorialStep.bakeBread && r.id == 'bread');
