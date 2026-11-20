// Draws the extra pixel-art sprites that the Kenney "Tiny" packs don't have
// (windmill, bakery oven, popcorn machine, bread, cheese, gems, UI icons...)
// in the same 16px style and color palette, and packs them into one atlas.
//
// Run from the project root:  dart run tool/make_sprites.dart
//
// Writes:
//   assets/images/extra.png      the sprite atlas
//   lib/art/extra_atlas.dart     where each sprite is inside the atlas
//
// Everything this script draws is original work released as CC0.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// Kenney "Tiny" palette.
const Map<String, int> pal = {
  '.': 0x00000000,
  'o': 0xFF3F2631, // outline
  'w': 0xFFFFFFFF,
  'W': 0xFFEBEFF8,
  'y': 0xFFFDBE53,
  'Y': 0xFFE38628,
  'l': 0xFFF7C282,
  's': 0xFFEAA56C,
  'S': 0xFFFEC99C,
  'L': 0xFFFDD6B4,
  'b': 0xFFBD6C4A,
  'B': 0xFFCF8254,
  'D': 0xFF763B36,
  'r': 0xFFC34B35,
  'R': 0xFFAA2C23,
  'p': 0xFFE84537,
  'P': 0xFFF28462,
  'g': 0xFF84C669,
  'G': 0xFF4E974C,
  'h': 0xFFC6E58D,
  'H': 0xFF65A556,
  'c': 0xFFC0CBDC,
  'C': 0xFF8B9BB4,
  'k': 0xFF5A6988,
  'n': 0xFF262B44,
  'u': 0xFF99D8F8,
  'U': 0xFF79A7E8,
  'e': 0xFF009ADC,
  'm': 0xFFD176D0,
  'M': 0xFF9B4CA3,
};

class Px {
  Px(this.w, this.h) : p = Uint32List(w * h);
  final int w, h;
  final Uint32List p;

  int get(int x, int y) =>
      (x < 0 || y < 0 || x >= w || y >= h) ? 0 : p[y * w + x];
  void set(int x, int y, String c) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    p[y * w + x] = pal[c]!;
  }

  void rect(int x, int y, int rw, int rh, String c) {
    for (var j = y; j < y + rh; j++) {
      for (var i = x; i < x + rw; i++) {
        set(i, j, c);
      }
    }
  }

  void ellipse(
    double cx,
    double cy,
    double rx,
    double ry,
    String c, {
    bool topHalf = false,
  }) {
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        final dx = (i + 0.5 - cx) / rx;
        final dy = (j + 0.5 - cy) / ry;
        if (dx * dx + dy * dy <= 1 && (!topHalf || j + 0.5 <= cy)) set(i, j, c);
      }
    }
  }

  void ascii(int x, int y, List<String> rows, {String name = ''}) {
    for (var j = 0; j < rows.length; j++) {
      for (var i = 0; i < rows[j].length; i++) {
        final ch = rows[j][i];
        if (ch == '.') continue;
        if (!pal.containsKey(ch)) throw 'bad char "$ch" in $name';
        set(x + i, y + j, ch);
      }
    }
  }

  /// Kenney-style 1px dark outline around everything that is drawn.
  void outline() {
    final out = <int>[];
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        if (get(i, j) != 0) continue;
        if (get(i - 1, j) != 0 ||
            get(i + 1, j) != 0 ||
            get(i, j - 1) != 0 ||
            get(i, j + 1) != 0) {
          out.add(j * w + i);
        }
      }
    }
    for (final k in out) {
      p[k] = pal['o']!;
    }
  }

  Px rotated90() {
    final r = Px(h, w);
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        r.p[i * r.w + (h - 1 - j)] = p[j * w + i];
      }
    }
    return r;
  }

  void blit(Px src, int x, int y) {
    for (var j = 0; j < src.h; j++) {
      for (var i = 0; i < src.w; i++) {
        final v = src.p[j * src.w + i];
        if (v != 0 && x + i >= 0 && y + j >= 0 && x + i < w && y + j < h) {
          p[(y + j) * w + x + i] = v;
        }
      }
    }
  }
}

