import 'package:flutter/material.dart';

import '../../art/icons.dart';

/// One icon flying across the screen (global coordinates).
class Flight {
  Flight(this.id, this.icon, this.from, this.to);
  final int id;
  final GameIconType icon;
  final Offset from;
  final Offset to;
}

/// Sends little icons flying to named targets (e.g. the coin counter).
/// Widgets register a target by putting [target] as their key.
class FxController extends ChangeNotifier {
  final Map<String, GlobalKey> _targets = {};
  final List<Flight> flights = [];
  int _nextId = 0;

  GlobalKey target(String name) => _targets.putIfAbsent(name, GlobalKey.new);

  Offset? _centerOf(String name) {
    final box = _targets[name]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// Flies [count] copies of [icon] from [from] (global) to target [to].
  void fly(GameIconType icon, Offset from, String to, {int count = 3}) {
    final end = _centerOf(to);
    if (end == null) return;
    for (var i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        flights.add(Flight(_nextId++, icon, from + Offset((i - (count - 1) / 2) * 12, 0), end));
        notifyListeners();
      });
    }
  }

  /// Flies icons from the widget with [context] to target [to].
  void flyFrom(BuildContext context, GameIconType icon, String to, {int count = 3}) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    fly(icon, box.localToGlobal(box.size.center(Offset.zero)), to, count: count);
  }

  void _done(Flight f) {
    flights.remove(f);
    notifyListeners();
  }
}

/// Draws all flights above everything else.
class FxLayer extends StatelessWidget {
  const FxLayer({super.key, required this.controller});

  final FxController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final box = context.findRenderObject() as RenderBox?;
          final origin = box != null && box.attached ? box.localToGlobal(Offset.zero) : Offset.zero;
          return Stack(
            children: [
              for (final f in controller.flights)
                _FlyingIcon(
                  key: ValueKey(f.id),
                  flight: f,
                  origin: origin,
                  onDone: () => controller._done(f),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FlyingIcon extends StatelessWidget {
  const _FlyingIcon({super.key, required this.flight, required this.origin, required this.onDone});

  final Flight flight;
  final Offset origin;
  final VoidCallback onDone;

  static const double _size = 34;

  @override
  Widget build(BuildContext context) {
    final a = flight.from - origin;
    final b = flight.to - origin;
    final control = Offset(a.dx + (b.dx - a.dx) * 0.15, a.dy - 120);
    return Positioned(
      left: 0,
      top: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
        onEnd: onDone,
        builder: (context, t, child) {
          final p = Offset(
            (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * control.dx + t * t * b.dx,
            (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * control.dy + t * t * b.dy,
          );
          final s = t < 0.15 ? 0.6 + t / 0.15 * 0.7 : 1.3 - (t - 0.15) * 0.6;
          return Transform.translate(
            offset: p - const Offset(_size / 2, _size / 2),
            child: Transform.scale(scale: s, child: child),
          );
        },
        child: GameIcon(flight.icon, size: _size),
      ),
    );
  }
}
