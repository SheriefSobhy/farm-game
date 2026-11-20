import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/sprites.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/order.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// The orders board: three customers, each wanting a few things.
class OrdersPanel extends StatelessWidget {
  const OrdersPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < state.orders.length; i++)
            _OrderCard(state: state, index: i, order: state.orders[i]),
          Text(
            'Orders pay more than the market and give lots of XP!',
            textAlign: TextAlign.center,
            style: AppText.style(14, weight: 500, color: Palette.textSoft),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.state, required this.index, required this.order});

  final GameState state;
  final int index;
  final Order order;

  void _fill(BuildContext context) {
    final result = state.fillOrder(index);
    showGameMessage(context, result);
    if (result.ok) {
      final fx = GameScope.of(context).fx;
      fx.flyFrom(context, GameIconType.coin, 'coin', count: 5);
      fx.flyFrom(context, GameIconType.star, 'xp', count: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = state.nowMs;
    if (order.isWaiting(now)) {
      final secs = ((order.readyAtMs - now) / 1000).ceil();
      return PaperCard(
        color: Palette.cream,
        child: Row(
          children: [
            const GameIcon(GameIconType.clock, size: 34),
            const SizedBox(width: 10),
            Text('New customer in ${secs}s', style: AppText.style(18, weight: 600)),
          ],
        ),
      );
    }
    final canFill = state.canFill(order);
    return PaperCard(
      color: canFill ? const Color(0xFFEFF9E3) : Palette.paper,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(painter: _FacePainter(order.customer)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerNames[order.customer % customerNames.length],
                  style: AppText.style(18, weight: 700),
                ),
              ),
              IconText(
                '+${order.coins} $coinToken  +${order.xp} $xpToken',
                style: AppText.style(17, weight: 700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final e in order.items.entries) ...[
                _Want(item: e.key, need: e.value, have: state.count(e.key)),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              _TrashButton(
                onTap: () =>
                    showGameMessage(context, state.skipOrder(index), successSound: Sfx.tap),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ChunkyButton(
              label: canFill ? 'Deliver!' : 'Not ready yet',
              height: 44,
              fontSize: 19,
              onPressed: canFill ? () => _fill(context) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Want extends StatelessWidget {
  const _Want({required this.item, required this.need, required this.have});

  final Item item;
  final int need;
  final int have;

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: ok ? Palette.grassLight : Palette.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.outline, width: 3),
      ),
      child: Column(
        children: [
          GameIcon(itemIcon(item), size: 30),
          Text(
            '${have > need ? need : have}/$need',
            style: AppText.style(14, weight: 700, color: ok ? Palette.greenDark : Palette.redDark),
          ),
        ],
      ),
    );
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const GameIcon(GameIconType.cross, size: 26),
          Text('Skip', style: AppText.style(12, weight: 600, color: Palette.textSoft)),
        ],
      ),
    );
  }
}

/// Draws the farmer sprite tinted a little differently for each customer.
class _FacePainter extends CustomPainter {
  _FacePainter(this.customer);
  final int customer;

  @override
  void paint(Canvas canvas, Size size) {
    Art.fit(canvas, customer.isEven ? S.farmer : S.farmerGirl, Offset.zero & size);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.customer != customer;
}
