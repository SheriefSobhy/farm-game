import 'package:flutter/material.dart';

import '../../art/palette.dart';
import '../../art/text_styles.dart';
import '../../services/sound_service.dart';
import '../game_scope.dart';
import 'icon_text.dart';

/// Big rounded 3D button that presses down and bounces back.
/// [label] may contain icon tokens like "{coin}".
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.green,
    this.darkColor = Palette.greenDark,
    this.height = 58,
    this.fontSize = 21,
    this.tapSound,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color darkColor;
  final double height;
  final double fontSize;

  /// Sound played on tap. Leave null when the action plays its own sound.
  final Sfx? tapSound;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  static const double _lip = 5;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : Palette.disabled;
    final lip = enabled ? widget.darkColor : Palette.disabledDark;
    final h = widget.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setDown(true) : null,
      onTapUp: enabled ? (_) => _setDown(false) : null,
      onTapCancel: () => _setDown(false),
      onTap: enabled
          ? () {
              if (widget.tapSound != null) {
                GameScope.of(context).sound.play(widget.tapSound!);
              }
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: Duration(milliseconds: _down ? 70 : 450),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: SizedBox(
          height: h + _lip,
          child: Stack(
            children: [
              Positioned.fill(
                top: _lip,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: lip,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Palette.outline, width: 3),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: _down ? _lip : 0,
                height: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Palette.outline, width: 3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // flat pixel highlight strip along the top
                      Positioned(
                        top: 2,
                        left: 4,
                        right: 4,
                        height: 4,
                        child: ColoredBox(
                          color: Colors.white.withValues(
                            alpha: enabled ? 0.3 : 0.15,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: IconText(
                          widget.label,
                          style: AppText.light(widget.fontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
