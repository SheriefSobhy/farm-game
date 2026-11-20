import 'package:flutter/widgets.dart';

import '../services/sound_service.dart';
import 'widgets/game_message.dart';

/// Gives every widget below the game screen access to sound and messages.
class GameScope extends InheritedWidget {
  const GameScope({
    super.key,
    required this.sound,
    required this.toasts,
    required super.child,
  });

  final SoundService sound;
  final ToastController toasts;

  static GameScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope not found above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(GameScope oldWidget) =>
      sound != oldWidget.sound || toasts != oldWidget.toasts;
}
