import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../services/sound_service.dart';
import 'game_scope.dart';
import 'game_screen.dart';
import 'widgets/fx_layer.dart';
import 'widgets/game_message.dart';

class FarmApp extends StatefulWidget {
  const FarmApp({super.key, required this.state, required this.saveService, required this.sound});

  final GameState state;
  final SaveService saveService;
  final SoundService sound;

  static const double maxGameWidth = 480;

  @override
  State<FarmApp> createState() => _FarmAppState();
}

class _FarmAppState extends State<FarmApp> {
  final ToastController _toasts = ToastController();
  final FxController _fx = FxController();

  @override
  void dispose() {
    _toasts.dispose();
    _fx.dispose();
    super.dispose();
  }

  Widget _frame(BuildContext context, Widget? child) {
    return GameScope(
      sound: widget.sound,
      toasts: _toasts,
      fx: _fx,
      child: Listener(
        // The first touch anywhere unlocks audio (needed by web browsers).
        onPointerDown: (_) => widget.sound.unlock(),
        child: ColoredBox(
          color: const Color(0xFF4E974C),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: FarmApp.maxGameWidth),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [BoxShadow(color: Color(0x553F2631), blurRadius: 24)],
                ),
                child: ClipRect(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Stack(
                      children: [
                        Positioned.fill(child: child ?? const SizedBox()),
                        Positioned(
                          top: MediaQuery.paddingOf(context).top + 64,
                          left: 0,
                          right: 0,
                          child: Center(child: ToastView(controller: _toasts)),
                        ),
                        Positioned.fill(child: FxLayer(controller: _fx)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppText.family,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.green),
        scaffoldBackgroundColor: Palette.grass,
      ),
      // On wide screens (tablet, desktop browser) keep a phone-sized,
      // centered column. On a phone this has no visible effect.
      builder: (context, child) => _frame(context, child),
      home: GameScreen(state: widget.state, saveService: widget.saveService, sound: widget.sound),
    );
  }
}
