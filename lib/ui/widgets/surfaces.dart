import 'package:flutter/material.dart';

import '../../art/palette.dart';

/// Hard pixel-style drop shadow used by cards and panels.
const List<BoxShadow> hardShadow = [BoxShadow(color: Color(0x553F2631), offset: Offset(0, 4))];

/// Cream "paper" card with a dark outline, matching the pixel art.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color = Palette.paper,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.outline, width: 3),
        boxShadow: hardShadow,
      ),
      child: child,
    );
  }
}

/// Flat wooden planks (top bar, sign boards, bottom bar).
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.radius = 0,
    this.planks = 2,
    this.padding = EdgeInsets.zero,
    this.nails = false,
    this.border = true,
  });

  final Widget child;
  final double radius;
  final int planks;
  final EdgeInsetsGeometry padding;
  final bool nails;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WoodPainter(planks: planks, radius: radius, nails: nails, border: border),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _WoodPainter extends CustomPainter {
  _WoodPainter({
    required this.planks,
    required this.radius,
    required this.nails,
    required this.border,
  });

  final int planks;
  final double radius;
  final bool nails;
  final bool border;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = Palette.wood);
    final ph = size.height / planks;
    for (var i = 0; i < planks; i++) {
      final top = i * ph;
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, 3), Paint()..color = Palette.woodLight);
      canvas.drawRect(
        Rect.fromLTWH(0, top + ph - 3, size.width, 3),
        Paint()..color = Palette.woodDark,
      );
      // little knots and grain dashes, pixel style
      for (var x = 18.0 + i * 37; x < size.width - 10; x += 74) {
        canvas.drawRect(
          Rect.fromLTWH(x, top + ph * 0.45, 14, 3),
          Paint()..color = Palette.woodDark,
        );
      }
    }
    if (nails) {
      final nail = Paint()..color = Palette.outline;
      for (final o in [
        const Offset(10, 10),
        Offset(size.width - 14, 10),
        Offset(10, size.height - 14),
        Offset(size.width - 14, size.height - 14),
      ]) {
        canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 4, 4), nail);
      }
    }
    canvas.restore();
    if (border) {
      canvas.drawRRect(
        rrect.deflate(1.5),
        Paint()
          ..color = Palette.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_WoodPainter old) =>
      old.planks != planks || old.radius != radius || old.nails != nails || old.border != border;
}

/// Framed picture area for building illustrations in panels.
class SceneFrame extends StatelessWidget {
  const SceneFrame({super.key, required this.child, this.height = 180});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Palette.grass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.outline, width: 3),
        boxShadow: hardShadow,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(9), child: child),
    );
  }
}

/// A small dark pill with a number, e.g. "x12".
class CountPill extends StatelessWidget {
  const CountPill(this.text, {super.key, this.color = Palette.woodDeep});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.outline, width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontVariations: [FontVariation('wght', 700)],
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
