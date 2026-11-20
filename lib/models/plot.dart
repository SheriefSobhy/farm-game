import '../game_config.dart';

/// One piece of farm land. Empty when [plantedAtMs] is null.
class Plot {
  Plot({this.plantedAtMs});

  /// Wall-clock time (ms since epoch) when wheat was planted.
  /// Using real time means crops keep growing while the app is closed.
  int? plantedAtMs;

  static final int _growMs = GameConfig.wheatGrowTime.inMilliseconds;

  bool get isEmpty => plantedAtMs == null;

  double progress(int nowMs) {
    if (plantedAtMs == null) return 0;
    return ((nowMs - plantedAtMs!) / _growMs).clamp(0.0, 1.0);
  }

  bool isReady(int nowMs) => !isEmpty && progress(nowMs) >= 1;

  int remainingMs(int nowMs) {
    if (plantedAtMs == null) return 0;
    return (plantedAtMs! + _growMs - nowMs).clamp(0, _growMs);
  }
}
