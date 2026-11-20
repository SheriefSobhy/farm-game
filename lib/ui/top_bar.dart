import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import 'game_scope.dart';
import 'widgets/animated_count.dart';
import 'widgets/icon_text.dart';
import 'widgets/surfaces.dart';

/// Wooden bar that always shows coins and the main items.
/// Each icon is a target for flying icons ("coin", "item:wheat", ...).
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final fx = GameScope.of(context).fx;
    return WoodPanel(
      planks: 2,
      border: false,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 9),
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => Row(
          children: [
            Stat(
              icon: GameIconType.coin,
              value: state.coins,
              iconKey: fx.target('coin'),
              flex: 4,
            ),
            for (final item in Item.values)
              Stat(
                icon: itemIcon(item),
                value: state.count(item),
                iconKey: fx.target('item:${item.name}'),
              ),
          ],
        ),
      ),
    );
  }
}

/// An icon with a number that counts up and down and bumps on change.
class Stat extends StatefulWidget {
  const Stat({
    super.key,
    required this.icon,
    required this.value,
    required this.iconKey,
    this.flex = 3,
  });

  final GameIconType icon;
  final int value;
  final GlobalKey iconKey;
  final int flex;

  @override
  State<Stat> createState() => _StatState();
}

class _StatState extends State<Stat> with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Stat old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: AnimatedBuilder(
        animation: _bump,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.14 * sin(_bump.value * pi),
          child: child,
        ),
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.only(left: 2, right: 7),
          decoration: BoxDecoration(
            color: Palette.woodDeep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Palette.outline, width: 3),
          ),
          child: Row(
            children: [
              GameIcon(widget.icon, key: widget.iconKey, size: 28),
              const SizedBox(width: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AnimatedCount(
                    value: widget.value,
                    style: AppText.light(18, weight: 650),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
