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
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _s.tick());
    _saveTimer = Timer.periodic(GameConfig.autoSaveInterval, (_) => _save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _onLevelUp(int level, List<Unlock> unlocks) {
    if (!mounted) return;
    widget.sound.play(Sfx.done);
    final names = unlocks.map((u) => u.name).join(', ');
    GameScope.of(context).toasts.show(
      ActionResult.ok(
        'Level $level! +${GameConfig.levelUpGems} {gem}${names.isEmpty ? '' : '  New: $names'}',
      ),
    );
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
          ColoredBox(
            color: Palette.wood,
            child: SafeArea(bottom: false, child: TopBar(state: _s)),
          ),
          const SizedBox(
            height: 3,
            width: double.infinity,
            child: ColoredBox(color: Palette.outline),
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
                  Positioned(right: 8, top: 8, child: SeedPicker(state: _s)),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 3,
            width: double.infinity,
            child: ColoredBox(color: Palette.outline),
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
