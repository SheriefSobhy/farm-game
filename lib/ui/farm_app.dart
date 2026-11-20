import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import '../services/save_service.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';

class FarmApp extends StatelessWidget {
  const FarmApp({
    super.key,
    required this.state,
    required this.saveService,
    required this.sound,
  });

  final GameState state;
  final SaveService saveService;
  final SoundService sound;

  static const double maxGameWidth = 480;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppText.family,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.green),
        scaffoldBackgroundColor: Palette.cream,
      ),
      // On wide screens (tablet, desktop browser) keep a phone-sized,
      // centered column. On a phone this has no visible effect.
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FB24A), Color(0xFF4F7F2B)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxGameWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 24)],
              ),
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
      home: GameScreen(state: state, saveService: saveService, sound: sound),
    );
  }
}
