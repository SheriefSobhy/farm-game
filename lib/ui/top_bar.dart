import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/item.dart';

/// Always-visible bar with coins, wheat, flour and bread.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF558B2F),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => Row(
          children: [
            _Stat(emoji: coinEmoji, value: state.coins),
            for (final item in Item.values)
              _Stat(emoji: item.emoji, value: state.count(item)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.value});

  final String emoji;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$emoji $value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF33691E),
            ),
          ),
        ),
      ),
    );
  }
}
