import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/save_service.dart';
import 'game_screen.dart';

class FarmApp extends StatelessWidget {
  const FarmApp({super.key, required this.state, required this.saveService});

  final GameState state;
  final SaveService saveService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7CB342)),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        useMaterial3: true,
      ),
      // On wide screens (tablet, desktop browser) keep a phone-sized,
      // centered column. On a phone this has no visible effect.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFF33691E),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxGameWidth),
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: GameScreen(state: state, saveService: saveService),
    );
  }

  static const double maxGameWidth = 480;
}
