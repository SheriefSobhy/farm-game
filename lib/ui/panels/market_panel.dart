import 'package:flutter/material.dart';

import '../../art/farm_art.dart';
import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Sell wheat, flour and bread for coins.
class MarketPanel extends StatelessWidget {
  const MarketPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SceneFrame(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _StallScenePainter()),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  child: Center(
                    child: WoodPanel(
                      radius: 14,
                      planks: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                      child: Text('Market', style: AppText.light(24, weight: 700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final item in Item.values) _itemCard(context, item),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, Item item) {
    final owned = state.count(item);
    return PaperCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Palette.cream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Palette.paperDark, width: 2.5),
                ),
                child: GameIcon(itemIcon(item), size: 52),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: AppText.style(23, weight: 700)),
                    IconText(
                      '${item.sellPrice} $coinToken each',
                      textAlign: TextAlign.start,
                      style: AppText.style(16, weight: 500, color: Palette.textSoft),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Palette.woodDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Palette.woodDeep, width: 2),
                ),
                child: Text('x$owned', style: AppText.light(18, weight: 700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: 'Sell 1',
                  color: Palette.blue,
                  darkColor: Palette.blueDark,
                  onPressed: () => showGameMessage(context, state.sell(item, 1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  label: owned > 0 ? 'All +${owned * item.sellPrice} $coinToken' : 'Sell all',
                  color: Palette.blueDark,
                  darkColor: const Color(0xFF1F6491),
                  onPressed: () => showGameMessage(context, state.sellAll(item)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StallScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    drawSky(canvas, Rect.fromLTWH(0, 0, w, h * 0.7));
    drawHills(canvas, Offset.zero & size, h * 0.62);
    drawTree(canvas, Offset(w * 0.1, h * 0.92), h * 0.55);
    drawBush(canvas, Offset(w * 0.9, h * 0.97), h * 0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.92), width: h * 0.9, height: h * 0.1),
      Paint()..color = const Color(0x33000000),
    );
    drawStall(canvas, Rect.fromCenter(center: Offset(w / 2, h * 0.6), width: h * 0.8, height: h * 0.8));
  }

  @override
  bool shouldRepaint(_StallScenePainter oldDelegate) => false;
}
