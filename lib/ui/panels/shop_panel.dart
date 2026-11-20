import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../game_config.dart';
import '../../models/defs.dart';
import '../../models/game_state.dart';
import '../../models/item.dart';
import '../../models/production_building.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import '../widgets/chunky_button.dart';
import '../widgets/game_message.dart';
import '../widgets/icon_text.dart';
import '../widgets/surfaces.dart';

GameIconType buildingIcon(BuildingKind k) => switch (k) {
  BuildingKind.mill => GameIconType.windmill,
  BuildingKind.oven => GameIconType.oven,
  BuildingKind.popcorn => GameIconType.popcornMachine,
  BuildingKind.feedMill => GameIconType.feedMill,
  BuildingKind.dairy => GameIconType.dairy,
};

/// Buy land, buildings and animals, upgrade the barn; sound; new game.
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Land'),
          _ShopRow(
            icon: GameIconType.wheatSeeds,
            title: 'Field plot',
            subtitle: 'You own ${state.plots.length} / ${GameConfig.maxPlots}',
            buttonLabel: state.canBuyMorePlots ? '${state.nextPlotPrice} $coinToken' : 'Full',
            done: !state.canBuyMorePlots,
            onPressed: state.canBuyMorePlots
                ? () => showGameMessage(context, state.buyPlot())
                : null,
          ),
          const _Heading('Buildings'),
          for (final k in BuildingKind.values) _building(context, state.buildings[k]!),
          const _Heading('Animals'),
          for (final a in GameConfig.animals) _animal(context, a),
          const _Heading('Barn'),
          _ShopRow(
            icon: GameIconType.barn,
            title: 'Bigger barn',
            subtitle:
                'Holds ${state.barnCapacity} → '
                '${state.barnCapacity + GameConfig.barnCapacityPerUpgrade} items',
            buttonLabel: '${state.barnUpgradePrice} $coinToken',
            done: false,
            onPressed: () => showGameMessage(context, state.upgradeBarn()),
          ),
          const _Heading('Settings'),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GameIcon(sound.enabled ? GameIconType.soundOn : GameIconType.soundOff, size: 40),
                const SizedBox(width: 10),
                Expanded(child: Text('Sound effects', style: AppText.style(19, weight: 650))),
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

  Widget _building(BuildContext context, ProductionBuilding b) {
    final d = b.def;
    final unlocked = state.isUnlocked(b.kind);
    final makes = b.recipes.map((r) => r.output.token).toSet().join(' ');
    return _ShopRow(
      icon: buildingIcon(b.kind),
      title: d.name,
      subtitle: 'Makes $makes',
      buttonLabel: b.owned ? 'Owned' : (unlocked ? '${d.price} $coinToken' : 'Lv ${d.unlockLevel}'),
      done: b.owned,
      locked: !unlocked,
      onPressed: b.owned || !unlocked ? null : () => showGameMessage(context, state.buyBuilding(b)),
    );
  }

  Widget _animal(BuildContext context, AnimalDef a) {
    final pen = state.pens[a.kind]!;
    final unlocked = state.isAnimalUnlocked(a.kind);
    final full = pen.animals.length >= a.maxCount;
    return _ShopRow(
      icon: a.kind == AnimalKind.chicken ? GameIconType.chicken : GameIconType.cow,
      title: a.name,
      subtitle:
          'Eats ${a.feed.token}, gives ${a.product.token}  '
          '(${pen.animals.length}/${a.maxCount})',
      buttonLabel: full ? 'Full' : (unlocked ? '${a.price} $coinToken' : 'Lv ${a.unlockLevel}'),
      done: full,
      locked: !unlocked,
      onPressed: full || !unlocked ? null : () => showGameMessage(context, state.buyAnimal(a.kind)),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
    child: Text(text, style: AppText.style(19, weight: 700, color: Palette.textSoft)),
  );
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.done,
    required this.onPressed,
    this.locked = false,
  });

  final GameIconType icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool done;
  final bool locked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: PaperCard(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Palette.cream,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.outline, width: 3),
              ),
              child: locked ? const GameIcon(GameIconType.lock) : GameIcon(icon, size: 46),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.style(19, weight: 700)),
                  IconText(
                    subtitle,
                    textAlign: TextAlign.start,
                    style: AppText.style(14, weight: 500, color: Palette.textSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 96,
              child: done
                  ? const Center(child: GameIcon(GameIconType.check, size: 32))
                  : ChunkyButton(
                      label: buttonLabel,
                      height: 44,
                      fontSize: 17,
                      onPressed: onPressed,
                    ),
            ),
          ],
        ),
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
          width: 72,
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? Palette.green : Palette.disabled,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Palette.outline, width: 3),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Palette.outline, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
