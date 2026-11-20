import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../widgets/big_button.dart';
import '../widgets/game_message.dart';

/// Screen for the Mill or the Oven.
class BuildingPanel extends StatelessWidget {
  const BuildingPanel({
    super.key,
    required this.state,
    required this.building,
    required this.onGoToShop,
  });

  final GameState state;
  final ProductionBuilding building;
  final VoidCallback onGoToShop;

  @override
  Widget build(BuildContext context) {
    final recipe = building.recipe;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PanelCard(
            child: Column(
              children: [
                Text(recipe.emoji, style: const TextStyle(fontSize: 72)),
                Text(
                  recipe.buildingName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${recipe.inputAmount} ${recipe.input.emoji}  ➜  '
                  '${recipe.outputAmount} ${recipe.output.emoji}',
                  style: const TextStyle(fontSize: 30),
                ),
                Text(
                  '${recipe.inputAmount} ${recipe.input.label.toLowerCase()} → '
                  '${recipe.outputAmount} ${recipe.output.label.toLowerCase()} '
                  'in ${recipe.duration.inSeconds} seconds',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                if (building.owned)
                  ..._ownedContent(context, recipe)
                else
                  ..._notOwnedContent(context, recipe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _ownedContent(BuildContext context, Recipe recipe) {
    final now = state.nowMs;
    final working = building.isWorking;
    return [
      Text(
        'You have ${state.count(recipe.input)} ${recipe.input.emoji}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: building.progress(now),
          minHeight: 18,
          backgroundColor: const Color(0xFFE0E0E0),
          color: const Color(0xFFFFB300),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        working
            ? 'Working… ${(building.remainingMs(now) / 1000).ceil()}s left'
            : 'Ready to work',
        style: const TextStyle(fontSize: 16),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: BigButton(
          label: working
              ? 'Working…'
              : '${recipe.actionVerb}! (${recipe.inputAmount} ${recipe.input.emoji})',
          color: const Color(0xFFFB8C00),
          onPressed: working
              ? null
              : () => showGameMessage(context, state.startProduction(building)),
        ),
      ),
    ];
  }

  List<Widget> _notOwnedContent(BuildContext context, Recipe recipe) {
    return [
      Text(
        'You don\'t have a ${recipe.buildingName} yet.',
        style: const TextStyle(fontSize: 18),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: BigButton(
          label: 'Buy for ${recipe.price} $coinEmoji',
          onPressed: () =>
              showGameMessage(context, state.buyBuilding(building)),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: onGoToShop, child: const Text('Open Shop')),
    ];
  }
}
