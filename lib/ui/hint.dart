import 'dart:math';

import '../art/icons.dart';
import '../game/farm_layout.dart';
import '../models/defs.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import 'panels/shop_panel.dart';
import 'widgets/icon_text.dart';

/// What the hint banner says, its icon, and where tapping it leads.
class Hint {
  const Hint(this.text, this.icon, {this.spot, this.opens});

  final String text;
  final GameIconType icon;

  /// A farm spot to open when the hint is tapped.
  final FarmSpot? spot;

  /// Or a named panel: "shop", "daily", "orders".
  final String? opens;
}

/// The tutorial step's instruction.
Hint tutorialHint(GameState s) {
  final wheat = s.count(Item.wheat);
  final need = GameState.tutorialWheatNeeded;
  return switch (s.tutorial) {
    TutorialStep.plant => const Hint('Tap the soil to plant wheat!', GameIconType.wheatSeeds),
    TutorialStep.harvest =>
      s.plots.any((p) => p.isReady(s.nowMs))
          ? const Hint('The wheat is ready. Tap it to harvest!', GameIconType.wheat)
          : (s.plots.every((p) => p.isEmpty)
                ? Hint(
                    'Plant again — you need $need {wheat} ($wheat/$need)',
                    GameIconType.wheatSeeds,
                  )
                : Hint('Wheat is growing... ($wheat/$need {wheat})', GameIconType.clock)),
    TutorialStep.buildMill => const Hint(
      'Tap the windmill and build it!',
      GameIconType.windmill,
      spot: FarmSpot.mill,
    ),
    TutorialStep.makeFlour =>
      s.mill.readyCount(s.nowMs) > 0
          ? const Hint(
              'Flour is ready! Tap the mill to collect it.',
              GameIconType.flour,
              spot: FarmSpot.mill,
            )
          : Hint(
              'Tap the mill and make 2 {flour} (${min(s.count(Item.flour), 2)}/2)',
              GameIconType.windmill,
              spot: FarmSpot.mill,
            ),
    TutorialStep.bakeBread =>
      s.oven.readyCount(s.nowMs) > 0
          ? const Hint(
              'Bread is ready! Tap the oven to collect it.',
              GameIconType.bread,
              spot: FarmSpot.oven,
            )
          : const Hint('Tap the oven and bake {bread}', GameIconType.oven, spot: FarmSpot.oven),
    TutorialStep.deliver => const Hint(
      'A customer wants bread! Tap the orders board.',
      GameIconType.scroll,
      spot: FarmSpot.orders,
    ),
    TutorialStep.done => const Hint('', GameIconType.check),
  };
}

/// After the tutorial: the single most useful next thing to do.
Hint nextGoalHint(GameState s) {
  final now = s.nowMs;

  // 1. things waiting to be collected
  for (final b in s.buildings.values) {
    final ready = b.ready(now);
    if (b.owned && ready.isNotEmpty) {
      final item = ready.first.recipe.output;
      return Hint(
        'Tap the ${b.name} to collect ${item.token}',
        itemIcon(item),
        spot: FarmSpot.forBuilding(b.kind),
      );
    }
  }
  for (final p in s.pens.values) {
    if (p.readyCount(now) > 0) {
      return Hint(
        'Collect ${p.def.product.token} from the ${p.def.penName}',
        itemIcon(p.def.product),
        spot: FarmSpot.forAnimal(p.kind),
      );
    }
  }
  // 2. orders that can be delivered
  if (s.fillableOrders > 0) {
    return const Hint('An order is ready to deliver!', GameIconType.scroll, spot: FarmSpot.orders);
  }
  // 3. daily reward / goals
  if (s.canClaimDaily) {
    return const Hint('Claim your daily reward!', GameIconType.gift, opens: 'daily');
  }
  if (s.claimableGoals > 0) {
    return const Hint('A daily goal is done — claim it!', GameIconType.trophy, opens: 'daily');
  }
  // 4. something new to build that the player can afford
  for (final b in s.buildings.values) {
    if (!b.owned && s.isUnlocked(b.kind) && s.coins >= b.def.price) {
      return Hint('Build the ${b.name}!', buildingIcon(b.kind), spot: FarmSpot.forBuilding(b.kind));
    }
  }
  for (final p in s.pens.values) {
    if (p.animals.isEmpty && s.isAnimalUnlocked(p.kind) && s.coins >= p.def.price) {
      return Hint(
        'Buy your first ${p.def.name.toLowerCase()}!',
        p.kind == AnimalKind.chicken ? GameIconType.chicken : GameIconType.cow,
        spot: FarmSpot.forAnimal(p.kind),
      );
    }
  }
  // 5. hungry animals
  for (final p in s.pens.values) {
    if (p.hungryCount() > 0 && s.count(p.def.feed) == 0) {
      return Hint(
        'Make ${p.def.feed.token} at the Feed Mill for your ${p.def.name.toLowerCase()}s',
        itemIcon(p.def.feed),
        spot: FarmSpot.feedMill,
      );
    }
  }
  // 6. work toward the first order
  for (final o in s.orders) {
    if (o.isWaiting(now)) continue;
    for (final e in o.items.entries) {
      final missing = e.value - s.count(e.key);
      if (missing > 0) {
        return Hint(
          'Make $missing more ${e.key.token} for ${customerNames[o.customer % customerNames.length]}',
          itemIcon(e.key),
          spot: FarmSpot.orders,
        );
      }
    }
  }
  // 7. the next level
  final next = s.level + 1;
  final unlocks = GameState.unlocksAt(next);
  return Hint(
    '${s.xpToNextLevel} {star} to level $next${unlocks.isEmpty ? '' : ' (${unlocks.first.name})'}',
    GameIconType.star,
    opens: 'orders',
  );
}
