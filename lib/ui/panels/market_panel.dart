import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/item.dart';
import '../widgets/big_button.dart';
import '../widgets/game_message.dart';

/// Sell wheat, flour and bread for coins.
class MarketPanel extends StatelessWidget {
  const MarketPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🏪 Market',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final item in Item.values) _itemCard(context, item),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, Item item) {
    final owned = state.count(item);
    return PanelCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.sellPrice} $coinEmoji each  •  you have $owned',
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BigButton(
                  label: 'Sell 1',
                  color: const Color(0xFF29B6F6),
                  onPressed: () =>
                      showGameMessage(context, state.sell(item, 1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BigButton(
                  label: 'Sell all',
                  color: const Color(0xFF0288D1),
                  onPressed: () =>
                      showGameMessage(context, state.sellAll(item)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
