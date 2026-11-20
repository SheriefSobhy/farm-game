import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../services/sound_service.dart';
import 'game_scope.dart';
import 'widgets/surfaces.dart';

/// The five tabs. The order must match the IndexedStack in GameScreen.
enum GameTab {
  farm(GameIconType.barn, 'Farm'),
  mill(GameIconType.windmill, 'Mill'),
  oven(GameIconType.oven, 'Oven'),
  market(GameIconType.stall, 'Market'),
  shop(GameIconType.bag, 'Shop');

  const GameTab(this.icon, this.label);
  final GameIconType icon;
  final String label;
}

class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.selected, required this.onSelected});

  final GameTab selected;
  final ValueChanged<GameTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return WoodPanel(
      planks: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (final tab in GameTab.values)
                Expanded(
                  child: _TabButton(
                    tab: tab,
                    selected: tab == selected,
                    onTap: () {
                      GameScope.of(context).sound.play(Sfx.tap);
                      onSelected(tab);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({required this.tab, required this.selected, required this.onTap});

  final GameTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final scale = _down ? 0.9 : (selected ? 1.06 : 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: _down ? 70 : 500),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 74,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          transform: Matrix4.translationValues(0, selected ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? const [Color(0xFFFFF3C4), Palette.gold]
                  : const [Color(0x664A2812), Color(0x884A2812)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Palette.goldDark : Palette.woodDeep,
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x665E3719), offset: Offset(0, 4), blurRadius: 4)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameIcon(widget.tab.icon, size: selected ? 40 : 36),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.tab.label,
                  style: selected
                      ? AppText.style(14, weight: 700, color: Palette.woodDeep)
                      : AppText.light(14, weight: 650),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