/// A 16x16 icon from ASCII art; the outline is added automatically.
Px icon(String name, List<String> rows) {
  if (rows.length != 16) throw '$name: needs 16 rows, has ${rows.length}';
  for (var j = 0; j < 16; j++) {
    if (rows[j].length != 16) throw '$name row $j: length ${rows[j].length}';
  }
  final px = Px(16, 16)..ascii(0, 0, rows, name: name);
  return px..outline();
}

final Map<String, Px> sprites = {};

void main() {
  _icons();
  _buildings();
  _pack();
}

void _icons() {
  sprites['bread'] = icon('bread', [
    '................',
    '................',
    '................',
    '................',
    '.....BBBBBB.....',
    '...BBBBBBBBBB...',
    '..BBSBBBSBBBSB..',
    '..BSBBBSBBBSBB..',
    '.BBBBBBBBBBBBBB.',
    '.bBBBBBBBBBBBBb.',
    '.bbBBBBBBBBBBbb.',
    '..bbbbbbbbbbbb..',
    '...bbbbbbbbbb...',
    '................',
    '................',
    '................',
  ]);
  sprites['popcorn'] = icon('popcorn', [
    '................',
    '.....wL...L.....',
    '...LwwLw.wwL....',
    '..LwwyLwwLwyL...',
    '..wLwwLwyLwwLw..',
    '..LwwLwwLwwLwL..',
    '..rrwwrrwwrrww..',
    '..rrwwrrwwrrww..',
    '...rwwrrwwrrw...',
    '...rwwrrwwrrw...',
    '...rwwrrwwrrw...',
    '....wrrwwrrw....',
    '....wrrwwrrw....',
    '....RRRRRRRR....',
    '................',
    '................',
  ]);
  sprites['cheese'] = icon('cheese', [
    '................',
    '................',
    '................',
    '..........ll....',
    '........llllll..',
    '......llllllll..',
    '....llllllllll..',
    '..llllllllllll..',
    '..yyYyyyyyyyyy..',
    '..yYYYyyyyYyyy..',
    '..yyYyyyyYYYyy..',
    '..yyyyyyyyYyyy..',
    '..yyyyYyyyyyyy..',
    '..YYYYYYYYYYYY..',
    '................',
    '................',
  ]);
  sprites['cake'] = icon('cake', [
    '................',
    '.......pp.......',
    '.......pR.......',
    '...wwwwwwwwww...',
    '..wwwwwwwwwwww..',
    '..wPwwwPwwwPww..',
    '..PPPPPPPPPPPP..',
    '..SSSSSSSSSSSS..',
    '..PPPPPPPPPPPP..',
    '..PPPPPPPPPPPP..',
    '..SSSSSSSSSSSS..',
    '..PPPPPPPPPPPP..',
    '.cccccccccccccc.',
    '..CCCCCCCCCCCC..',
    '................',
    '................',
  ]);
  sprites['cowFeed'] = icon('cowFeed', [
    '................',
    '................',
    '......gGgh......',
    '.....hGgGhg.....',
    '......SSSS......',
    '.....LSSSSL.....',
    '....SSSSSSSS....',
    '...SSSSSSSSSS...',
    '...SSShhgSSSS...',
    '...SShgGghSSS...',
    '...SSSgGgSSSS...',
    '...SSSShSSSSS...',
    '...sSSSSSSSSs...',
    '....ssssssss....',
    '................',
    '................',
  ]);
  sprites['gem'] = icon('gem', [
    '................',
    '................',
    '................',
    '....UUUUUUUU....',
    '...UuuWUUuuuU...',
    '..UuuWWUUuuuuU..',
    '..eeeeeeeeeeee..',
    '...eUuuuuuuUe...',
    '....eUuWuuUe....',
    '.....eUuuUe.....',
    '......eUUe......',
    '.......ee.......',
    '................',
    '................',
    '................',
    '................',
  ]);
  sprites['star'] = icon('star', [
    '................',
    '.......yy.......',
    '......yyyy......',
    '......ylyy......',
    '.yyyyyllyyyyyyy.',
    '..yyyyllyyyyyy..',
    '...yyylyyyyyy...',
    '....yyyyyyyy....',
    '....yyyyyyyy....',
    '...yyyyyyyyyy...',
    '...yyyyYYyyyy...',
    '..yyyyY..Yyyyy..',
    '..yyyY....Yyyy..',
    '..YYY......YYY..',
    '................',
    '................',
  ]);
  sprites['lock'] = icon('lock', [
    '................',
    '................',
    '......cccc......',
    '.....cCCCCc.....',
    '....cC....Cc....',
    '....cC....Cc....',
    '....cC....Cc....',
    '...yyyyyyyyyy...',
    '...ylyyyyyyyy...',
    '...ylyyyDDyyy...',
    '...ylyyyDDyyy...',
    '...yyyyyyDyyy...',
    '...yyyyyyDyyy...',
    '...YYYYYYYYYY...',
    '................',
    '................',
  ]);
  sprites['check'] = icon('check', [
    '................',
    '................',
    '...........hg...',
    '..........hgg...',
    '.........hggG...',
    '........hggG....',
    '..hg...hggG.....',
    '..ggg.hggG......',
    '..GggggggG......',
    '...GggggG.......',
    '....GggG........',
    '.....GG.........',
    '................',
    '................',
    '................',
    '................',
  ]);
  sprites['plus'] = icon('plus', [
    '................',
    '................',
    '......hhhh......',
    '......hggg......',
    '......hggg......',
    '......hggg......',
    '..hhhhhgggggggg.',
    '..hgggggggggggG.',
    '..hgggggggggggG.',
    '..GGGGGgggGGGGG.',
    '......hggG......',
    '......hggG......',
    '......hggG......',
    '......GGGG......',
    '................',
    '................',
  ]);
  sprites['cross'] = icon('cross', [
    '................',
    '................',
    '..PP........PP..',
    '..PppR....PppR..',
    '...PppR..PppR...',
    '....PppRPppR....',
    '.....PpppppR....',
    '......ppppR.....',
    '......PpppR.....',
    '.....PppRppR....',
    '....PppR.PppR...',
    '...PppR...PppR..',
    '..PppR.....PppR.',
    '...RR.......RR..',
    '................',
    '................',
  ]);
  sprites['arrowDown'] = icon('arrowDown', [
    '................',
    '.....yyyyyy.....',
    '.....ylyyyY.....',
    '.....ylyyyY.....',
    '.....ylyyyY.....',
    '.....ylyyyY.....',
    '.....ylyyyY.....',
    '..yyyylyyyYyyy..',
    '...yyylyyyyyy...',
    '....yylyyyyy....',
    '.....ylyyyy.....',
    '......yyyy......',
    '.......YY.......',
    '................',
    '................',
    '................',
  ]);
  sprites['soundOn'] = icon('soundOn', [
    '................',
    '................',
    '.......C......w.',
    '......CC...w..w.',
    '.....CcC....w.w.',
    '..CCCccC..w.w.w.',
    '..cccccC..w.w.w.',
    '..cccccC..w.w.w.',
    '..CCCccC..w.w.w.',
    '.....CcC....w.w.',
    '......CC...w..w.',
    '.......C......w.',
    '................',
    '................',
    '................',
    '................',
  ]);
  sprites['soundOff'] = icon('soundOff', [
    '................',
    '................',
    '.......C........',
    '......CC........',
    '.....CcC........',
    '..CCCccC.pp..pp.',
    '..cccccC..pppp..',
    '..cccccC...pp...',
    '..CCCccC..pppp..',
    '.....CcC.pp..pp.',
    '......CC........',
    '.......C........',
    '................',
    '................',
    '................',
    '................',
  ]);
  sprites['scroll'] = icon('scroll', [
    '................',
    '................',
    '...SSSSSSSSSS...',
    '..sLLLLLLLLLLs..',
    '...LLLLLLLLLL...',
    '...LssssssLLL...',
    '...LLLLLLLLLL...',
    '...LsssssssLL...',
    '...LLLLLLLLLL...',
    '...LssssLLLLL...',
    '...LLLLLLLLLL...',
    '...LLLLLLLLrL...',
    '..sLLLLLLLLLLs..',
    '...SSSSSSSSSS...',
    '................',
    '................',
  ]);
  sprites['gift'] = icon('gift', [
    '................',
    '................',
    '....yy....yy....',
    '...y..y..y..y...',
    '....yy.yy.yy....',
    '..rrrrryyrrrrr..',
    '..pppppyypppppp.',
    '..rrrrryyrrrrr..',
    '...rrrryyrrrr...',
    '...prrryyrrrr...',
    '...prrryyrrrr...',
    '...prrryyrrrr...',
    '...prrryyrrrr...',
    '...RRRRYYRRRR...',
    '................',
    '................',
  ]);
  sprites['trophy'] = icon('trophy', [
    '................',
    '................',
    '..yyyyyyyyyyyy..',
    '.y.yllyyyyyyy.y.',
    '.y.yllyyyyyyy.y.',
    '.y.ylyyyyyyyy.y.',
    '..yylyyyyyyyyy..',
    '....yyyyyyyy....',
    '.....yyyyyY.....',
    '.......yY.......',
    '.......yY.......',
    '.....bBBBBb.....',
    '....bBBBBBBb....',
    '....DDDDDDDD....',
    '................',
    '................',
  ]);
  sprites['bolt'] = icon('bolt', [
    '................',
    '........yyyy....',
    '.......ylyyY....',
    '......ylyyY.....',
    '.....ylyyY......',
    '....ylyyyyyyy...',
    '...yyyyyyyyyY...',
    '.......yyyyY....',
    '......yyyyY.....',
    '.....yyyyY......',
    '....yyyyY.......',
    '...yyyY.........',
    '...yYY..........',
    '................',
    '................',
    '................',
  ]);
  sprites['barnIcon'] = icon('barnIcon', [
    '................',
    '.......rr.......',
    '.....rrrrrr.....',
    '...rrrrrrrrrr...',
    '..rrrrrwwrrrrr..',
    '..RRrrrwwrrrRR..',
    '...rrrrrrrrrr...',
    '...rwwwwwwwwr...',
    '...rwwrrrrwwr...',
    '...rwrwrrwrwr...',
    '...rwrrwwrrwr...',
    '...rwrrwwrrwr...',
    '...rwrwrrwrwr...',
    '...rwwwwwwwwr...',
    '...RRRRRRRRRR...',
    '................',
  ]);
  sprites['clock'] = (() {
    final px = Px(16, 16);
    px.ellipse(8, 8, 6.5, 6.5, 'C');
    px.ellipse(8, 8, 5.5, 5.5, 'W');
    px.rect(7, 4, 2, 5, 'n');
    px.rect(8, 7, 3, 2, 'n');
    px.set(7, 3, 'C');
    px.set(8, 3, 'C');
    return px..outline();
  })();
  sprites['note'] = (() {
    // a paper order note for the orders board
    final px = Px(12, 14);
    px.rect(1, 2, 10, 11, 'L');
    px.rect(1, 12, 10, 1, 's');
    px.rect(3, 6, 6, 1, 's');
    px.rect(3, 8, 5, 1, 's');
    px.rect(3, 10, 6, 1, 's');
    px.outline();
    px.set(5, 1, 'p');
    px.set(6, 1, 'p');
    px.set(5, 2, 'R');
    px.set(6, 2, 'p');
    return px;
  })();
}

