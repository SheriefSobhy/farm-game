import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game_config.dart';

/// Where everything sits on the farm screen, computed from the game size.
/// Shared by the background and the plots so they always line up.
class FarmLayout {
  FarmLayout(Vector2 size)
      : width = size.x,
        height = size.y {
    topSpace = (height * 0.24).clamp(96.0, 180.0);
    const pad = 16.0;
    gap = (width * 0.03).clamp(8.0, 14.0);
    const cols = GameConfig.gridColumns;
    final rows = (GameConfig.maxPlots / cols).ceil();
    cell = max(
      24.0,
      min(
        (width - pad * 2 - gap * (cols - 1)) / cols,
        (height - topSpace - pad - gap * (rows - 1)) / rows,
      ),
    );
    final gridW = cell * cols + gap * (cols - 1);
    final gridH = cell * rows + gap * (rows - 1);
    final left = (width - gridW) / 2;
    final top = topSpace + max(0.0, (height - topSpace - pad - gridH) / 2);
    grid = Rect.fromLTWH(left, top, gridW, gridH);
  }

  final double width;
  final double height;
  late final double topSpace;
  late final double gap;
  late final double cell;
  late final Rect grid;

  /// Center point of plot number [index].
  Vector2 cellCenter(int index) {
    const cols = GameConfig.gridColumns;
    final col = index % cols;
    final row = index ~/ cols;
    return Vector2(
      grid.left + col * (cell + gap) + cell / 2,
      grid.top + row * (cell + gap) + cell / 2,
    );
  }
}
