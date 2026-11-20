import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../game_config.dart';
import '../../models/defs.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/order.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Daily reward (7-day streak) and today's three goals.
class DailyPanel extends StatelessWidget {
  const DailyPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final next = state.nextStreakDay;
        final claimed = !state.canClaimDaily;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PaperCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text('Daily reward', style: AppText.style(20, weight: 700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var d = 1; d <= 7; d++)
                        Expanded(
                          child: _Day(
                            day: d,
                            coins: state.dailyCoinsFor(d),
                            done: d < next || (claimed && d == next),
                            today: d == next,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ChunkyButton(
                      label: claimed ? 'Come back tomorrow!' : 'Claim day $next',
                      height: 46,
                      fontSize: 19,
                      color: Palette.gold,
                      darkColor: Palette.goldDark,
                      onPressed: claimed
                          ? null
                          : () {
                              final r = state.claimDaily();
                              showGameMessage(context, r);
                              if (r.ok) {
                                GameScope.of(
                                  context,
                                ).fx.flyFrom(context, GameIconType.coin, 'coin', count: 5);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Come every day — day 7 is a big one!',
                    style: AppText.style(14, weight: 500, color: Palette.textSoft),
                  ),
                ],
              ),
            ),
            Text("Today's goals", style: AppText.style(20, weight: 700)),
            const SizedBox(height: 6),
            for (var i = 0; i < state.todaysGoals.length; i++)
              _GoalCard(state: state, index: i, goal: state.todaysGoals[i]),
          ],
        );
      },
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.coins, required this.done, required this.today});

  final int day;
  final int coins;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final big = day == 7;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: done ? Palette.grassLight : (today ? Palette.goldLight : Palette.cream),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.outline, width: today ? 3 : 2),
      ),
      child: Column(
        children: [
          Text('Day $day', style: AppText.style(11, weight: 700)),
          GameIcon(
            done ? GameIconType.check : (big ? GameIconType.gift : GameIconType.coin),
            size: 24,
          ),
          FittedBox(child: Text('$coins', style: AppText.style(13, weight: 700))),
        ],
      ),
    );
  }
}

String goalText(GoalDef d) {
  final item = d.item;
  return switch (d.type) {
    GoalType.harvest => 'Harvest ${d.target} ${item!.label.toLowerCase()}',
    GoalType.make => 'Make ${d.target} ${item!.label.toLowerCase()}',
    GoalType.collect => 'Collect ${d.target} ${item!.label.toLowerCase()}s',
    GoalType.fillOrders => 'Deliver ${d.target} orders',
    GoalType.sell => 'Sell ${d.target} items at the market',
  };
}

GameIconType goalIcon(GoalDef d) => switch (d.type) {
  GoalType.fillOrders => GameIconType.scroll,
  GoalType.sell => GameIconType.coin,
  _ => itemIcon(d.item!),
};

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.state, required this.index, required this.goal});

  final GameState state;
  final int index;
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final d = state.goalDef(goal);
    final done = state.goalDone(goal);
    return PaperCard(
      padding: const EdgeInsets.all(10),
      color: goal.claimed ? Palette.cream : Palette.paper,
      child: Row(
        children: [
          GameIcon(goalIcon(d), size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goalText(d), style: AppText.style(16, weight: 700)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progress / d.target,
                    minHeight: 9,
                    color: Palette.gold,
                    backgroundColor: Palette.woodDeep,
                  ),
                ),
                Text(
                  '${goal.progress} / ${d.target}',
                  style: AppText.style(13, weight: 600, color: Palette.textSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: goal.claimed
                ? const Center(child: GameIcon(GameIconType.check, size: 34))
                : ChunkyButton(
                    label: '${GameConfig.goalRewardCoins}$coinToken',
                    height: 42,
                    fontSize: 17,
                    color: Palette.gold,
                    darkColor: Palette.goldDark,
                    onPressed: done
                        ? () {
                            final r = state.claimGoal(index);
                            showGameMessage(context, r);
                            if (r.ok) {
                              GameScope.of(context).fx.flyFrom(context, GameIconType.coin, 'coin');
                            }
                          }
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}