void _buildings() {
  // ---- Windmill tower (32x44); blade hub at (16, 13)
  final tower = Px(32, 46);
  for (var y = 14; y < 45; y++) {
    final t = (y - 14) / 31; // taper
    final half = (8 + t * 5).round();
    tower.rect(16 - half, y, half * 2, 1, 'S');
    tower.rect(16 - half, y, 2, 1, 'L');
    tower.rect(16 + half - 3, y, 3, 1, 's');
    if (y % 4 == 0) tower.rect(16 - half, y, half * 2, 1, 's');
  }
  tower.rect(12, 36, 8, 9, 'b'); // door
  tower.rect(13, 37, 6, 8, 'D');
  tower.rect(13, 36, 6, 1, 'B');
  tower.set(17, 41, 'y');
  tower.rect(13, 24, 6, 6, 'b'); // window
  tower.rect(14, 25, 4, 4, 'n');
  tower.rect(14, 25, 2, 2, 'U');
  tower.rect(10, 44, 12, 1, 's');
  tower.ellipse(16, 15, 11, 9, 'r', topHalf: true); // roof cap
  tower.rect(5, 14, 22, 2, 'R');
  tower.ellipse(13, 11, 3, 3, 'p', topHalf: true);
  tower.rect(15, 4, 2, 3, 'D'); // finial
  tower.outline();
  sprites['windmillTower'] = tower;

  // ---- Windmill blades (48x48), hub in the middle
  final sail = Px(48, 48);
  for (var y = 3; y < 22; y++) {
    sail.rect(22, y, 4, 1, 'B'); // spar
  }
  sail.rect(26, 3, 6, 17, 'W'); // cloth
  for (var y = 5; y < 20; y += 4) {
    sail.rect(26, y, 6, 1, 'c');
  }
  sail.rect(31, 3, 1, 17, 'c');
  final blades = Px(48, 48);
  var s = sail;
  for (var k = 0; k < 4; k++) {
    blades.blit(s, 0, 0);
    s = s.rotated90();
  }
  blades.ellipse(24, 24, 4, 4, 'D');
  blades.ellipse(24, 24, 2, 2, 'b');
  blades.outline();
  sprites['windmillBlades'] = blades;

  // ---- Bakery oven (44x40); opening at (16..28, 24..35)
  final oven = Px(44, 42);
  oven.rect(31, 2, 7, 14, 'C'); // chimney
  oven.rect(31, 2, 2, 14, 'c');
  oven.rect(30, 1, 9, 3, 'k');
  oven.ellipse(22, 28, 19, 22, 'r', topHalf: true); // dome
  for (var y = 10; y < 28; y += 4) {
    for (var x = 2 + ((y ~/ 4) % 2) * 3; x < 42; x += 6) {
      if (oven.get(x, y) == pal['r']) oven.rect(x, y, 2, 1, 'R');
    }
  }
  oven.ellipse(16, 14, 6, 5, 'P', topHalf: true);
  oven.rect(2, 28, 40, 13, 'c'); // stone base
  for (var x = 2; x < 42; x += 8) {
    oven.rect(x, 33, 1, 3, 'C');
    oven.rect(x + 4, 37, 1, 4, 'C');
  }
  oven.rect(2, 32, 40, 1, 'C');
  oven.rect(2, 36, 40, 1, 'C');
  oven.rect(2, 40, 40, 1, 'k');
  oven.ellipse(22, 31, 8, 10, 'n', topHalf: true); // opening
  oven.rect(14, 31, 16, 5, 'n');
  oven.rect(12, 36, 20, 2, 'k'); // ledge
  oven.outline();
  sprites['oven'] = oven;

  // ---- Popcorn machine (30x40)
  final pop = Px(30, 40);
  pop.rect(4, 4, 22, 5, 'r'); // roof
  pop.rect(4, 4, 22, 1, 'p');
  pop.rect(6, 1, 18, 3, 'p');
  pop.rect(13, 0, 4, 1, 'y');
  pop.rect(5, 9, 20, 14, 'u'); // glass
  pop.rect(5, 9, 2, 14, 'W');
  pop.rect(24, 9, 1, 14, 'U');
  final rnd = Random(3);
  for (var i = 0; i < 70; i++) {
    final x = 6 + rnd.nextInt(18);
    final y = 14 + rnd.nextInt(9);
    pop.set(x, y, ['w', 'L', 'y', 'W'][rnd.nextInt(4)]);
  }
  pop.rect(3, 23, 24, 11, 'r'); // cart
  pop.rect(3, 23, 24, 2, 'p');
  pop.rect(3, 33, 24, 1, 'R');
  pop.rect(10, 26, 10, 5, 'y'); // label
  pop.rect(11, 27, 8, 3, 'Y');
  pop.ellipse(8, 35, 3.5, 3.5, 'n'); // wheels
  pop.ellipse(22, 35, 3.5, 3.5, 'n');
  pop.set(8, 35, 'c');
  pop.set(22, 35, 'c');
  pop.outline();
  sprites['popcornMachine'] = pop;

  // ---- Feed mill (36x44): a grain silo with a hopper
  final feed = Px(36, 46);
  feed.rect(5, 14, 18, 30, 'c'); // silo
  feed.rect(5, 14, 3, 30, 'W');
  feed.rect(19, 14, 4, 30, 'C');
  for (var y = 20; y < 44; y += 7) {
    feed.rect(5, y, 18, 1, 'C');
  }
  feed.ellipse(14, 15, 11, 12, 'r', topHalf: true); // cone roof
  feed.rect(3, 14, 22, 2, 'R');
  feed.ellipse(10, 9, 3, 3, 'p', topHalf: true);
  feed.rect(23, 22, 11, 22, 'B'); // shed
  feed.rect(23, 22, 11, 2, 'b');
  feed.rect(26, 32, 6, 12, 'D');
  feed.rect(25, 26, 8, 3, 'y'); // sign with grain
  feed.rect(22, 18, 13, 4, 'r');
  feed.rect(22, 18, 13, 1, 'p');
  feed.rect(3, 44, 31, 1, 'C');
  feed.outline();
  sprites['feedMill'] = feed;

  // ---- Dairy (44x40): white cottage with blue roof and a milk sign
  final dairy = Px(44, 42);
  dairy.rect(4, 18, 36, 22, 'W'); // walls
  dairy.rect(4, 18, 36, 1, 'c');
  dairy.rect(36, 18, 4, 22, 'c');
  for (var x = 4; x < 40; x += 6) {
    dairy.rect(x, 18, 1, 22, 'c');
  }
  for (var y = 2; y < 19; y++) {
    // roof: trapezoid
    final inset = (18 - y) ~/ 2;
    dairy.rect(1 + inset, y, 42 - inset * 2, 1, (y % 3 == 0) ? 'U' : 'u');
  }
  dairy.rect(1, 17, 42, 2, 'e');
  dairy.rect(17, 27, 10, 13, 'b'); // door
  dairy.rect(18, 28, 8, 12, 'D');
  dairy.rect(21, 28, 1, 12, 'b');
  dairy.rect(7, 25, 7, 6, 'n'); // window
  dairy.rect(8, 26, 2, 2, 'U');
  dairy.rect(30, 25, 7, 6, 'n');
  dairy.rect(31, 26, 2, 2, 'U');
  dairy.ellipse(22, 10, 5, 5, 'W'); // milk drop sign
  dairy.rect(21, 3, 2, 3, 'W');
  dairy.ellipse(21, 9, 1.5, 1.5, 'c');
  dairy.outline();
  sprites['dairy'] = dairy;

  // ---- Market stall (48x40): striped awning over a counter
  final stall = Px(48, 42);
  stall.rect(4, 12, 3, 28, 'b'); // posts
  stall.rect(41, 12, 3, 28, 'b');
  stall.rect(2, 26, 44, 14, 'B'); // counter
  stall.rect(2, 26, 44, 2, 'S');
  for (var x = 2; x < 46; x += 9) {
    stall.rect(x, 29, 1, 11, 'b');
  }
  stall.rect(2, 39, 44, 1, 'b');
  for (var x = 0; x < 48; x++) {
    final red = (x ~/ 6) % 2 == 0;
    final c = red ? 'r' : 'w';
    stall.rect(x, 2, 1, 10, c);
    if (x % 6 >= 1 && x % 6 <= 4) stall.rect(x, 12, 1, 2, c); // scallops
    if (x % 6 >= 2 && x % 6 <= 3) stall.rect(x, 14, 1, 1, c);
  }
  stall.rect(0, 2, 48, 1, 'p');
  stall.rect(0, 11, 48, 1, 'R');
  stall.outline();
  sprites['stall'] = stall;

  // ---- Orders board (44x38)
  final board = Px(46, 40);
  board.rect(6, 20, 4, 19, 'b'); // legs
  board.rect(36, 20, 4, 19, 'b');
  board.rect(2, 4, 42, 28, 'b'); // frame
  board.rect(4, 6, 38, 24, 'B');
  for (var y = 9; y < 30; y += 5) {
    board.rect(4, y, 38, 1, 's');
  }
  board.rect(2, 3, 42, 2, 'D');
  board.rect(2, 32, 42, 1, 'D');
  board.outline();
  sprites['ordersBoard'] = board;

  // ---- Chicken coop (32x30)
  final coop = Px(32, 32);
  coop.rect(4, 14, 24, 14, 'B');
  for (var x = 4; x < 28; x += 4) {
    coop.rect(x, 14, 1, 14, 'b');
  }
  for (var y = 1; y < 15; y++) {
    final inset = (14 - y);
    coop.rect(1 + inset, y, 30 - inset * 2, 1, 'r');
  }
  coop.rect(1, 13, 30, 2, 'R');
  coop.rect(12, 19, 8, 9, 'D');
  coop.ellipse(16, 20, 4, 3, 'D', topHalf: true);
  coop.rect(14, 28, 4, 3, 'b'); // ramp
  coop.outline();
  sprites['coop'] = coop;

  // ---- Little shed for cows (36x30)
  final shed = Px(38, 32);
  shed.rect(3, 12, 32, 18, 'r');
  for (var x = 3; x < 35; x += 4) {
    shed.rect(x, 12, 1, 18, 'R');
  }
  shed.rect(12, 16, 14, 14, 'W');
  shed.rect(13, 17, 12, 13, 'D');
  shed.rect(13, 17, 12, 1, 'W');
  for (var i = 0; i < 12; i++) {
    shed.set(13 + i, 17 + i, 'W');
    shed.set(24 - i, 17 + i, 'W');
  }
  for (var y = 1; y < 13; y++) {
    final inset = (12 - y) + 1;
    shed.rect(inset, y, 38 - inset * 2, 1, 'W');
  }
  shed.rect(1, 11, 36, 2, 'c');
  shed.outline();
  sprites['cowShed'] = shed;
}

