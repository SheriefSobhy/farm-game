import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../game/farm_game.dart';
import '../game/farm_layout.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import '../models/production_building.dart';
import '../services/save_service.dart';
import '../services/sound_service.dart';
import 'bottom_buttons.dart';
import 'game_scope.dart';
import 'panels/barn_panel.dart';
import 'panels/building_panel.dart';
import 'panels/market_panel.dart';
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
    onHarvest: _flyFromFarm,
    onOpenSpot: _openSpot,
  );
  final GlobalKey _gameKey = GlobalKey();

  Timer? _tickTimer;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.onProductionDone = _onProductionDone;
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => widget.state.tick(),
    );
    _saveTimer = Timer.periodic(GameConfig.autoSaveInterval, (_) => _save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.onProductionDone = null;
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
      widget.state.tick();
    }
  }

  void _save({bool force = false}) {
    final dirty = widget.state.consumeDirty();
    if (dirty || force) widget.saveService.save(widget.state.toJson());
  }

  void _onProductionDone(ProductionBuilding b) {
    if (!mounted) return;
    widget.sound.play(Sfx.done);
    final r = b.recipe;
    GameScope.of(context).toasts.show(
      ActionResult.ok(
        '${r.output.label} is ready! +${r.outputAmount} ${r.output.token}',
      ),
    );
  }

  /// Flies item icons from a spot on the farm up to the top bar.
  void _flyFromFarm(Offset fromInGame, Item item, int count) {
    final box = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    GameScope.of(context).fx.fly(
      itemIcon(item),
      box.localToGlobal(fromInGame),
      'item:${item.name}',
      count: count,
    );
  }

  void _openSpot(FarmSpot spot) {
    final s = widget.state;
    switch (spot) {
      case FarmSpot.barn:
        _openBarn();
      case FarmSpot.market:
        _openMarket();
      case FarmSpot.mill:
        openSheet(
          context,
          title: 'Mill',
          icon: GameIconType.windmill,
          builder: (_) => BuildingPanel(state: s, building: s.mill),
        );
      case FarmSpot.oven:
        openSheet(
          context,
          title: 'Oven',
          icon: GameIconType.oven,
          builder: (_) => BuildingPanel(state: s, building: s.oven),
        );
    }
  }

  void _openBarn() => openSheet(
    context,
    title: 'Barn',
    icon: GameIconType.barn,
    builder: (_) => BarnPanel(state: widget.state),
  );

  void _openMarket() => openSheet(
    context,
    title: 'Market',
    icon: GameIconType.stall,
    builder: (_) => MarketPanel(state: widget.state),
  );

  void _openShop() => openSheet(
    context,
    title: 'Shop',
    icon: GameIconType.bag,
    builder: (_) => ShopPanel(state: widget.state),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.grass,
      body: Column(
        children: [
          ColoredBox(
            color: Palette.wood,
            child: SafeArea(bottom: false, child: TopBar(state: widget.state)),
          ),
          const SizedBox(
            height: 3,
            width: double.infinity,
            child: ColoredBox(color: Palette.outline),
          ),
          Expanded(
            child: ClipRect(
              child: KeyedSubtree(
                key: _gameKey,
                child: GameWidget(game: _game),
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
      bottomNavigationBar: BottomButtons(
        buttons: [
          BarButton(GameIconType.barn, 'Barn', _openBarn, targetName: 'barn'),
          BarButton(GameIconType.stall, 'Market', _openMarket),
          BarButton(GameIconType.bag, 'Shop', _openShop),
        ],
      ),
    );
  }
}
