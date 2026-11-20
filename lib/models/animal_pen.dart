import '../game_config.dart';
import 'defs.dart';

AnimalDef animalDef(AnimalKind kind) => GameConfig.animals.firstWhere((a) => a.kind == kind);

/// One animal. Hungry when [fedAtMs] is null; after eating it makes its
/// product, which waits until the player collects it.
class Animal {
  Animal({this.fedAtMs});
  int? fedAtMs;

  bool get isHungry => fedAtMs == null;
}

/// A pen with animals of one kind (chickens or cows).
class AnimalPen {
  AnimalPen(this.kind);

  final AnimalKind kind;
  final List<Animal> animals = [];

  AnimalDef get def => animalDef(kind);

  bool isReady(Animal a, int nowMs) =>
      a.fedAtMs != null && nowMs - a.fedAtMs! >= def.time.inMilliseconds;

  bool isProducing(Animal a, int nowMs) => a.fedAtMs != null && !isReady(a, nowMs);

  double progress(Animal a, int nowMs) =>
      a.fedAtMs == null ? 0 : ((nowMs - a.fedAtMs!) / def.time.inMilliseconds).clamp(0.0, 1.0);

  int readyCount(int nowMs) => animals.where((a) => isReady(a, nowMs)).length;
  int hungryCount() => animals.where((a) => a.isHungry).length;

  List<int?> toJson() => [for (final a in animals) a.fedAtMs];

  void loadFromJson(Object? json) {
    animals.clear();
    if (json is! List) return;
    for (final v in json.take(def.maxCount)) {
      animals.add(Animal(fedAtMs: v is int ? v : null));
    }
  }
}