void _pack() {
  const atlasW = 256;
  final names = sprites.keys.toList()
    ..sort((a, b) => sprites[b]!.h.compareTo(sprites[a]!.h));
  final rects = <String, List<int>>{};
  var x = 0, y = 0, rowH = 0;
  for (final n in names) {
    final s = sprites[n]!;
    if (x + s.w > atlasW) {
      x = 0;
      y += rowH + 2;
      rowH = 0;
    }
    rects[n] = [x, y, s.w, s.h];
    x += s.w + 2;
    rowH = max(rowH, s.h);
  }
  final atlasH = y + rowH;
  final atlas = Px(atlasW, atlasH);
  rects.forEach((n, r) => atlas.blit(sprites[n]!, r[0], r[1]));
  File('assets/images/extra.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(_png(atlas));

  final b = StringBuffer()
    ..writeln('// GENERATED by tool/make_sprites.dart - do not edit by hand.')
    ..writeln('// Original CC0 pixel art in the Kenney "Tiny" style.')
    ..writeln()
    ..writeln("import 'dart:ui';")
    ..writeln()
    ..writeln('/// Where each sprite is inside assets/images/extra.png.')
    ..writeln('abstract final class ExtraAtlas {');
  final sorted = rects.keys.toList()..sort();
  for (final n in sorted) {
    final r = rects[n]!;
    b.writeln(
      '  static const $n = Rect.fromLTWH(${r[0]}, ${r[1]}, ${r[2]}, ${r[3]});',
    );
  }
  b.writeln('}');
  File('lib/art/extra_atlas.dart').writeAsStringSync(b.toString());
  stdout.writeln(
    'Wrote ${sprites.length} sprites into a ${atlasW}x$atlasH atlas.',
  );
}

List<int> _png(Px img) {
  final raw = BytesBuilder();
  for (var j = 0; j < img.h; j++) {
    raw.addByte(0);
    for (var i = 0; i < img.w; i++) {
      final v = img.p[j * img.w + i];
      raw.add([(v >> 16) & 255, (v >> 8) & 255, v & 255, (v >> 24) & 255]);
    }
  }
  final out = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final td = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(td)
      ..add(_u32(_crc(td)));
  }

  chunk('IHDR', [..._u32(img.w), ..._u32(img.h), 8, 6, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes()));
  chunk('IEND', []);
  return out.toBytes();
}

List<int> _u32(int v) => [
  (v >> 24) & 255,
  (v >> 16) & 255,
  (v >> 8) & 255,
  v & 255,
];

int _crc(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}
