import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import '../widgets/surfaces.dart';

/// Slides a panel up from the bottom over the farm, with a wooden title
/// plaque and a close button. The farm stays visible behind it.
Future<void> openSheet(
  BuildContext context, {
  required String title,
  required GameIconType icon,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x553F2631),
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (sheetContext) =>
        _Sheet(title: title, icon: icon, builder: builder),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final GameIconType icon;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        decoration: const BoxDecoration(
          color: Palette.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: Palette.outline, width: 3),
            left: BorderSide(color: Palette.outline, width: 3),
            right: BorderSide(color: Palette.outline, width: 3),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 34),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      4,
                      14,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: builder(context),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(
                child: WoodPanel(
                  radius: 10,
                  planks: 1,
                  padding: const EdgeInsets.fromLTRB(8, 4, 18, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameIcon(icon, size: 34),
                      const SizedBox(width: 6),
                      Text(title, style: AppText.light(24, weight: 700)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  GameScope.of(context).sound.play(Sfx.tap);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Palette.red,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Palette.outline, width: 3),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const _CloseX(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseX extends StatelessWidget {
  const _CloseX();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _XPainter());
}

class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      const Offset(5, 5),
      Offset(size.width - 5, size.height - 5),
      p,
    );
    canvas.drawLine(Offset(size.width - 5, 5), Offset(5, size.height - 5), p);
  }

  @override
  bool shouldRepaint(_XPainter oldDelegate) => false;
}
