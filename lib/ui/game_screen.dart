import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../game/farm_game.dart';
import '../game/farm_layout.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/defs.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import '../models/production_building.dart';
import '../services/save_service.dart';
import '../services/sound_service.dart';
import 'bottom_buttons.dart';
import 'game_scope.dart';
import 'hint.dart';
import 'level_up.dart';
import 'panels/barn_panel.dart';
import 'panels/building_panel.dart';
import 'panels/daily_panel.dart';
import 'panels/market_panel.dart';
import 'panels/orders_panel.dart';
import 'panels/pen_panel.dart';
import 'panels/sheet.dart';
import 'panels/shop_panel.dart';
import 'top_bar.dart';
import 'widgets/icon_text.dart';
import 'widgets/surfaces.dart';

/// The main screen: top bar, the farm, and the bottom buttons.
/// Tapping a building on the farm slides its panel up from the bottom.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.state,
    required this.saveService,
    required this.sound,
  });

  final GameState state;
  final SaveService saveService;
  final SoundService sound;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final FarmGame _game = FarmGame(
    state: widget.state,
    sound: widget.sound,
    onMessage: (r) => GameScope.of(context).toasts.show(r),
    onFly: _flyFromFarm,
    onOpenSpot: _openSpot,
  );
  final GlobalKey _gameKey = GlobalKey();

  Timer? _tickTimer;
  Timer? _saveTimer;

  GameState get _s => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _s.onProductionDone = _onProductionDone;
    _s.onLevelUp = _onLevelUp;
    _s.addListener(_watchTutorial);
    _tutorialSeen = _s.tutorial;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _s.tick());
    _saveTimer = Timer.periodic(GameConfig.autoSaveInterval, (_) => _save());
  }

  late TutorialStep _tutorialSeen;

  /// Plays a happy sound on each tutorial step, and gives a tip at the end.
  void _watchTutorial() {
    final now = _s.tutorial;
    if (now == _tutorialSeen) return;
    _tutorialSeen = now;
    if (!mounted) return;
    if (now == TutorialStep.done) {
      GameScope.of(context).toasts.show(
        const ActionResult.ok(
          'Great farming! Tip: drag your finger across the field to plant or harvest many plots at once.',
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _s.removeListener(_watchTutorial);
    _s.onProductionDone = null;
    _s.onLevelUp = null;
    _tickTimer?.cancel();
    _saveTimer?.cancel();
    _save(force: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Save right away when the player leaves the app.
    if (lifecycle != AppLifecycleState.resumed) {
      _save(force: true);
    } else {
      _s.tick();
    }
  }

  void _save({bool force = false}) {
    final dirty = _s.consumeDirty();
    if (dirty || force) widget.saveService.save(_s.toJson());
  }

  void _onProductionDone(ProductionBuilding b, RecipeDef r) {
    if (!mounted) return;
    widget.sound.play(Sfx.done);
    GameScope.of(context).toasts.show(
      ActionResult.ok(
        '${r.output.label} is ready ${r.output.token}  Tap the ${b.name} to collect!',
      ),
    );
  }

  final List<(int, List<Unlock>)> _levelUps = [];
  bool _showingLevelUp = false;

  /// Level-ups are shown one after another as a full-screen celebration.
  void _onLevelUp(int level, List<Unlock> unlocks) {
    _levelUps.add((level, unlocks));
    _showNextLevelUp();
  }

  Future<void> _showNextLevelUp() async {
    if (_showingLevelUp || _levelUps.isEmpty || !mounted) return;
    _showingLevelUp = true;
    final (level, unlocks) = _levelUps.removeAt(0);
    // let the current tap's effects play first
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) await showLevelUp(context, level, unlocks);
    _showingLevelUp = false;
    _showNextLevelUp();
  }

  void _openHint(Hint h) {
    widget.sound.play(Sfx.tap);
    final spot = h.spot;
    if (spot != null) {
      _openSpot(spot);
      return;
    }
    switch (h.opens) {
      case 'daily':
        _openDaily();
      case 'shop':
        _openShop();
      case 'orders':
        _openOrders();
    }
  }

  /// Flies icons from a spot on the farm to a UI target (barn, coins...).
  void _flyFromFarm(Offset fromInGame, GameIconType icon, String target, int count) {
    final box = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    GameScope.of(context).fx.fly(icon, box.localToGlobal(fromInGame), target, count: count);
  }

  void _openSpot(FarmSpot spot) {
    final kind = spot.building;
    if (kind != null) {
      final b = _s.buildings[kind]!;
      openSheet(
        context,
        title: b.name,
        icon: buildingIcon(kind),
        builder: (_) => BuildingPanel(state: _s, building: b),
      );
      return;
    }
    final animal = spot.animal;
    if (animal != null) {
      final d = _s.pens[animal]!.def;
      openSheet(
        context,
        title: d.penName,
        icon: animal == AnimalKind.chicken ? GameIconType.chicken : GameIconType.cow,
        builder: (_) => PenPanel(state: _s, kind: animal),
      );
      return;
    }
    switch (spot) {
      case FarmSpot.barn:
        _openBarn();
      case FarmSpot.market:
        _openMarket();
      case FarmSpot.orders:
        _openOrders();
      default:
        break;
    }
  }

  void _openBarn() => openSheet(
    context,
    title: 'Barn',
    icon: GameIconType.barn,
    builder: (_) => BarnPanel(state: _s),
  );

  void _openMarket() => openSheet(
    context,
    title: 'Market',
    icon: GameIconType.stall,
    builder: (_) => MarketPanel(state: _s),
  );

  void _openShop() => openSheet(
    context,
    title: 'Shop',
    icon: GameIconType.bag,
    builder: (_) => ShopPanel(state: _s),
  );

  void _openOrders() => openSheet(
    context,
    title: 'Orders',
    icon: GameIconType.scroll,
    builder: (_) => OrdersPanel(state: _s),
  );

  void _openDaily() => openSheet(
    context,
    title: 'Daily',
    icon: GameIconType.gift,
    builder: (_) => DailyPanel(state: _s),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.grass,
      body: Column(
        children: [
          DecoratedBox(
            // a bright sky strip above the farm
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5DB8F2), Color(0xFFA6DDF8)],
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF4E9A3A), width: 2)),
            ),
            child: SafeArea(bottom: false, child: TopBar(state: _s)),
          ),
          Expanded(
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: KeyedSubtree(
                      key: _gameKey,
                      child: GameWidget(game: _game),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    top: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        HintBanner(state: _s, onTap: _openHint),
                        const SizedBox(height: 6),
                        SeedPicker(state: _s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _s,
        builder: (context, _) => BottomButtons(
          buttons: [
            BarButton(GameIconType.scroll, 'Orders', _openOrders, badge: _s.fillableOrders),
            BarButton(GameIconType.barn, 'Barn', _openBarn, targetName: 'barn'),
            BarButton(GameIconType.stall, 'Market', _openMarket),
            BarButton(GameIconType.bag, 'Shop', _openShop),
            BarButton(
              GameIconType.gift,
              'Daily',
              _openDaily,
              badge: (_s.canClaimDaily ? 1 : 0) + _s.claimableGoals,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chooses which seed to plant. Only shown once there is more than one crop.
class SeedPicker extends StatelessWidget {
  const SeedPicker({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final crops = state.unlockedCrops;
        if (crops.length < 2) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Palette.wood,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Palette.outline, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in crops)
                GestureDetector(
                  onTap: () {
                    GameScope.of(context).sound.play(Sfx.tap);
                    state.selectCrop(c.item);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
                    decoration: BoxDecoration(
                      color: state.selectedCrop == c.item ? Palette.goldLight : Palette.cream,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: state.selectedCrop == c.item ? Palette.outline : Palette.woodDark,
                        width: state.selectedCrop == c.item ? 3 : 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameIcon(itemIcon(c.item), size: 26),
                        IconText('${c.seedCost}$coinToken', style: AppText.style(14, weight: 700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A small note at the top of the farm saying what to do next.
/// During the tutorial it shows the tutorial step instead.
class HintBanner extends StatelessWidget {
  const HintBanner({super.key, required this.state, required this.onTap});

  final GameState state;
  final ValueChanged<Hint> onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final inTutorial = state.tutorial != TutorialStep.done;
        final hint = inTutorial ? tutorialHint(state) : nextGoalHint(state);
        return GestureDetector(
          onTap: () => onTap(hint),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(hint.text),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
              decoration: BoxDecoration(
                color: inTutorial ? Palette.goldLight : Palette.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.outline, width: 3),
                boxShadow: hardShadow,
              ),
              child: Row(
                children: [
                  GameIcon(hint.icon, size: 30),
                  const SizedBox(width: 6),
                  Expanded(
                    child: IconText(
                      hint.text,
                      textAlign: TextAlign.start,
                      style: AppText.style(inTutorial ? 16 : 15, weight: 650),
                    ),
                  ),
                  if (inTutorial)
                    GestureDetector(
                      onTap: state.skipTutorial,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'Skip',
                          style: AppText.style(13, weight: 600, color: Palette.textSoft),
                        ),
                      ),
                    )
                  else
                    const GameIcon(GameIconType.arrow, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
