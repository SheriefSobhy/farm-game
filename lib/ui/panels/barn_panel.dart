import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../game_config.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Everything stored in the barn, how full it is, and the upgrade button.
class BarnPanel extends StatelessWidget {
  const BarnPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final fill = state.stored / state.barnCapacity;
        final items = Item.values.where((i) => state.count(i) > 0).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaperCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Storage', style: AppText.style(18, weight: 700)),
                      const Spacer(),
                      Text(
                        '${state.stored} / ${state.barnCapacity}',
                        style: AppText.style(
                          18,
                          weight: 700,
                          color: fill >= 1 ? Palette.redDark : Palette.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: fill.clamp(0.0, 1.0),
                      minHeight: 12,
                      color: fill >= 0.9 ? Palette.red : Palette.green,
                      backgroundColor: Palette.woodDeep,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ChunkyButton(
                      label:
                          'Upgrade +${GameConfig.barnCapacityPerUpgrade}  '
                          '${state.barnUpgradePrice} $coinToken',
                      height: 46,
                      fontSize: 18,
                      color: Palette.blue,
                      darkColor: Palette.blueDark,
                      onPressed: () => showGameMessage(context, state.upgradeBarn()),
                    ),
                  ),
                ],
              ),
            ),
            PaperCard(
              child: items.isEmpty
                  ? Text(
                      'The barn is empty. Harvest some crops!',
                      style: AppText.style(16, weight: 500, color: Palette.textSoft),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in items) _Slot(item: item, count: state.count(item)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.item, required this.count});

  final Item item;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Palette.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline, width: 3),
      ),
      child: Column(
        children: [
          GameIcon(itemIcon(item), size: 36),
          FittedBox(child: Text(item.label, style: AppText.style(13, weight: 600))),
          Text('$count', style: AppText.style(18, weight: 700)),
        ],
      ),
    );
  }
}
