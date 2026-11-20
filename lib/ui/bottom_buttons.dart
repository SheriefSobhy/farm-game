import 'package:flutter/material.dart';

/// The five tabs. The order must match the IndexedStack in GameScreen.
enum GameTab {
  farm('🚜', 'Farm'),
  mill('🏭', 'Mill'),
  oven('🔥', 'Oven'),
  market('🏪', 'Market'),
  shop('🛒', 'Shop');

  const GameTab(this.emoji, this.label);
  final String emoji;
  final String label;
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GameTab selected;
  final ValueChanged<GameTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF558B2F),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (final tab in GameTab.values)
                Expanded(child: _TabButton(
                  tab: tab,
                  selected: tab == selected,
                  onTap: () => onSelected(tab),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final GameTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? const Color(0xFFFFD54F) : const Color(0xFF7CB342),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tab.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? const Color(0xFF33691E) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
