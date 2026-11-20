# Credits

## Graphics
All graphics (plots, wheat, windmill, oven, market stall, farmhouse, trees,
icons for coins/wheat/flour/bread, buttons, wood and paper panels) are drawn
in code with Flutter/Flame canvas calls — see `lib/art/`.
Created for this project and released under **CC0 1.0** (public domain).
No external image files are used, so `assets/images/` is not needed.

(Kenney.nl's CC0 packs were the first choice, but their site blocks automated
downloads, so everything was drawn in code instead.)

## Sound effects — `assets/audio/*.wav`
`plant`, `harvest`, `coin`, `done`, `tap`, `error` were synthesized from
scratch (sine waves, noise and envelopes) by `tool/generate_sounds.dart`.
Created for this project and released under **CC0 1.0** (public domain).
Regenerate them with: `dart run tool/generate_sounds.dart`

## Font — `assets/fonts/Fredoka.ttf`
**Fredoka** by The Fredoka Project Authors (Milena Brandão, Hafontia),
from Google Fonts: https://github.com/google/fonts/tree/main/ofl/fredoka
Licensed under the **SIL Open Font License 1.1** — see `assets/fonts/OFL.txt`.

## Libraries
- [Flutter](https://flutter.dev) — BSD 3-Clause
- [Flame](https://flame-engine.org) and flame_audio — MIT
- [audioplayers](https://pub.dev/packages/audioplayers) — MIT
- [shared_preferences](https://pub.dev/packages/shared_preferences) — BSD 3-Clause
