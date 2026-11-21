import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import 'game_scope.dart';
import 'widgets/animated_count.dart';
import 'widgets/surfaces.dart';

const Color _barText = Color(0xFF5A3418);

/// Glossy pills with the level (and XP bar), coins and gems.
/// Icons are targets for flying icons ("xp", "coin", "gem").
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final fx = GameScope.of(context).fx;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 9),
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => Row(
          children: [
            Expanded(
              flex: 5,
              child: LevelBadge(state: state, iconKey: fx.target('xp')),
            ),
            Stat(icon: GameIconType.coin, value: state.coins, iconKey: fx.target('coin'), flex: 4),
            Stat(icon: GameIconType.gem, value: state.gems, iconKey: fx.target('gem'), flex: 3),
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
        builder: (context, child) =>
            Transform.scale(scale: 1 + 0.14 * sin(_bump.value * pi), child: child),
        child: GlossyBox(
          height: 38,
          radius: 19,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.only(left: 1, right: 10),
          child: Row(
            children: [
              GameIcon(widget.icon, key: widget.iconKey, size: 32),
              const SizedBox(width: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AnimatedCount(
                    value: widget.value,
                    style: AppText.style(19, weight: 700, color: _barText),
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

/// A star with the level number, and an XP bar that fills toward the next
/// level.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.state, required this.iconKey});

  final GameState state;
  final GlobalKey iconKey;

  @override
  Widget build(BuildContext context) {
    return GlossyBox(
      height: 38,
      radius: 19,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GameIcon(GameIconType.star, key: iconKey, size: 36),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${state.level}',
                    style: AppText.light(state.level > 9 ? 11 : 13, weight: 700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level ${state.level}', style: AppText.style(13, weight: 700, color: _barText)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: state.levelProgress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A4D24),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, 1)),
                      ],
                    ),
                    padding: const EdgeInsets.all(1.5),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v.clamp(0.06, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFC8F56E), Color(0xFF4DB52A)],
                          ),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.fromLTRB(3, 1, 3, 0),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
