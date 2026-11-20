import 'package:flutter/material.dart';

import '../../game_config.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../widgets/big_button.dart';
import '../widgets/game_message.dart';

/// Buy land plots, the mill and the oven.
class ShopPanel extends StatelessWidget {
  const ShopPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🛒 Shop',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _shopCard(
            emoji: '🟫',
            title: 'Land plot',
            subtitle:
                'You own ${state.plots.length} / ${GameConfig.maxPlots} plots',
            buttonLabel: state.canBuyMorePlots
                ? 'Buy for ${state.nextPlotPrice} $coinEmoji'
                : 'Farm is full ✅',
            onPressed: state.canBuyMorePlots
                ? () => showGameMessage(context, state.buyPlot())
                : null,
          ),
          _buildingCard(context, state.mill),
          _buildingCard(context, state.oven),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _confirmReset(context),
            child: const Text('Start a new game',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildingCard(BuildContext context, ProductionBuilding building) {
    final r = building.recipe;
    return _shopCard(
      emoji: r.emoji,
      title: r.buildingName,
      subtitle: 'Turns ${r.inputAmount} ${r.input.emoji} into '
          '${r.outputAmount} ${r.output.emoji}',
      buttonLabel: building.owned ? 'Owned ✅' : 'Buy for ${r.price} $coinEmoji',
      onPressed: building.owned
          ? null
          : () => showGameMessage(context, state.buyBuilding(building)),
    );
  }

  Widget _shopCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback? onPressed,
  }) {
    return PanelCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BigButton(label: buttonLabel, onPressed: onPressed),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('All your coins, items and buildings will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yes == true) state.resetGame();
  }
}
