import 'package:flutter/material.dart';

import '../../art/palette.dart';

/// Soft cream "paper" card with rounded corners and a gentle shadow.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.paper, Color(0xFFFFF0D0)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.paperDark, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x2E5A3A22), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Wooden planks background (top bar, sign boards, nav bar).
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.radius = 0,
    this.planks = 2,
    this.padding = EdgeInsets.zero,
    this.nails = false,
  });

  final Widget child;
  final double radius;
  final int planks;
  final EdgeInsetsGeometry padding;
  final bool nails;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _WoodPainter(planks: planks, radius: radius, nails: nails),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _WoodPainter extends CustomPainter {
  _WoodPainter({required this.planks, required this.radius, required this.nails});

  final int planks;
  final double radius;
  final bool nails;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.woodLight, Palette.wood],
        ).createShader(rect),
    );
    final ph = size.height / planks;
    final seam = Paint()
      ..color = Palette.woodDark
      ..strokeWidth = 2.5;
    final highlight = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.5;
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < planks; i++) {
      final top = i * ph;
      if (i > 0) canvas.drawLine(Offset(0, top), Offset(size.width, top), seam);
      canvas.drawLine(Offset(0, top + 2), Offset(size.width, top + 2), highlight);
      // wavy wood grain
      for (var g = 0; g < 2; g++) {
        final y = top + ph * (0.35 + g * 0.3);
        final path = Path()..moveTo(0, y);
        for (var x = 0.0; x < size.width; x += 60) {
          path.quadraticBezierTo(x + 15, y - 2.5 + g * 5, x + 30, y);
          path.quadraticBezierTo(x + 45, y + 2.5 - g * 5, x + 60, y);
        }
        canvas.drawPath(path, grain);
      }
      // knots
      final kx = (size.width * (0.23 + 0.41 * i)) % size.width;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(kx, top + ph * 0.5), width: 10, height: 5), grain);
    }
    // inner border
    final border = Paint()
      ..color = Palette.woodDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1.5), Radius.circular(radius)),
      border,
    );
    if (nails) {
      final nail = Paint()..color = Palette.woodDeep;
      final shine = Paint()..color = const Color(0x66FFFFFF);
      for (final o in [
        const Offset(10, 10),
        Offset(size.width - 10, 10),
        Offset(10, size.height - 10),
        Offset(size.width - 10, size.height - 10),
      ]) {
        canvas.drawCircle(o, 3.2, nail);
        canvas.drawCircle(o - const Offset(1, 1), 1.1, shine);
      }
    }
  }

  @override
  bool shouldRepaint(_WoodPainter old) =>
      old.planks != planks || old.radius != radius || old.nails != nails;
}

/// Rounded picture frame for the building illustrations.
class SceneFrame extends StatelessWidget {
  const SceneFrame({super.key, required this.child, this.height = 210});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Palette.woodDark, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x335A3A22), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: child),
    );
  }
}
