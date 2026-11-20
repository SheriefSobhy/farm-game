import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The game's sound effects (files live in assets/audio/).
enum Sfx { plant, harvest, coin, done, tap, error }

/// Plays short sound effects and remembers the on/off setting.
///
/// Browsers block audio until the player has touched the page, so nothing
/// is played until [unlock] has been called from the first tap.
class SoundService extends ChangeNotifier {
  static const String _prefsKey = 'farm_game_sound_enabled';

  bool _enabled = true;
  bool _unlocked = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsKey) ?? true;
    } catch (e) {
      debugPrint('Could not read sound setting: $e');
    }
    if (!kIsWeb) {
      // Let the player's own music keep playing alongside the game sounds.
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
        );
      } catch (e) {
        debugPrint('Could not set audio context: $e');
      }
    }
    // Preload in the background so the first sound has no delay.
    FlameAudio.audioCache
        .loadAll([for (final s in Sfx.values) _file(s)])
        .catchError((Object e) {
      debugPrint('Could not preload sounds: $e');
      return <Uri>[];
    });
  }

  /// Call on the first user tap. Safe to call many times.
  void unlock() => _unlocked = true;

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (e) {
      debugPrint('Could not save sound setting: $e');
    }
  }

  void play(Sfx sfx) {
    if (!_enabled || !_unlocked) return;
    FlameAudio.play(_file(sfx), volume: _volume(sfx)).then<void>(
      (_) {},
      onError: (Object e) => debugPrint('Could not play ${sfx.name}: $e'),
    );
  }

  static String _file(Sfx s) => '${s.name}.wav';

  static double _volume(Sfx s) => switch (s) {
        Sfx.tap => 0.5,
        Sfx.error => 0.6,
        _ => 0.8,
      };
}
