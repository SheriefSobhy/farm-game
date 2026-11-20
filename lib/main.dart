import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art/sprites.dart';
import 'models/game_state.dart';
import 'services/save_service.dart';
import 'services/sound_service.dart';
import 'ui/farm_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Browsers don't allow locking orientation for normal pages, so only lock
  // it in the native app. On web the layout is kept phone-sized instead.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final saveService = SaveService();
  final sound = SoundService();
  final state = GameState();
  final saved = await saveService.load();
  if (saved != null) state.loadFromJson(saved);
  await sound.init();
  await Art.load();

  runApp(FarmApp(state: state, saveService: saveService, sound: sound));
}
