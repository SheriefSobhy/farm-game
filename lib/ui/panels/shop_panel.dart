import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../game_config.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

/// Buy land plots, the mill and the oven; sound setting; new game.
class ShopPanel extends StatelessWidget {
  const ShopPanel({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final sound = GameScope.of(context).sound;
    return ListenableBuilder(
      listenable: Listenable.merge([state, sound]),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShopCard(
            icon: GameIconType.wheatSeeds,
            title: 'Field plot',
            subtitle:
                'You own ${state.plots.length} / ${GameConfig.maxPlots} plots',
            buttonLabel: state.canBuyMorePlots
                ? 'Buy for ${state.nextPlotPrice} $coinToken'
                : 'Farm is full!',
            owned: !state.canBuyMorePlots,
            onPressed: state.canBuyMorePlots
                ? () => showGameMessage(context, state.buyPlot())
                : null,
          ),
          _buildingCard(context, state.mill, GameIconType.windmill),
          _buildingCard(context, state.oven, GameIconType.oven),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GameIcon(
                  sound.enabled ? GameIconType.soundOn : GameIconType.soundOff,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sound effects',
                    style: AppText.style(20, weight: 650),
                  ),
                ),
                _CozyToggle(
                  value: sound.enabled,
                  onChanged: (v) {
                    sound.setEnabled(v);
                    sound.play(Sfx.tap);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _confirmReset(context),
              child: Text(
                'Start a new game',
                style: AppText.style(16, weight: 500, color: Palette.redDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingCard(
    BuildContext context,
    ProductionBuilding b,
    GameIconType icon,
  ) {
    final r = b.recipe;
    return _ShopCard(
      icon: icon,
      title: r.buildingName,
      subtitle:
          'Turns ${r.inputAmount} ${r.input.token} into ${r.outputAmount} ${r.output.token}',
      buttonLabel: b.owned ? 'Owned' : 'Buy for ${r.price} $coinToken',
      owned: b.owned,
      onPressed: b.owned
          ? null
          : () => showGameMessage(context, state.buyBuilding(b)),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final scope = GameScope.of(context);
    scope.sound.play(Sfx.tap);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: PaperCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GameIcon(GameIconType.warning, size: 56),
              const SizedBox(height: 8),
              Text('Start a new game?', style: AppText.style(24, weight: 700)),
              const SizedBox(height: 6),
              Text(
                'All your coins, crops and buildings will be gone.',
                textAlign: TextAlign.center,
                style: AppText.style(16, weight: 500, color: Palette.textSoft),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ChunkyButton(
                      label: 'Keep',
                      tapSound: Sfx.tap,
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChunkyButton(
                      label: 'Reset',
                      color: Palette.red,
                      darkColor: Palette.redDark,
                      tapSound: Sfx.tap,
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true) state.resetGame();
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.owned,
    required this.onPressed,
  });

  final GameIconType icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool owned;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Palette.cream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Palette.paperDark, width: 2.5),
                ),
                child: GameIcon(icon, size: 58),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.style(22, weight: 700)),
                    IconText(
                      subtitle,
                      textAlign: TextAlign.start,
                      style: AppText.style(
                        15,
                        weight: 500,
                        color: Palette.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (owned) const GameIcon(GameIconType.check, size: 34),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ChunkyButton(label: buttonLabel, onPressed: onPressed),
          ),
        ],
      ),
    );
  }
}

/// A big friendly on/off switch.
class _CozyToggle extends StatelessWidget {
  const _CozyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? Palette.green : Palette.disabled,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? Palette.greenDark : Palette.disabledDark,
              width: 3,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x334E2F1E), width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
