import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../game_config.dart';
import '../models/game_state.dart';
import '../services/sound_service.dart';
import 'game_scope.dart';
import 'widgets/chunky_button.dart';
import 'widgets/surfaces.dart';

/// Full-screen "Level up!" celebration that lists what was unlocked.
Future<void> showLevelUp(BuildContext context, int level, List<Unlock> unlocks) {
  GameScope.of(context).sound.play(Sfx.done);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xAA1E1420),
    transitionDuration: const Duration(milliseconds: 550),
    pageBuilder: (context, a1, a2) => _LevelUpView(level: level, unlocks: unlocks),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
    ),
  );
}

class _LevelUpView extends StatefulWidget {
  const _LevelUpView({required this.level, required this.unlocks});

  final int level;
  final List<Unlock> unlocks;

  @override
  State<_LevelUpView> createState() => _LevelUpViewState();
}

class _LevelUpViewState extends State<_LevelUpView> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = GameConfig.levelUpCoinsBase + GameConfig.levelUpCoinsPerLevel * widget.level;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 210,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _spin,
                      builder: (context, _) => CustomPaint(
                        size: const Size(210, 210),
                        painter: _RaysPainter(_spin.value),
                      ),
                    ),
                    const GameIcon(GameIconType.star, size: 130),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        '${widget.level}',
                        style: AppText.style(44, weight: 700, color: Palette.outline),
                      ),
                    ),
                  ],
                ),
              ),
              Text('Level up!', style: AppText.light(40, weight: 700)),
              const SizedBox(height: 10),
              PaperCard(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text('Rewards', style: AppText.style(18, weight: 700, color: Palette.textSoft)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Reward(GameIconType.coin, '+$coins'),
                        const SizedBox(width: 18),
                        _Reward(GameIconType.gem, '+${GameConfig.levelUpGems}'),
                      ],
                    ),
                    if (widget.unlocks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'New on your farm',
                        style: AppText.style(18, weight: 700, color: Palette.textSoft),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final u in widget.unlocks) _UnlockTile(u)],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 220,
                child: ChunkyButton(
                  label: 'Awesome!',
                  color: Palette.gold,
                  darkColor: Palette.goldDark,
                  tapSound: Sfx.tap,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward(this.icon, this.text);
  final GameIconType icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GameIcon(icon, size: 32),
      const SizedBox(width: 4),
      Text(text, style: AppText.style(24, weight: 700)),
    ],
  );
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile(this.unlock);
  final Unlock unlock;

  @override
  Widget build(BuildContext context) {
    final icon = GameIconType.values.asNameMap()[unlock.icon] ?? GameIconType.star;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Palette.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline, width: 3),
      ),
      child: Column(
        children: [
          GameIcon(icon, size: 44),
          FittedBox(child: Text(unlock.name, style: AppText.style(14, weight: 700))),
        ],
      ),
    );
  }
}

/// Golden light rays turning slowly behind the star.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..color = Palette.gold.withValues(alpha: 0.35);
    for (var i = 0; i < 12; i++) {
      final a = t * 2 * pi + i * pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.12) * r, c.dy + sin(a - 0.12) * r)
        ..lineTo(c.dx + cos(a + 0.12) * r, c.dy + sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}
