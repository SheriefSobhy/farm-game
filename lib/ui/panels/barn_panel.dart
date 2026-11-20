import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Everything stored in the barn.
class BarnPanel extends StatelessWidget {
  const BarnPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => PaperCard(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in Item.values)
              _Slot(item: item, count: state.count(item)),
          ],
        ),
      ),
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
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: count > 0 ? Palette.cream : Palette.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline, width: 3),
      ),
      child: Column(
        children: [
          GameIcon(itemIcon(item), size: 40, opacity: count > 0 ? 1 : 0.35),
          Text(item.label, style: AppText.style(14, weight: 600)),
          Text('$count', style: AppText.style(20, weight: 700)),
        ],
      ),
    );
  }
}
