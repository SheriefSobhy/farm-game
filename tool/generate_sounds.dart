// Generates the game's sound effects as small WAV files.
//
// Run from the project folder:   dart run tool/generate_sounds.dart
//
// The sounds are synthesized from scratch (sine waves, noise and envelopes),
// so they are original works released as CC0 along with this project.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;
final Random _rng = Random(7);

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);
  final sounds = <String, List<double>>{
    'plant.wav': plant(),
    'harvest.wav': harvest(),
    'coin.wav': coin(),
    'done.wav': done(),
    'tap.wav': tap(),
    'error.wav': error(),
  };
  sounds.forEach((name, samples) {
    final file = File('${dir.path}/$name');
    file.writeAsBytesSync(toWav(samples));
    stdout.writeln('wrote ${file.path} (${file.lengthSync()} bytes)');
  });
}

// ------------------------------------------------------------------ sounds

/// Soft rising "pop" for planting a seed.
List<double> plant() => render(0.16, (t, d) {
  final f = 260 + 520 * (t / d);
  return sin(2 * pi * f * t) * env(t, d, attack: 0.005, curve: 3) * 0.7;
});

/// Rustle of leaves plus a bright two-note chime.
List<double> harvest() => render(0.32, (t, d) {
  final rustle = noise() * env(t, 0.12, attack: 0.002, curve: 2) * 0.25;
  final n1 = tone(660, t) * env(t, 0.14, attack: 0.003, curve: 3);
  final n2 = t > 0.08 ? tone(990, t - 0.08) * env(t - 0.08, 0.24, attack: 0.003, curve: 3) : 0.0;
  return rustle + (n1 + n2) * 0.45;
});

/// Classic shiny two-note coin.
List<double> coin() => render(0.38, (t, d) {
  final first = t < 0.07;
  final f = first ? 988.0 : 1319.0;
  final local = first ? t : t - 0.07;
  final e = first
      ? env(local, 0.07, attack: 0.002, curve: 0.5)
      : env(local, d - 0.07, attack: 0.002, curve: 3);
  final s = sin(2 * pi * f * local) + 0.3 * sin(2 * pi * f * 2 * local);
  return s * e * 0.4;
});

/// Friendly bell arpeggio (C-E-G) when the mill or oven finishes.
List<double> done() => render(0.75, (t, d) {
  const notes = [523.25, 659.25, 783.99];
  var v = 0.0;
  for (var i = 0; i < notes.length; i++) {
    final start = i * 0.11;
    if (t < start) continue;
    final lt = t - start;
    v +=
        (sin(2 * pi * notes[i] * lt) + 0.4 * sin(2 * pi * notes[i] * 3 * lt) * exp(-lt * 12)) *
        env(lt, d - start, attack: 0.004, curve: 4);
  }
  return v * 0.3;
});

/// Very short wooden "tock" for button taps.
List<double> tap() => render(0.06, (t, d) {
  final f = 900 - 400 * (t / d);
  return (sin(2 * pi * f * t) * 0.8 + noise() * 0.15) * env(t, d, attack: 0.001, curve: 4) * 0.55;
});

/// Gentle low "nuh-uh" for errors (not harsh).
List<double> error() => render(0.34, (t, d) {
  final first = t < 0.15;
  final f = first ? 233.0 : 175.0;
  final lt = first ? t : t - 0.15;
  final e = env(lt, first ? 0.15 : 0.19, attack: 0.005, curve: 1.5);
  return triangle(f, lt) * e * 0.5;
});

// --------------------------------------------------------------- helpers

double tone(double f, double t) => sin(2 * pi * f * t) + 0.25 * sin(2 * pi * f * 2 * t);

double triangle(double f, double t) {
  final p = (t * f) % 1.0;
  return 4 * (p < 0.5 ? p : 1 - p) - 1;
}

double noise() => _rng.nextDouble() * 2 - 1;

/// Quick attack, then a decay shaped by [curve] (higher = faster fade).
double env(double t, double d, {required double attack, required double curve}) {
  if (t < 0 || t > d) return 0;
  if (t < attack) return t / attack;
  final x = (t - attack) / (d - attack);
  return pow(1 - x, curve).toDouble();
}

List<double> render(double seconds, double Function(double t, double d) fn) {
  final n = (seconds * sampleRate).round();
  return List.generate(n, (i) => fn(i / sampleRate, seconds));
}

Uint8List toWav(List<double> samples) {
  final dataLen = samples.length * 2;
  final b = ByteData(44 + dataLen);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, dataLen, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    b.setInt16(44 + i * 2, v, Endian.little);
  }
  return b.buffer.asUint8List();
}
