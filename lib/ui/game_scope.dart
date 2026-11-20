import 'package:flutter/widgets.dart';

import '../services/sound_service.dart';
import 'widgets/fx_layer.dart';
import 'widgets/game_message.dart';

/// Gives every widget (including bottom sheets and dialogs) access to sound,
/// messages and flying icons.
class GameScope extends InheritedWidget {
  const GameScope({
    super.key,
    required this.sound,
    required this.toasts,
    required this.fx,
    required super.child,
  });

  final SoundService sound;
  final ToastController toasts;
  final FxController fx;

  static GameScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope not found above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(GameScope oldWidget) =>
      sound != oldWidget.sound || toasts != oldWidget.toasts || fx != oldWidget.fx;
}
