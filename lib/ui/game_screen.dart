import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../game/farm_game.dart';
import '../game_config.dart';
import '../models/action_result.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import '../models/production_building.dart';
import '../services/save_service.dart';
import '../services/sound_service.dart';
import 'bottom_buttons.dart';
import 'game_scope.dart';
import 'panels/building_panel.dart';
import 'panels/market_panel.dart';
import 'panels/shop_panel.dart';
import 'top_bar.dart';
import 'widgets/game_message.dart';

/// The single main screen: top bar, the current tab, and bottom buttons.
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
    onMessage: _toasts.show,
    onHarvest: _flyWheat,
  );
  final ToastController _toasts = ToastController();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _gameKey = GlobalKey();
  final GlobalKey _coinKey = GlobalKey();
  final Map<Item, GlobalKey> _itemKeys = {for (final i in Item.values) i: GlobalKey()};
  final List<_Flight> _flights = [];
  int _nextFlightId = 0;

  Timer? _tickTimer;
  Timer? _saveTimer;
  GameTab _tab = GameTab.farm;

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
    _toasts.dispose();
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
    widget.sound.play(Sfx.done);
    final r = b.recipe;
    _toasts.show(ActionResult.ok(
        '${r.output.label} is ready! +${r.outputAmount} ${r.output.token}'));
  }

  /// Sends three little wheat icons from the plot up to the top bar.
  void _flyWheat(Vector2 from) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final gameBox = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox = _itemKeys[Item.wheat]!.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || gameBox == null || targetBox == null) return;
    final start = stackBox.globalToLocal(gameBox.localToGlobal(Offset(from.x, from.y)));
    final end = stackBox.globalToLocal(
        targetBox.localToGlobal(targetBox.size.center(Offset.zero)));
    for (var i = 0; i < GameConfig.wheatPerHarvest; i++) {
      Future.delayed(Duration(milliseconds: 90 * i), () {
        if (!mounted) return;
        setState(() => _flights.add(_Flight(
              _nextFlightId++,
              start + Offset((i - 1) * 14.0, 0),
              end,
            )));
      });
    }
  }

  void _select(GameTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pages = <Widget>[
      KeyedSubtree(key: _gameKey, child: GameWidget(game: _game)),
      BuildingPanel(state: state, building: state.mill, onGoToShop: () => _select(GameTab.shop)),
      BuildingPanel(state: state, building: state.oven, onGoToShop: () => _select(GameTab.shop)),
      MarketPanel(state: state),
      ShopPanel(state: state),
    ];

    return GameScope(
      sound: widget.sound,
      toasts: _toasts,
      child: Listener(
        // The first touch anywhere unlocks audio (needed by web browsers).
        onPointerDown: (_) => widget.sound.unlock(),
        child: Scaffold(
          backgroundColor: Palette.cream,
          body: Stack(
            key: _stackKey,
            children: [
              Column(
                children: [
                  ColoredBox(
                    color: Palette.woodDark,
                    child: SafeArea(
                      bottom: false,
                      child: TopBar(state: state, coinKey: _coinKey, itemKeys: _itemKeys),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF4DA), Color(0xFFF5DFB4)],
                              ),
                            ),
                            child: IndexedStack(
                              index: _tab.index,
                              children: [
                                for (var i = 0; i < pages.length; i++)
                                  TickerMode(enabled: i == _tab.index, child: pages[i]),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(child: ToastView(controller: _toasts)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              for (final f in _flights)
                _FlyingIcon(
                  key: ValueKey(f.id),
                  flight: f,
                  onDone: () => setState(() => _flights.remove(f)),
                ),
            ],
          ),
          bottomNavigationBar: BottomButtons(selected: _tab, onSelected: _select),
        ),
      ),
    );
  }
}

class _Flight {
  _Flight(this.id, this.from, this.to);
  final int id;
  final Offset from;
  final Offset to;
}

/// A wheat icon flying along a curve from a plot to the top bar.
class _FlyingIcon extends StatelessWidget {
  const _FlyingIcon({super.key, required this.flight, required this.onDone});

  final _Flight flight;
  final VoidCallback onDone;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    final a = flight.from;
    final b = flight.to;
    final control = Offset(a.dx + (b.dx - a.dx) * 0.15, a.dy - 140);
    return Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubic,
          onEnd: onDone,
          builder: (context, t, child) {
            final p = Offset(
              (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * control.dx + t * t * b.dx,
              (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * control.dy + t * t * b.dy,
            );
            final s = t < 0.15 ? 0.6 + t / 0.15 * 0.7 : 1.3 - (t - 0.15) * 0.6;
            return Transform.translate(
              offset: p - const Offset(_size / 2, _size / 2),
              child: Transform.scale(scale: s, child: child),
            );
          },
          child: const GameIcon(GameIconType.wheat, size: _size),
        ),
      ),
    );
  }
}
