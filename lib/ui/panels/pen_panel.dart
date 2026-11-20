import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/defs.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Chicken coop or cow pasture: buy animals and see what they're doing.
class PenPanel extends StatelessWidget {
  const PenPanel({super.key, required this.state, required this.kind});

  final GameState state;
  final AnimalKind kind;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final pen = state.pens[kind]!;
        final d = pen.def;
        final now = state.nowMs;
        final unlocked = state.isAnimalUnlocked(kind);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaperCard(
              child: Column(
                children: [
                  IconText(
                    'Feed ${d.feed.token} → ${d.product.token} in ${d.time.inSeconds}s',
                    style: AppText.style(18, weight: 600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the pen on the farm to collect and feed.',
                    style: AppText.style(14, weight: 500, color: Palette.textSoft),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final a in pen.animals)
                        _AnimalBox(
                          kind: kind,
                          status: pen.isReady(a, now)
                              ? 'Ready!'
                              : (a.isHungry
                                    ? 'Hungry'
                                    : '${((d.time.inMilliseconds - (now - a.fedAtMs!)) / 1000).ceil()}s'),
                          ready: pen.isReady(a, now),
                        ),
                      for (var i = pen.animals.length; i < d.maxCount; i++)
                        const _AnimalBox(kind: null, status: '', ready: false),
                    ],
                  ),
                ],
              ),
            ),
            if (!unlocked)
              PaperCard(
                child: Column(
                  children: [
                    const GameIcon(GameIconType.lock, size: 40),
                    Text(
                      '${d.name}s unlock at level ${d.unlockLevel}',
                      style: AppText.style(19, weight: 700),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ChunkyButton(
                  label: pen.animals.length >= d.maxCount
                      ? 'The ${d.penName} is full'
                      : 'Buy a ${d.name.toLowerCase()}  ${d.price} $coinToken',
                  onPressed: pen.animals.length >= d.maxCount
                      ? null
                      : () => showGameMessage(context, state.buyAnimal(kind)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnimalBox extends StatelessWidget {
  const _AnimalBox({required this.kind, required this.status, required this.ready});

  final AnimalKind? kind;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final k = kind;
    return Container(
      width: 64,
      height: 70,
      decoration: BoxDecoration(
        color: k == null ? Palette.paper : (ready ? Palette.grassLight : Palette.cream),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline.withValues(alpha: k == null ? 0.3 : 1), width: 3),
      ),
      child: k == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameIcon(
                  k == AnimalKind.chicken ? GameIconType.chicken : GameIconType.cow,
                  size: 36,
                ),
                Text(status, style: AppText.style(13, weight: 700)),
              ],
            ),
    );
  }
}
