import '../game_config.dart';
import 'defs.dart';
import 'item.dart';

/// Looks up the crop that produces [item].
CropDef cropFor(Item item) => GameConfig.crops.firstWhere((c) => c.item == item);

/// One piece of farm land. Empty when [plantedAtMs] is null.
class Plot {
  Plot({this.plantedAtMs, this.crop = Item.wheat});

  /// Wall-clock time (ms since epoch) when the crop was planted.
  /// Using real time means crops keep growing while the app is closed.
  int? plantedAtMs;

  /// Which crop is growing (wheat or corn).
  Item crop;

  int get _growMs => cropFor(crop).growTime.inMilliseconds;

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

  /// Saved as {"c": "wheat", "t": 123} or null when empty.
  Object? toJson() => plantedAtMs == null ? null : {'c': crop.name, 't': plantedAtMs};

  /// Reads both the new format and the old one (just a timestamp = wheat).
  static Plot fromJson(Object? json) {
    if (json is int) return Plot(plantedAtMs: json);
    if (json is Map) {
      final t = json['t'];
      final c = Item.values.asNameMap()[json['c']];
      final isCrop = c != null && GameConfig.crops.any((d) => d.item == c);
      return Plot(plantedAtMs: t is int ? t : null, crop: isCrop ? c : Item.wheat);
    }
    return Plot();
  }
}
