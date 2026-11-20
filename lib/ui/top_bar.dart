import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/palette.dart';
import '../art/text_styles.dart';
import '../models/game_state.dart';
import '../models/item.dart';
import 'widgets/animated_count.dart';
import 'widgets/icon_text.dart';
import 'widgets/surfaces.dart';

/// Wooden bar that always shows coins, wheat, flour and bread.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.state, required this.coinKey, required this.itemKeys});

  final GameState state;

  /// Keys on the icons, so flying icons know where to go.
  final GlobalKey coinKey;
  final Map<Item, GlobalKey> itemKeys;

  @override
  Widget build(BuildContext context) {
    return WoodPanel(
      planks: 2,
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 11),
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => Row(
          children: [
            _Stat(icon: GameIconType.coin, value: state.coins, iconKey: coinKey),
            for (final item in Item.values)
              _Stat(icon: itemIcon(item), value: state.count(item), iconKey: itemKeys[item]!),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatefulWidget {
  const _Stat({required this.icon, required this.value, required this.iconKey});

  final GameIconType icon;
  final int value;
  final GlobalKey iconKey;

  @override
  State<_Stat> createState() => _StatState();
}

class _StatState extends State<_Stat> with SingleTickerProviderStateMixin {
  late final AnimationController _bump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(_Stat old) {
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
      child: AnimatedBuilder(
        animation: _bump,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.14 * sin(_bump.value * pi),
          child: child,
        ),
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.only(left: 3, right: 8),
          decoration: BoxDecoration(
            color: const Color(0x8A4A2812),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.woodDeep, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33FFFFFF), offset: Offset(0, 1.5)),
            ],
          ),
          child: Row(
            children: [
              GameIcon(widget.icon, key: widget.iconKey, size: 32),
              const SizedBox(width: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AnimatedCount(value: widget.value, style: AppText.light(19, weight: 650)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
