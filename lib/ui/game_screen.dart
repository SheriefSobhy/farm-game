import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/farm_game.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import 'bottom_buttons.dart';
import 'panels/building_panel.dart';
import 'panels/market_panel.dart';
import 'panels/shop_panel.dart';
import 'top_bar.dart';
import 'widgets/game_message.dart';

/// The single main screen: top bar, the current tab, and bottom buttons.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.state, required this.saveService});

  final GameState state;
  final SaveService saveService;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final FarmGame _game =
      FarmGame(state: widget.state, onResult: _showResult);
  Timer? _tickTimer;
  Timer? _saveTimer;
  GameTab _tab = GameTab.farm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => widget.state.tick(),
    );
    _saveTimer = Timer.periodic(GameConfig.autoSaveInterval, (_) => _save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _showResult(ActionResult result) {
    if (mounted) showGameMessage(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TopBar(state: state),
            Expanded(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  GameWidget(game: _game),
                  BuildingPanel(
                    state: state,
                    building: state.mill,
                    onGoToShop: () => setState(() => _tab = GameTab.shop),
                  ),
                  BuildingPanel(
                    state: state,
                    building: state.oven,
                    onGoToShop: () => setState(() => _tab = GameTab.shop),
                  ),
                  MarketPanel(state: state),
                  ShopPanel(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomButtons(
        selected: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
    );
  }
}
