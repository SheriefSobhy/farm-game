import 'dart:math';

import 'package:flutter/material.dart';

import '../../art/palette.dart';

/// Gently pulses [child] with a glowing outline when [enabled], to show the
/// player what to press next (used by the tutorial).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat();
  }

  @override
  void didUpdateWidget(Pulse old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_c.isAnimating) _c.repeat();
    if (!widget.enabled && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = sin(_c.value * pi);
        return Transform.scale(
          scale: 1 + 0.05 * v,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Palette.gold.withValues(alpha: 0.4 + 0.5 * v),
                  blurRadius: 4 + 8 * v,
                  spreadRadius: 1 + 3 * v,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
