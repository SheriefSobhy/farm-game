import 'package:flutter/material.dart';

import '../art/icons.dart';
import '../art/text_styles.dart';
import '../services/sound_service.dart';
import 'game_scope.dart';
import 'widgets/surfaces.dart';

/// One big button in the bottom bar.
class BarButton {
  const BarButton(this.icon, this.label, this.onTap, {this.targetName, this.badge = 0});
  final GameIconType icon;
  final String label;
  final VoidCallback onTap;

  /// Name of a fly-to target (e.g. "barn") placed on this button's icon.
  final String? targetName;

  /// A red badge with this number when > 0.
  final int badge;
}

/// Smooth wooden tray with glossy rounded buttons along the bottom.
class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.buttons});

  final List<BarButton> buttons;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDB877), Color(0xFFC98743), Color(0xFFB0702F)],
          stops: [0, 0.55, 1],
        ),
        border: Border(top: BorderSide(color: Color(0xFF8A5424), width: 2)),
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
          child: Row(
            children: [for (final b in buttons) Expanded(child: _Button(button: b))],
          ),
        ),
      ),
    );
  }
}

class _Button extends StatefulWidget {
  const _Button({required this.button});

  final BarButton button;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.button;
    final scope = GameScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        scope.sound.play(Sfx.tap);
        b.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: Duration(milliseconds: _down ? 70 : 500),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlossyBox(
              height: 66,
              radius: 18,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameIcon(
                    b.icon,
                    size: 38,
                    key: b.targetName == null ? null : scope.fx.target(b.targetName!),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      b.label,
                      style: AppText.style(13.5, weight: 700, color: const Color(0xFF5A3418)),
                    ),
                  ),
                ],
              ),
            ),
            if (b.badge > 0) Positioned(right: -2, top: -6, child: RedBadge(count: b.badge)),
          ],
        ),
      ),
    );
  }
}

/// A glossy red circle with a white number, for "something is ready".
class RedBadge extends StatelessWidget {
  const RedBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7262), Color(0xFFD8251B)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: softShadow,
      ),
      child: Text(count > 9 ? '9+' : '$count', style: AppText.light(13, weight: 700)),
    );
  }
}
