import '../game_config.dart';
import 'defs.dart';

/// Looks up a recipe by id.
RecipeDef? recipeById(String id) {
  for (final r in GameConfig.recipes) {
    if (r.id == id) return r;
  }
  return null;
}

BuildingDef buildingDef(BuildingKind kind) =>
    GameConfig.buildings.firstWhere((b) => b.kind == kind);

/// One batch in a building: it is ready at [endMs].
class Job {
  Job(this.recipe, this.endMs);

  final RecipeDef recipe;
  int endMs;

  bool isReady(int nowMs) => endMs <= nowMs;

  int get startMs => endMs - recipe.time.inMilliseconds;

  double progress(int nowMs) => ((nowMs - startMs) / recipe.time.inMilliseconds).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {'r': recipe.id, 'end': endMs};
}

/// A building (mill, oven, ...) with a queue of jobs.
///
/// Jobs run one after another. Finished products wait in the building until
/// the player collects them (they need room in the barn).
class ProductionBuilding {
  ProductionBuilding(this.kind);

  final BuildingKind kind;
  bool owned = false;
  final List<Job> jobs = [];

  /// Extra queue slots bought with upgrades.
  int extraSlots = 0;

  BuildingDef get def => buildingDef(kind);
  String get name => def.name;

  int get slots => GameConfig.queueSlots + extraSlots;

  List<RecipeDef> get recipes => GameConfig.recipes.where((r) => r.building == kind).toList();

  bool get isFull => jobs.length >= slots;

  /// The job being worked on right now (not finished yet).
  Job? working(int nowMs) {
    for (final j in jobs) {
      if (!j.isReady(nowMs)) return j;
    }
    return null;
  }

  bool isWorking(int nowMs) => working(nowMs) != null;

  List<Job> ready(int nowMs) => jobs.where((j) => j.isReady(nowMs)).toList();

  int readyCount(int nowMs) => jobs.where((j) => j.isReady(nowMs)).length;

  /// When a newly added job would finish.
  int nextEnd(int nowMs, RecipeDef r) {
    final lastEnd = jobs.isEmpty ? nowMs : jobs.last.endMs;
    final start = lastEnd > nowMs ? lastEnd : nowMs;
    return start + r.time.inMilliseconds;
  }

  Map<String, dynamic> toJson() => {
    'owned': owned,
    'jobs': [for (final j in jobs) j.toJson()],
    'extraSlots': extraSlots,
  };

  /// Reads the save. Also understands the old mill/oven format
  /// ({"owned": true, "jobStartedAtMs": 123}).
  void loadFromJson(Map<String, dynamic>? json) {
    owned = json?['owned'] == true;
    jobs.clear();
    extraSlots = 0;
    final e = json?['extraSlots'];
    if (e is int && e >= 0) extraSlots = e;
    final list = json?['jobs'];
    if (list is List) {
      for (final j in list) {
        if (j is! Map) continue;
        final r = recipeById('${j['r']}');
        final end = j['end'];
        if (r != null && r.building == kind && end is int) jobs.add(Job(r, end));
      }
    }
    final oldStart = json?['jobStartedAtMs'];
    if (oldStart is int && recipes.isNotEmpty) {
      final r = recipes.first;
      jobs.add(Job(r, oldStart + r.time.inMilliseconds));
    }
    if (!owned) jobs.clear();
  }
}
