import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Sell items for coins.
class MarketPanel extends StatelessWidget {
  const MarketPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in Item.values) _ItemRow(state: state, item: item),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.state, required this.item});

  final GameState state;
  final Item item;

  void _sell(BuildContext context, int amount) {
    final result = state.sell(item, amount);
    showGameMessage(context, result);
    if (result.ok) {
      GameScope.of(context).fx.flyFrom(
        context,
        GameIconType.coin,
        'coin',
        count: amount.clamp(1, 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = state.count(item);
    return PaperCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Palette.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Palette.outline, width: 3),
            ),
            child: GameIcon(itemIcon(item), size: 40),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.label}  x$owned',
                  style: AppText.style(19, weight: 700),
                ),
                IconText(
                  '${item.sellPrice} $coinToken each',
                  textAlign: TextAlign.start,
                  style: AppText.style(
                    15,
                    weight: 500,
                    color: Palette.textSoft,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: ChunkyButton(
              label: 'Sell 1',
              height: 44,
              fontSize: 17,
              color: Palette.blue,
              darkColor: Palette.blueDark,
              onPressed: owned > 0 ? () => _sell(context, 1) : null,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 92,
            child: ChunkyButton(
              label: owned > 0
                  ? 'All ${owned * item.sellPrice}$coinToken'
                  : 'All',
              height: 44,
              fontSize: 17,
              color: Palette.green,
              darkColor: Palette.greenDark,
              onPressed: owned > 0 ? () => _sell(context, owned) : null,
            ),
          ),
        ],
      ),
    );
  }
}
