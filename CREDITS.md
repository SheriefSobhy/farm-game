# Credits

Every asset in this game is either public domain (CC0) or under a license
that allows commercial use.

## Graphics — `assets/images/`

| File | What | Author / source | License |
|---|---|---|---|
| `kenney_tiny_farm.png` | Soil, crops (3 growth stages), animals, barn, troughs, trees, products | **Tiny Farm** by Kenney — https://opengameart.org/content/tiny-farm (also https://kenney.nl) | **CC0 1.0** (see `KENNEY_TINY_FARM_LICENSE.txt`) |
| `kenney_tiny_town.png` | Grass, flowers, trees, fences, dirt path, coin, beehive, sign, bag | **Tiny Town** by Kenney — https://opengameart.org/content/tiny-town (also https://kenney.nl) | **CC0 1.0** (see `KENNEY_TINY_TOWN_LICENSE.txt`) |
| `extra.png` | Windmill, bakery oven, popcorn machine, feed mill, dairy, market stall, orders board, coop, cow shed, bread, popcorn, cheese, cake, cow feed, gem, star, and UI icons | Made for this project in the Kenney "Tiny" style and palette by `tool/make_sprites.dart` | **CC0 1.0** |

Each Kenney license file was checked: "This content is free to use in
personal, educational and commercial projects." Crediting Kenney is optional,
but we do it anyway — thank you, Kenney!

The packs did not include a windmill, oven, bread, gems and a few other things,
so those were drawn as new pixel art in the same 16×16 style and color palette
so everything looks like one set. Rebuild them with:
`dart run tool/make_sprites.dart`

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
