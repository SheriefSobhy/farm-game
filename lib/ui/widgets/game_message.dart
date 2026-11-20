import 'dart:async';

import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/action_result.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import 'icon_text.dart';

/// Plays the right sound for [result] and shows its message (if any).
/// [successSound] is played when the action worked.
void showGameMessage(BuildContext context, ActionResult result, {Sfx successSound = Sfx.coin}) {
  final scope = GameScope.of(context);
  scope.sound.play(result.ok ? successSound : Sfx.error);
  scope.toasts.show(result);
}

class ToastData {
  ToastData(this.id, this.result);
  final int id;
  final ActionResult result;
}

/// Holds the message currently shown; it hides itself after a moment.
class ToastController extends ValueNotifier<ToastData?> {
  ToastController() : super(null);

  int _nextId = 0;
  Timer? _timer;

  void show(ActionResult result) {
    if (result.message == null) return;
    value = ToastData(_nextId++, result);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2300), () => value = null);
  }

  void hide() {
    _timer?.cancel();
    value = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// A paper note with a wooden frame that pops in near the top of the screen.
class ToastView extends StatelessWidget {
  const ToastView({super.key, required this.controller});

  final ToastController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToastData?>(
      valueListenable: controller,
      builder: (context, data, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        reverseDuration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -0.4),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
        child: data == null
            ? const SizedBox.shrink(key: ValueKey(-1))
            : GestureDetector(
                key: ValueKey(data.id),
                onTap: controller.hide,
                child: _ToastCard(result: data.result),
              ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.result});

  final ActionResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: Palette.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.woodDark, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x445A3A22), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(result.ok ? GameIconType.check : GameIconType.warning, size: 34),
          const SizedBox(width: 10),
          Flexible(
            child: IconText(
              result.message ?? '',
              textAlign: TextAlign.start,
              style: AppText.style(18, color: Palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
