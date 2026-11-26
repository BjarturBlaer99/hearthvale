# A cosy farm look from asset packs — the plan

The user's request, 2026-11-25: make Hearthvale look like a cosy farming RPG, in the spirit of the
genre, with downloaded pixel-art asset packs made by their own artists, on licences that allow a game
sold commercially. Step 1 is this plan: research and a proposal, nothing downloaded, nothing in the
game changed. Step 2 switches the art in five phases (A terrain and trees, B buildings, interiors and
props, C crops, items and UI, D villagers, animals and monsters, E the hero), stopping after each.

## What the user has decided

**2026-11-25, shown the shortlist, its licences and what speaks against each pack:**

- **F1, the pack: Ninja Adventure,** by Pixel-Boy and AAA, CC0, free (section 3.3). The user chose
  it knowing what speaks against it: a feudal-Japan village, a flatter look, no crops or farm poses
  listed, short people. The repository is public and the other two packs forbid redistribution.
- **F2 and F10 fall away:** a CC0 pack may sit in a public repository, and there is no artist to
  ask.
- **F6 and F7: taken as recommended; the user has not spoken to them; open at the phase A
  review.** F6: the ground-detail rule is kept and its sheet painted again from the pack. F7: the
  pack's own edges are drawn where the code drew its fringe, banks and cliff faces.
- **F3, F4, F5, F8 and F9 are open:** they belong to later phases. (F8 decided 2026-11-26, F9 taken: see below.)

**2026-11-25, shown phase A's summary and pictures: "Approve phase A, go on to phase B".** And of
the pack in git, the same day: "Yes, without audio".

**2026-11-26, shown phase B's summary and pictures: "Approve phase B, go on to phase C".** F9 (what
is drawn in code stays drawn) stands as taken.

**How far it has come:**

- **Step 1, this plan:** written and committed (`54e1fd7`).
- **Step 2, phase A (terrain and trees): built on 2026-11-25 (`558a830`; the pack itself, without
  its audio, `29db85f`) and approved the same day.** Shown the summary and the before-and-after
  pictures, the user said: "Approve phase A, go on to phase B". It stands as built, and F6 and F7
  with it; the user said nothing separately of them, nor of the marsh's green ground. What was
  built, what the pack did not cover and what fits badly are in section 11.
- **Phase B (buildings, interiors, props): built on 2026-11-26 (`c73d69c`) and approved the same
  day.** Shown the summary and the before-and-after pictures, the user said: "Approve phase B, go
  on to phase C". It stands as built, F9's recommended answer with it (what is drawn in code stays
  drawn); the user said nothing separately of it. What was built, the gaps and what fits badly
  are in section 12.
- **Phase C (crops, items, UI): built on 2026-11-26 and waiting for the user's review.** Begun
  on that word, in a session of its own. **F8 was decided by the user during the phase,** shown
  seven screens in each look side by side: **"Dark wood, light text"** (the pack's frame round
  today's dark inside and light writing). What was built, the gaps and what fits badly are in
  section 13.
- Phases D and E: not begun.

**The plan as it was written follows** (sections 0 to 10). When it was written nothing had been
downloaded and nothing in the game had changed.

**Nothing was downloaded.** Every fact below was read on the packs' own pages on 2026-11-25, in the
app's browser. Where a page does not say something, this plan says "the page doesn't say" and the
answer waits for the files. Prices are as read that day; two of them are sale prices that end about
2026-11-29.

## 0. In short

- **The PNG pipeline is in place** (checked: `docs/progress/png-art-plan.md` is built, `art/sheets.json`
  lists 29 PNGs, `tests/art/` checks them). The switch can go ahead.
- **Three packs are shortlisted**, each one artist's whole family in one style:
  1. **Cute Fantasy, by Kenmi** (recommended). The nearest to the look asked for and the widest
     cover. **It must be bought** (two bundles, 17.50 and 10.00 USD on sale; I never pay).
  2. **Sunnyside World, by danieldiggle.** Free, commercial use allowed. Its people face only left
     and right, which is the wrong shape for this game's hero.
  3. **Ninja Adventure, by Pixel-Boy and AAA.** Free and CC0, the most complete of all (monsters,
     bosses, items, UI). A feudal-Japan village and a plainer, flatter look: the furthest from what
     was asked.
- **Two things I did not expect, and you need to know before choosing:**
  - **This repository is public on GitHub.** Packs 1 and 2 forbid redistributing their art, changed
    or not. Art cut from them cannot sit in a public repository. Either the repository is made
    private before the first pack file is committed, or the pack must be the CC0 one (section 7).
  - **The best fit on size, Mana Seed by Seliel the Shaper, is ruled out by its own licence.** It
    forbids use "in a project alongside 'AI' generated imagery, writing, code, or anything else".
    This game's code is written with an AI and some of its art is PixelLab's. It is not on the
    shortlist and should not be bought for this game.
- **No shortlisted pack has tall people.** The look asked for says "characters about 16x32", as the
  hero and the villagers are today. In all three packs people are short, about one cell wide and a
  cell to a cell and a half tall. With a pack, the hero and the villagers become short too, or they
  stay as they are on a new world, which is a mix of two styles (question F3).
- **Ten questions for you** in section 9. The four that decide the rest: which pack (F1), the public
  repository (F2), short people (F3), and your slime and bat (F4).

## 1. Checked first: three facts the request has out of date

| The request says | The code says | The plan uses |
|---|---|---|
| The hero has 21 frames a row | **25** a row, 3 rows (down, up, side facing left), 16x32, 400x96 in all: idle, blink, walk 1 to 6, windup, slash, follow, hold, fallen, breathe, hurt, run 1 to 6, raise, strike, pour, reach (`art/sheets.json`, `PlayerAnimator.COLUMNS`) | 25 |
| New terrain replaces the old tiles | It replaces the **warm-ground pass** finished and pushed today (`78ed546`, `86cd784`, `4c8aabb`): warmer colours, more grain in the ground tiles, and `ground_details.png` with its per-cell rule | section 6 says what becomes of each part |
| (not said) | **The slime and the bat are your own art** (PixelLab, `115d5dd`, 2026-11-23), as are the trees, two boulders, the bush, the grass and flowers, the houses' colours, the hero's look and the boxes' frame (2026-11-20) | question F4 asks whether the slime and the bat stay |

## 2. What the game's art is today

29 PNGs, each with its size, frames and pivot in `art/sheets.json`, checked by `tests/art/`:

| Kind | File | Layout |
|---|---|---|
| Hero | `gameplay/player/player_sheet.png` | 25 x 3 frames of 16x32, feet at (8, 32), no flash row |
| Tools in his hands | `gameplay/art/held_tools.png` | 57 frames of 40x56 (hoe, pickaxe, can in three tiers, the sprinkler; by facing and pose), his feet at (20, 40) |
| Villagers | `villager.png` | 6 frames of 16x32 (plain, bearded, each breathing and blinking), in four marker colours; one sheet for all eight villagers |
| Monsters | `slime.png`, `bat.png`, `wisp.png` 16x16 x 3; `goblin.png` 16x24 x 5 (front, front draw, back, side, side draw); `warden.png` 32x40 x 4; `shade.png` 32x40 x 3 | strips |
| Animals | `animals.png` 24x20 x 8 (sheep and cow: stand, walk, graze, blink); `critters.png` 16x16 x 8 (hen x 4, butterflies x 4) | face left |
| Crops, soil | `crops.png` 16x16 x 13 (seeded, sprout, withered, then five crops growing and ripe); `soil.png` x 4 | flat, never block |
| Items | `items.png` 16x16 x 74 | one icon each |
| Things in the world | `placed.png` x 25, `crafted.png` x 9, `rocks.png` x 11, `breakables.png` x 8, `forage.png` x 12, `crystal.png` x 3, `torch.png` 16x24 x 3, `dummy.png`, `brambles.png` | 16x16 but the torch and the dummy |
| Tiles | `world/tiles/greybox_tiles.png` | 8 x 34 tiles of 16x16; every tile's place is data (`GreyboxTiles`) |
| Trees | `world/tiles/scenery.png` | 7 trees of 32x40 in cells of 40x48, the trunk's foot at (16, 37) |
| Walls, pillar, ridges | `world/tiles/relief.png` | 96x112 (`ReliefAtlas`) |
| Ground details | `world/tiles/ground_details.png` | 26 frames of 16x16 |
| UI | `ui/art/ui_parts.png` 104x32 (a box's frame in nine pieces, the clock's dial); `ui/title/backdrop.png` 640x360 | |

Every sheet in `gameplay/art/` has a second row, the same frames in white (the hit flash).

**Drawn in code, with no PNG to replace:** shadows and soft edges, the grass's fringe over a path,
cliff faces, the water's movement and reflections, lights and darkness, mist, bursts, the sword's
blade, the hearts, the energy bar, the item bar's slots, the dial's hand, lit windows, the title's
stars and petals, and the things outlined in `PixelGrade.INK`: chests, dungeon doors, pickups,
signposts, pressure plates and push blocks. The fonts and all sound are made in code and stay so.

## 3. The shortlist

### 3.1 Cute Fantasy, by Kenmi (recommended; to be bought)

- **Pages:** [Cute Fantasy RPG](https://kenmi-art.itch.io/cute-fantasy-rpg) (the pictures and films
  on the page are the previews), [Dungeon](https://kenmi-art.itch.io/cute-fantasy-dungeon-16x16-top-down),
  [characters](https://kenmi-art.itch.io/cute-fantasy-characters-16x16-top-down-pixel-art-asset-pack),
  [UI](https://kenmi-art.itch.io/cute-fantasy-ui),
  [Icons](https://kenmi-art.itch.io/cute-fantasy-icons). The artist's page:
  [kenmi-art.itch.io](https://kenmi-art.itch.io/).
- **Price:** the bundle ["Cute Fantasy rpg Sale!"](https://itch.io/s/116495/cute-fantasy-rpg-sale),
  ten packs for **17.50 USD** (the RPG pack, Dungeon, UI, characters, Shroomlands, Volcano, Desert,
  War Camp, Christmas, Halloween; 30.93 off sale), and the
  ["7000 Cute Fantasy Icons Bundle"](https://itch.io/s/201539/7000-cute-fantasy-icons-bundle) for
  **10.00 USD** (35.00 off sale). Both sales end about 2026-11-29. Bought one by one, the four packs
  this game needs most are 3.99 (the RPG pack's premium licence), 2.99, 2.99 and 2.99.
- **Licence** (on each page; the same words on all five): the paid packs "can be used in any
  commercial or non-commercial project, you can modify the assets as much as you want. This asset
  pack can't be resold or redistributed even if modified." **The free version of the RPG pack and of
  the icons is for non-commercial projects only**, so it is no use here, even to start with.
- **Credit:** asked for on the RPG pack's page ("Please Credit: Kenmi"). It would go in the game's
  credits and `docs/ASSETS.md`.
- **AI:** the licence says nothing of AI. In the page's comments a buyer asked whether a game whose
  code is written with AI coding tools is compatible, and Kenmi answered "Yes". The same buyer then
  asked whether an AI coding assistant may see the sprite sheets to place them; **that has no answer
  on the page** (question F10).
- **Sizes:** tiles 16x16. Icons 16x16 (also 32 and 64). The page does not give the people's frame
  size; by eye from its pictures they are about 16 wide and 20 to 24 tall, hat and all.
- **What it covers** (as the pages list it):
  - ground: grass, water (animated), path, cliff, beach, bridge, cave, farmland, waterfall, pavement,
    hedges, wooden decks; "tileable grass"; many flowers, rocks, foliage;
  - trees, each with three stages of growth and a seed; round broadleaf and autumn trees are in the
    pictures. **A cherry in blossom and a willow are not on the page**;
  - buildings: over a hundred houses (limestone, wood, stone), **barn, coop, shed, silo**, church,
    inn, blacksmith's, stalls, windmill, greenhouse; interiors (two updates of them);
  - crops with seed, sign and item icon; ores; fences, scarecrows, mailboxes, barrels, torches,
    lanterns, furniture;
  - animals: cow, chicken, sheep and eight more; animated butterflies;
  - the player in layers (tool, hands, hair, shirt, trousers, shoes, body): idle, run, a sword
    attack in three stages, bow, roll, **tilling, chopping, mining, watering**, fishing, hit, dying,
    holding a lantern or an item, jumping, climbing, pushing. Kenmi says in the comments that
    nearly every animation has down, side and up. Eight NPCs ready made, and a tool to build more;
  - monsters: slime, four skeletons, a "bombshroom"; in the characters pack 4 goblins, 4 orcs,
    4 knights and 2 angels, each with idle, run, attack and hurt **facing up, down and side**, which
    is this game's three rows;
  - two dungeon tilesets and a sewer, with doors, gates, levers, pressure plates, spikes, pots,
    chests, statues;
  - UI: frames, a book, buttons, health bars, hearts, sliders, selectors, a font;
  - about 7,000 icons: farming, food, tools, resources, weapons, potions, treasure and keys,
    monster drops, armour.
- **For it:** warm, saturated, outlined in dark colour, chunky round trees, wooden buildings, crops
  in clear stages, a wood-and-paper UI. It is the look the request describes, by its own artist. It
  has this game's own farm buildings by name, monsters in this game's three facings, and a hero
  whose tools are a layer of their own, as `held_tools.png` is.
- **Against it:** it costs money. Its art may not sit in a public repository. Its people are short.
  The pack is still growing ("an ongoing project"), so a later download may differ from this one.

### 3.2 Sunnyside World, by danieldiggle (free)

- **Page:** [danieldiggle.itch.io/sunnyside](https://danieldiggle.itch.io/sunnyside) (pictures and
  films on the page).
- **Price:** free ("name your own price"; itch lists it under free assets).
- **Licence (V1, on the page):** "This asset pack can be used in free and commercial projects. You
  can modify the assets as you need. Credit is not necessary, but always appreciated." It may be
  redistributed "as part of tutorials or educational courses" with a link to the page. "You may not
  repackage and resell the assets, no matter how much they are modified". "You may not use these
  assets to train AI."
- **Credit:** none needed.
- **Sizes:** tiles 16x16. People about a cell tall by eye; the page gives no frame size.
- **What it covers:** a tileset with land, cliffs, paths, dirt, water, foliage, fences, walls,
  buildings and interiors, with autotiles; **11 crops in 5 stages each**, with harvest pictures;
  a game UI with icons and emotes; humans and goblins with 20 actions (idle, walk, run, roll, jump,
  hurt, death, carry, attack, swim, cutting trees, mining, building, fishing and more); a skeleton
  with six; seven animated hairstyles, meant for palette swapping.
- **For it:** free, cheerful, complete for a farm, and a goblin is in it.
- **Against it:** the page says in so many words that its people are drawn **for left and right
  only**. A beta file, "Human - 4,6,8 way movement", is on the page; what it holds beyond walking
  the page doesn't say. This game's hero has a row facing down and a row facing up for every one of
  his 25 frames: sword, hoe, pickaxe, can. With this pack two of his three rows would have to be
  drawn from nothing. The page lists no animals, no dungeon or cave, no bat, no bosses. Its licence
  allows redistribution only in tutorials, so it too needs a private repository.

### 3.3 Ninja Adventure, by Pixel-Boy and AAA (free, CC0)

- **Page:** [pixel-boy.itch.io/ninja-adventure-asset-pack](https://pixel-boy.itch.io/ninja-adventure-asset-pack);
  its Godot project is public at [github.com/pixel-boy/NinjaAdventure](https://github.com/pixel-boy/NinjaAdventure).
- **Price:** free ("name your own price").
- **Licence (on the page):** "They are released under the Creative Commons Zero (CC0) license. You
  can use any and all of the assets found in this package in your own games, even commercial ones.
  Attribution is not required but appreciated."
  ([CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/))
- **Credit:** none needed; a link to the page is asked for kindly.
- **Sizes:** the pack is tagged 16x16; its people are one cell tall.
- **What it covers** (the page's list): 50+ characters with animations and face pictures, **30+
  monsters, 9 bosses**, 60+ items, tilesets ("floor autotiling, exterior and interior element"), a
  UI theme, 30+ effects, two fonts, and since March 2026 one character with a fuller set (idle,
  walk, swim, jump, attack with five weapons and tools, hit, death, roll, push, climb, pick up and
  show an item) and new animals. Music and sound are in it too; this game makes its own.
- **For it:** CC0 is the one licence here with no strings at all: it can sit in a public
  repository, be kept whole in `art/packs/`, and be changed by any tool. It is the only pack with
  bosses, and its monsters are many.
- **Against it:** it is a ninja village: thatched Japanese houses, samurai, pagodas. Hearthvale is
  half-timbered houses, a chapel, a keep and a crypt. Its drawing is flatter and simpler, nearer an
  8-bit adventure than the soft, hand-shaded farm look asked for. The page lists no crops, no
  growth stages, and no hoe or watering pose; 60 items is fewer than this game's 74.

### 3.4 Also looked at, and why not

| Pack | Why not |
|---|---|
| **Mana Seed**, Seliel the Shaper ([licence](https://selieltheshaper.weebly.com/user-license.html)) | The best fit on size: a 16x16 grid, tall people, a farmer with every tool. **Ruled out:** "I do not consent for any of my art to be ... used in a project alongside 'AI' generated imagery, writing, code, or anything else." Paid, too |
| **Hana Caraka**, Otterisk ([series](https://itch.io/c/3569702/hana-caraka-series)) | The runner-up to Cute Fantasy. Seven packs for 29.99 USD: a ground tileset by season, farming and foraging, livestock, dungeon and mining, interiors, and a 16x16 character with 35 animations in four directions (two sword swings, bow, hoe, watering, pickaxe, planting, damage, death, pick up). Commercial use allowed, no credit needed, no redistribution, not for training AI image generators. A quiet, minimal look, less warm and textured than asked for; no UI pack and no monsters named in the series' list. Worth a second look if you would rather have its calm than Cute Fantasy's colour |
| **Sprout Lands**, Cup Nooble ([page](https://cupnooble.itch.io/sprout-lands-asset-pack)) | Pastel, by its own words; the request is warm and saturated. The free version is non-commercial; the premium is 3.99 USD. No monsters or dungeon yet |
| shubibubi's Cozy packs; Emanuelle's Farm RPG; VectoRaith's farming pack | Found by search. Their licence pages were not read in this pass, so they are not offered |
| Packs on a 32x32 grid, or with share-alike or GPL terms (the Liberated Pixel Cup family, for one) | The grid is wrong for this game's maps, and the terms are not the kind the request allows. Not read in this pass |

## 4. Coverage: every kind of art the game uses

"Yes" means the pack's page lists it. "Fit" means it is there but must be cut or arranged to this
game's layout (section 5). "?" means the page doesn't say. "No" means the page lists nothing of the
kind; only the files can make a "no" certain.

| What the game uses | Cute Fantasy | Sunnyside World | Ninja Adventure |
|---|---|---|---|
| Grass, path, water (4 frames), stairs | yes | yes | yes |
| Ground by height: lighter grass, then rock (8 columns) | fit: made from the pack's grass and cliff rock | fit | fit |
| Dungeon floor, walls, pillar, pits, ledges | yes (Dungeon pack) | no | ? (interiors listed; a dungeon is not) |
| The quarry: earth, cave walls, ore rocks, rails, ladder, lift | yes: cave tiles, ores (the lift: ?) | no | ? |
| The marsh: mossy ground, boardwalk, reeds, ruined hut, lantern posts | **no** (wooden decks could be the boardwalk) | no | ? (its Godot project has a "swamp" folder) |
| Trees: broadleaf, oak, pine | yes (pine: ?) | yes (pine: ?) | yes (pine: ?) |
| Cherry in blossom (two pictures), willow (two) | **not on the page** | not on the page | ? |
| Houses: red, blue and thatch roofs, half-timbered walls, windows, doors, chimney | fit (houses are whole pictures) | fit | fit, in another style of house |
| The chapel, the shop's sign, market stalls | yes: church, stalls | ? | ? |
| Farm buildings: well, silo, coop, barn, shed, a site | yes: silo, coop, barn, shed (well: ?; site: no) | ? | no |
| Interiors: floor, walls, table, bed, shelf, barrel, hearth, chair, loom, counter, bookcase... | yes (loom: ?) | yes | yes |
| Props: fence, crate, keg, hay, logs, stump, lamp, standing stone, washing line | yes for most | yes for most | yes for most |
| Crops: turnip, carrot, wheat, potato, pumpkin; seeded, sprout, withered | yes for crops (turnip: ?; withered: ?) | yes: 11 crops, 5 stages (which crops: ?) | no |
| Soil: bare, tilled, watered | yes (farmland) | yes | ? |
| Forage: berries, mushrooms, blossoms, cattails, marsh berries, bog mushrooms, full and picked | fit: bushes and mushrooms; the marsh's three: no | ? | ? |
| Items: 74 icons | yes for most (about 7,000 icons); this game's own (wisp ember, shuttle, heart piece, kit...) are gaps | fit: "icons" (how many: ?) | fit: 60+ items, fewer than 74 |
| Placed things: paths, fence and its joins, gate, floors, hedge, bench, lamp post, flower beds, saplings in three ages | yes for most; trees have three stages | yes for most | fit |
| Furnishings: workbench, furnace, chest, lamp, rug, blanket, sprinkler | fit (sprinkler: ?) | ? | fit |
| Breakables: grass, pot, branch, stump, weeds, bush, log | yes | yes for most | yes for most |
| Animals: sheep, cow (stand, walk, graze, blink); hen; butterflies | yes; graze and blink: fit | **not listed** | "animals" listed; which: ? |
| Slime | yes | ? | yes ("30+ monsters"; which: ?) |
| Bat | **not on the page** | ? | ? |
| Bogwisp | no | no | ? |
| Goblin archer (front, back, side; drawing a bow) | yes: goblins in three facings (one with a bow is in the page's picture) | fit: a goblin, sideways only | ? |
| The Iron Warden (32x40), the Crypt Shade (32x40) | **no bosses**; a knight and a dark angel are the nearest, at a cell's size | no | yes: 9 bosses (which: ?) |
| Villagers: eight, standing, breathing and blinking | yes: 8 NPCs and a builder | fit: humans, sideways | yes: 50+ characters |
| The hero: 25 poses in 3 facings | fit: every pose has a source; short | **no**: sideways only | fit: no run, no hoe or can pose listed; short |
| Tools in his hands, three tiers | fit: the tool is a layer; copper and iron by recolouring | no | fit |
| UI: box frame, hearts, bars, slots, the clock's dial | yes but the dial | yes but the dial | yes but the dial |
| The title picture, 640x360 | no | no | no |
| Ground details, 26 small pictures | fit: from its flowers, tufts and stones | fit | fit |

**What Cute Fantasy would leave missing** (to draw later by hand in its colours, or keep as now,
on your word for each):

1. The marsh: its mossy ground, reeds, ruined hut and lantern posts, and its three forage plants.
2. The cherry in blossom and the willow, unless the files hold them. A pink crown recoloured from
   the pack's own round tree is one style, not two; a willow has no such shortcut.
3. The bat and the Bogwisp.
4. The two bosses at their size.
5. The clock's dial, a building site, the lift, and this game's own items (about ten icons).
6. The title picture.
7. Everything drawn in code today (chests, dungeon doors, signposts, pickups, plates, push blocks)
   stays as drawn unless you say otherwise (F9).

## 5. The hard parts, and how each would be fitted

**The rule for all of them:** timing, hits and collisions do not change. A picture is cut, moved,
mirrored or recoloured to fit this game's layout. Where that cannot work, the game changes only
*how it slices a sheet* (a frame's size, a pivot, where a piece lies), and `art/sheets.json` and the
art tests change with it. Nothing in a map, in `data/`, or in a motor.

1. **The ground has no edge tiles.** A pack draws the ground as sets of tiles: a middle, and
   edges and corners for where grass meets a path or water, and cliffs that fill cells of their
   own. This game has one tile for each ground at each height, and draws the grass's fringe over a
   path, the line under a bank and the face under a drop in code (`HeightShading`), in the places
   it works out itself. Two ways:
   - **a.** Use only the pack's middle tiles, and keep the code's fringe, bank and faces, with
     their colours matched to the new grass (`GreyboxTiles.GROUND_COLORS`, `FACE_COLOR`,
     `BANK_SHADE`). No new code. The pack's hand-drawn edges, a large part of the look, are lost.
   - **b.** Draw a strip of the pack's own edge where `HeightShading` draws its fringe, its bank
     and its cliff face today: the same places, a picture where there is now a flat colour, from a
     new small sheet. Code that only draws; no map changes; tests for which strip goes where.
     *Recommended: b* (question F7).
2. **Height.** The ground is 8 columns, grass growing lighter and turning to rock as it rises. A
   pack has one grass. The other columns are made from the pack's own grass and rock by the rule
   used today.
3. **Houses are built from repeating tiles; a pack draws each house whole.** The village's houses
   and the farm's five buildings are blocks of tiles named by the maps and by `data/buildings/`
   (the barn is a roof 6 by 2, a wall 6 by 2, a loft door and a door). From a pack's house come its
   repeating parts: the roof's middle, ridge, eave and gable edge, a wall, a window, a door, each
   into its place in the atlas. The pack's one-off shapes (a porch, a crooked chimney) are lost.
   Showing a pack's house as one whole picture would need a new word in the buildings' data and in
   the maps, which is outside "art only", so it is not proposed.
4. **Lit windows** are rectangles in code (`WindowGlow.GLASS`: 6 by 4 pixels at (5, 5) of the
   window tile). A pack's window either has its glass there, or the rectangle moves in code.
5. **Trees** are 32x40 with the trunk's foot at (16, 37). Pack trees are often taller or wider.
   They are not shrunk (shrinking spoils pixel art): `SceneryAtlas` gets the pack's size and foot.
   A tree still blocks only its own cell, and a crown still fades when something is behind it.
6. **The hero.** 75 frames: 25 poses in 3 rows.
   - *Facings:* down, up, and side facing left (right is mirrored). A pack with four directions
     gives its left, or its right mirrored.
   - *Counts:* walk and run are six frames here; a pack's cycle of four or eight is thinned or
     repeated to six. The swing is three (windup, slash, follow): three are picked from the pack's
     swing. The motor times the swing, the pictures only follow.
   - *The sword:* this game draws the blade in code from his hand (`Sword.HAND`). The pack's own
     blade is left out (in Cute Fantasy the tool is a layer of its own), and `Sword.HAND` moves to
     the new hand. The reach is measured from his feet and does not change.
   - *Poses with no walk in them:* blink (the idle frame with two pixels closed), breathe (the
     pack's second idle frame), hold (its "holding an item" pose), hurt (its hit frame), fallen
     (the last frame of its dying), raise and strike (tilling or mining without the tool), pour
     (watering), reach (picking up). With Cute Fantasy each has a source. With Ninja Adventure run,
     raise, strike and pour have none. With Sunnyside World the down and up rows have none at all.
   - *Size:* a short hero is drawn low in his 16x32 frame, feet where they are; if a pose is wider
     than 16, the frame is made wider and his feet stay at its middle (`PlayerAnimator.FRAME_SIZE`
     and the pivot: slicing only). He collides where he always did. He would no longer hide the
     cell north of him.
7. **The tools in his hands** are 57 frames of their own, so that one hero carries three tiers of
   each tool. A pack draws one tool. With a layered pack the tool layer is cut into those frames,
   and copper and iron are the same tool with its head recoloured. With a pack that draws the tool
   into the body, the tool must be cut out by hand.
8. **Villagers** are one figure in two looks, six frames, facing the player. See section 6.
9. **Monsters** keep their frame names and their pivots. A pack's monster of another size gets its
   size in `sheets.json` and its script; what can be hit is in code and data and does not move, so
   a monster is kept within a pixel or two of today's size, or it would look hittable where it is
   not. The goblin needs a front, a back and a side, and a frame drawing its bow for front and
   side. The bosses must fill about 32x40.
10. **The white flash row** under every sheet of `gameplay/art/` is made by a script from each new
    frame's shape, as it was for your slime and bat.
11. **Crops** here share three first pictures (seeded, sprout, withered) and have two of their own
    (growing, ripe). A pack has four to six stages for each crop: the first two of one crop serve
    all, a middle stage is "growing", the last is "ripe". A withered plant is the growing one
    browned, if the pack has none. A crop drawn taller than its cell is cut to 16x16 or drawn
    upward from it; it never blocks.
12. **Items** are picked by meaning from the pack's icons, 16x16, in this game's order. This
    game's own things with no match are gaps.
13. **The UI.** A pack's frame is a nine-piece box of its own widths: `UiParts` gets the new
    places. The hearts, the energy bar and the slots are drawn in code; they either take the
    pack's colours or become pictures from it. **A pack's boxes are parchment with dark writing;
    this game's are dark wood with light writing**, and every menu's text colour comes from the
    theme the font tool bakes. Parchment is asked for in the request and is a change in that tool
    (F8). The fonts stay this game's own.
14. **The title picture** has places in code: 14 stars, the keep's window, seven cherry trees'
    feet. No pack has a title picture. It stays as it is, the one old picture left, or is drawn
    again later.
15. **Colours in code** must be matched to the new art, or seams show: the grass's fringe, the
    cliff faces, the bank's shade, the water's glint and depth, `PixelGrade.INK`, the UI's colours,
    the title's sky. The faint gold daylight and the warmer indoor light of the warm-ground pass
    are data and lighting, not art: they stay, and they will warm the pack's colours a little
    beyond what its artist drew. The pictures of phase A will show whether that suits.
16. **The still world.** A pack's waving grass, turning windmill sails, drifting smoke and swaying
    trees are not used: one frame of each. The water moves, as now.
17. **Light.** This game's art is lit from the north-west. A pack lit from elsewhere would fight
    the code's shadows. By eye, from the pages' pictures, none of the three is plainly lit from
    another side; the files will tell.

## 6. Villager recolouring, the master palette, and the ground details

### 6.1 How recolouring works today

`SpriteSheet.recoloured()` takes `villager.png` and swaps every pixel within 0.01 of a marker colour
for a villager's own: robe `#FF00FF`, robe shade `#800080`, hair `#00FFFF`, hair shade `#008080`
(`art/palettes/villager_markers.gpl`). Each villager's scene gives a robe colour and a hair colour;
the shade is that colour darkened by 30%. A test holds that all four markers are on the sheet and
that no other pixel comes near them.

### 6.2 With pack art

**Recommended: keep the mechanism, and paint the pack's figure in the markers.** One standing
figure from the pack, and the same with a beard, each with a breathing and a blinking frame: the
same six frames. Its clothes are painted in the robe markers and its hair in the hair markers,
darkest tone to the shade, by a script. Skin, eyes and shoes keep the pack's colours, which are
nowhere near magenta or cyan. Nothing changes in a scene or in `Villager`.

Three things to know:

- **A pack shades in three or four tones; the markers allow two.** If two tones look flat in
  phase D's pictures, a third marker for each (a light) is a small change: one more swap in
  `Villager._sheet()`, one more line in the marker palette and its test. Not before it is seen.
- **Outlines.** Pack art outlines cloth in a darker shade of the cloth. That outline is painted as
  the shade marker, or left a fixed dark; the pictures decide.
- **The sixteen colours in the villagers' scenes** were chosen against the old art. They stay as
  they are. If one sits badly in the pack's palette, it is yours to change.

**The other way: eight villagers each with a face of their own,** from the pack's ready-made NPCs
(Cute Fantasy has eight, and this game has eight villagers). It would look best. It ends
recolouring for villagers: a sheet of eight figures with their breathing and blinking frames, and
`Villager` choosing a figure by who it is. That is more than slicing, so it is your choice (F5).

### 6.3 The master palette

`art/palettes/hearthvale.gpl` is the 256 colours the art uses most, and each sheet has its own
palette file. Both are made again from the PNGs after every phase, as after every art pass so far.
From phase A to phase E the master is a mix of old and new; after E it is the pack's own. Asked in
the comments, Kenmi thinks the whole pack is under 256 colours; if so, the master may then simply
be the pack's. Any gap drawn later is drawn in that palette.

### 6.4 The warm-ground pass

- **The warmer tiles and their grain** (steps 1 and 2) are replaced with the ground tiles in phase
  A. That work is in git history.
- **The colours it changed in code and in the day's light** stay, matched to the new art where
  they touch it (section 5, point 15).
- **The ground details.** The rule stays: which cell gets a detail, how many, and never where
  something stands (`GroundDetails`, `data/rules/ground_detail.json`). It is a rule about *where*,
  and it knows nothing of what a detail looks like. **The sheet is painted again, whole, from the
  pack's own small ground pieces** (its tufts, small flowers and stones), the same 26 frames in
  the same order. No frame of today's sheet is kept, so the two are never mixed. Where the pack
  has nothing for a ground (the quarry's grit, the dungeon's cracks), the frame is one of the
  pack's own details recoloured to that ground. The rule that a detail must not look like
  something to pick up, cut or break still holds, and its test still checks it. *Recommended.*
  **The other choice is to retire the details** and list them as a gap (F6).

## 7. Licences and this repository

1. **The repository `BjarturBlaer99/hearthvale` is public.** Cute Fantasy "can't be resold or
   redistributed even if modified"; Sunnyside World may be redistributed only in tutorials. A
   public repository hands the files to anyone. That goes for the untouched pack in
   `art/packs/` and equally for the game's own PNGs cut from it. So, with either of those packs:
   **the repository is made private before the first pack file is committed** (yours to do; I
   won't change a repository's settings). What is already in its history is this game's own art
   and PixelLab's, and is unaffected. With Ninja Adventure nothing needs to change.
2. **`art/packs/<pack-name>/`** holds each pack untouched with its licence, as you asked. In a
   private repository it can be committed. A pack's licence is on its page, not always in its zip:
   I would save the page's licence words with the date in a `LICENCE.txt` beside the pack.
3. **A game that is sold** ships the art inside it. All three licences allow that.
4. **AI and these packs.** Mana Seed forbids any AI in the project, which rules it out. Sunnyside
   World and Hana Caraka forbid training AI on the art. Cute Fantasy's licence is silent, and its
   artist has said AI-written code is fine. **So gaps must not be filled by giving a pack's art to
   PixelLab as a style to copy.** A gap is drawn by hand in Aseprite, or by a script from the
   pack's own pieces, or made in PixelLab from words alone.
5. **In step 2 the fitting is done by scripts I write:** the art is cut, moved, mirrored and
   recoloured, never generated. Whether Kenmi minds an AI assistant handling the sheets at all is
   the one thing the page leaves open (F10).
6. **`docs/ASSETS.md`** gets a section for the pack (name, author, page, licence with a link and
   its words, credit, the date bought or downloaded) and each PNG's row says which pack it came
   from. The rows that say PixelLab change as each PNG is replaced.

## 8. Step 2, as it would go

| Phase | What changes | What it leans on |
|---|---|---|
| A. Terrain and trees | the atlas's ground, stairs, path, water, dungeon, quarry and marsh rows; `scenery.png`; the ground details; the edge strips (F7); the colours in code | section 5, points 1, 2, 5, 15; section 6.4 |
| B. Buildings, interiors, props | the atlas's house, roof, building, furniture and prop rows; `relief.png`; `placed.png`, `crafted.png`, `rocks.png`, `breakables.png`, `forage.png`, `torch.png` | points 3, 4 |
| C. Crops, items, UI | `crops.png`, `soil.png`, `items.png`, `ui_parts.png`, the UI's colours or pictures | points 11, 12, 13 |
| D. Villagers, animals, monsters | `villager.png`, `animals.png`, `critters.png`, the six monster sheets | points 9, 10; section 6 |
| E. The hero | `player_sheet.png`, `held_tools.png` | points 6, 7 |

At every stop: all tests pass, the atlas's places and the sheets' sizes fit the game,
`docs/ASSETS.md` and the palettes are up to date, before-and-after pictures from the same spots,
and a list of what the pack did not cover. Between phases the game is a mix of old and new: the
old hero walks the new world until phase E.

**It will not be a clean swap.** A pack is drawn for its own layout, and this game's layout is its
own. Expect each phase to end with a short list of gaps, and some pieces that fit less well than
the pack's own pictures promise. Phase A is the test of the whole idea: if the ground and the
trees do not sit well in this game, it is the place to stop, with only two files changed.

## 9. Questions for you

1. **F1. Which pack.** Cute Fantasy (you buy the two bundles, 27.50 USD on sale, and put the zips
   where I can read them); Sunnyside World (free); Ninja Adventure (free, CC0); or none of them,
   and the look stays as it is. *Recommended: Cute Fantasy, if F2 and F3 suit you. If the
   repository must stay public, Ninja Adventure is the only one that can be used.*
2. **F2. The public repository.** With Cute Fantasy or Sunnyside World: make it private before
   the pack is committed. *Needed for either; yours to do.*
3. **F3. Short people.** Take the pack's short hero and villagers, in one style with the world
   (*recommended with a pack*); or keep today's tall hero and villagers on the new world, two
   styles side by side, and leave out the villagers of phase D and all of phase E.
4. **F4. Your slime and bat** (PixelLab, 2026-11-23). Keep them, or replace them with the pack's.
   Cute Fantasy has a slime; a bat is not on its page. *Recommended: replace the slime in phase D,
   and keep your bat until the pack's files show one.*
5. **F5. Villagers:** one figure recoloured for each, as now (*recommended: nothing but the sheet
   changes*); or eight faces of their own from the pack's NPCs.
6. **F6. Ground details:** the rule kept and the sheet painted again from the pack
   (*recommended*); or retired.
7. **F7. The ground's edges:** the pack's own edges drawn where the code draws its fringe, banks
   and cliff faces today (*recommended*); or the pack's middle tiles only, with the code's edges.
8. **F8. Inside the boxes:** parchment with dark writing, as the request says and the packs draw
   (the font tool's theme changes, and every menu with it); or the pack's frame round today's dark
   wood and light writing. *Recommended: decide it at phase C, with a picture of each.*
9. **F9. What is drawn in code** (chests, dungeon doors, signposts, pickups, plates, push blocks):
   leave them as drawn and list them as a gap (*recommended for now*); or make them pictures from
   the pack in phase B, which is new drawing code.
10. **F10. A word to Kenmi before you buy** (only if F1 is Cute Fantasy). Two things the page
    leaves open: that the game's repository will be private, and that an AI coding assistant will
    cut and arrange the sheets by script, never generating art from them. I can write the message
    for you to send. *Recommended, since it costs a day and settles both.*

## 10. Sources (all read 2026-11-25)

- Cute Fantasy RPG, Kenmi: https://kenmi-art.itch.io/cute-fantasy-rpg (licence, contents, the
  comments quoted); its updates 9 and 12:
  https://kenmi-art.itch.io/cute-fantasy-rpg/devlog/907859/cute-fantasy-update-9-player-rework,
  https://kenmi-art.itch.io/cute-fantasy-rpg/devlog/1089694/cute-fantasy-update-12-village-overhaul
- Cute Fantasy Dungeon, characters, UI, Icons, and the two bundles: linked in section 3.1
- Sunnyside World, danieldiggle: https://danieldiggle.itch.io/sunnyside
- Ninja Adventure, Pixel-Boy and AAA: https://pixel-boy.itch.io/ninja-adventure-asset-pack; its
  update 8: https://pixel-boy.itch.io/ninja-adventure-asset-pack/devlog/1462556/update-8-animation-v2-animals-camping-more
- The Mana Seed User License, Seliel the Shaper: https://selieltheshaper.weebly.com/user-license.html
- Hana Caraka, Otterisk: https://itch.io/c/3569702/hana-caraka-series,
  https://otterisk.itch.io/hana-caraka-base-character
- Sprout Lands, Cup Nooble: https://cupnooble.itch.io/sprout-lands-asset-pack

## 11. Phase A as built (2026-11-25): terrain and trees

**The pack.** "Ninja Adventure - Asset Pack.zip" (the page's update 8, dated 2026-03-29) was taken
from the page's free download on 2026-11-25: no payment, no account, no details given. 94.0 MB
zipped (SHA-256 `95a06f4f...df62a7b15`), 109.9 MB unpacked in 2,234 files, the largest 4.6 MB. Its
own `LICENSE.txt` is the text of CC0 1.0 Universal, and its `README.md` and the page say the same
words section 3.3 quotes. It lies untouched in `art/packs/ninja-adventure/`. Unpacked it is
over the 100 MB the user set as the limit, and 100.1 MB of that is its `Audio` folder, which this
game never uses, so phase A's commit left it out and asked. **The user's answer (2026-11-25):
"Yes, without audio".** It is committed without the `Audio` folder: 2,046 files, 9.9 MB, byte for
byte as downloaded; `.gitignore` leaves the audio out and `art/packs/README.md` says so. Nothing in
the pack looks copied from another game.

**What is the pack's now** (cut, moved, mirrored and recoloured by a one-off script kept out of
the project; no map, data or collision changed, and no tile changed place):

| Piece | From the pack | How it was fitted |
|---|---|---|
| Grass, and the same grass under props (atlas rows 0 and 8) | its flat grass (`TilesetFloor`) | the meadow is its green (`#74a334`), the second rise its yellow-green (`#adbc3a`), the first rise a blend of the two. One flat colour a tile, as the pack draws it: the texture is the details'. Heights 3 to 7, which no map uses, are its olive, mud and sands |
| Path (row 2) | its dirt, the tile with no edge | in its lighter dirt colours at every height |
| Stairs (row 1) | its steps (`TilesetReliefDetail`) | the clear corners filled with its own dark brown: a ground tile can't be see-through |
| Water (row 11, and the old water tile in row 3) | its water colour (`#71ddee`) | flat, all four frames alike: the surface's movement is the shader's. The pack's ripple is not used (one tile for every cell would repeat it) |
| Dungeon floor (4, 4) | its dark cobbles (`TilesetInteriorFloor`) | as drawn |
| Raised dungeon floor (row 10) | the same cobbles | each tone one step lighter, in the cobbles' own tones |
| The quarry's earth (row 25, columns 0 and 1) | its darker dirt | as drawn |
| The marsh's ground (row 23, columns 0 and 1) | its flat grass | in the darker green it uses for marks on grass (`#56864c`); see the gaps |
| The closed canopy of thick woods (2, 22) | the middle of its pine | a bough and a half, which has no outline |
| Trees (`scenery.png`) | its round tree, its large green tree, its pine, its large and small blossom trees, its tree on roots | **the pictures are 48x48 now (they were 32x40)**, in cells of 56x56, the trunk's foot at (24, 45): the pack's large trees fill a picture and its 32x32 trees stand at its foot, none shrunk. Broadleaf: the round tree. Oak: the large green tree. Cherry: the large blossom tree, and the small one as its second picture. Willow: the tree on roots, and the same mirrored |
| Ground details (`ground_details.png`, F6) | its floor marks, cross mark, mound, petals, pebbles and gravel | the same 26 frames in the same order, each in the pack's colours for its ground; no frame of the old sheet is kept |
| The ground's edges (`ground_edges.png`, new; F7) | its dirt-and-grass edge tiles, its water's bank, its rock face (`TilesetRelief`) | see below |

**F7, the edges, as built.** `HeightShading` still works out where grass meets a path, where water
meets land and where the ground drops, exactly as before (`find_ground_edges`, unchanged). What it
draws there is now a picture from `world/tiles/ground_edges.png`, laid out by `EdgeAtlas`:

- **Grass over a path:** the pack's own edge tile for the sides the grass is on (fifteen pieces: a
  side, a corner, a lane one cell wide, a dead end), with the dirt cut out so the path's tile shows
  under it, in the grass's colours at each height. **New:** where grass touches a path cell only
  at its corner, the pack's small corner piece is drawn (`find_corners`); the code drew nothing
  there before.
- **Water's bank:** a band of the pack's earth and a line of its foam, as thick at each step along
  the edge as in its straight edge tile, laid from the water cell's edge inwards (four pixels or
  five). The pack draws a strip of grass outside its bank, inside the water's tile; here the land
  beside water may be grass, marsh, boards or cave floor, so only the bank and the foam were
  taken. The water's moving foam now laps on from where the bank's picture ends
  (`WaterSurface.BANK`).
- **Cliff faces:** the foot of the pack's rock face, as many rows as the drop is tall (4, 8 or
  12); in dungeons the same in the cobbles' tones. The dark lip and the soft shadows are still
  drawn in code.

It needed no change to gameplay, maps or collisions, so the fallback (the code's edges, recoloured)
was not taken.

**In code:** `EdgeAtlas` (new, `world/tiles/`), `HeightShading` (draws the pieces;
`fringe_color()`, the face and bank colours and the code that drew blades and stripes are gone),
`GreyboxTiles.GROUND_COLORS` (the tiles' own colours now, a test holds it), `WaterSurface` (the
pack's water colours, and the foam past the bank), `SceneryAtlas` (the new picture size and foot)
and `Scenery.CROWN_TOP` (a taller crown). `art/sheets.json` lists 30 PNGs.

**Gaps: what the pack did not cover, or was left for a later phase.**

1. **The marsh.** The pack's swamp is brown mud with purple water. This game's marsh shares the
   one water tile with every pond, so the purple water can't be used without a new tile and a map
   change. The ground was kept green instead: the pack's flat grass in its own darker green. **The
   reeds, the boardwalks, the ruined hut, the cattails, moss, mossy stone and lantern posts are
   today's art.** The pack has plank decks, mossy ruins and tall grass that could serve some of
   them in phase B; it has no reeds or cattails by name.
2. **A willow.** The pack has none; its tree on roots stands in. It has one picture of each tree,
   so the second willow is the first mirrored.
3. **The quarry's walls, their faces, the outcrop, the mine's mouth and the ladder** are today's
   art (phase B, with the walls of `relief.png`). The pack has rock faces, a cave mouth and a
   ladder.
4. **The dungeons' walls, pillar and pits** are today's art (phase B). The pack lists no dungeon
   floor: the dark cobbles are one of its interior floors.
5. **The small decorations of row 6** (flowers, the tuft, pebbles, mushrooms, lily pads) and every
   prop are today's art (phase B).
6. **The first rise's grass** is a blend of the pack's two greens, not a colour of the pack.
7. **Details on raised grass** are lightened in code as before (`GroundDetail.tint_of`), so their
   marks are near the pack's olive, not exactly it.
8. **The title picture** is unchanged.

**What fits badly, said plainly.**

- **The mix is plain to see.** The pack's ground is flat colour with a few marks; today's houses,
  props, flowers and hero are shaded and textured. Side by side they look like two games until
  phases B to E.
- **The trees are outlined in near black and are shorter.** The round tree and the pine are 32
  pixels tall, as tall as today's hero; in the pack a person is 16. The large blossom and green
  trees (48) carry the village and the farm better.
- **The water is a bright cyan,** far brighter than the teal it replaces. It is the pack's colour.
  It is strongest in the marsh, where it is most of the picture.
- **The cobbled dungeon floor is busier** than the old flagstones, though monsters and chests
  still read on it.
- **The path is redder** than the honey-coloured path it replaces.
- **The marsh reads as a darker meadow** more than a bog: its mood came from the mossy ground and
  the dull water, and both are gone.

**Tests:** `tests/art/ground_edges_sheet_test.gd` (new: the sheet's layout, every fringe piece the
grass of its height along its sides, every bank piece earth and foam along its sides, the faces),
`tests/world/ground_edges_test.gd` (four more: a cell's sides gathered into one piece, corners of
grass and of bank, the village's corners), and four older art tests follow the pack: the grass and
the marsh are checked as flat colours and no longer for grain (`ground_tiles_test`), the dungeon
floor's plain colour is 100 pixels of 256 at the least (it was 151: cobbles are stone and mortar in
near equal parts), the details may also use the edge sheet's colours and three of the pack's
petal and pebble colours (`ground_details_sheet_test`), and the ground's colours in code are
checked against the tiles in place of the fringe's (`pixel_grade_test`).

**For the review:** the two answers taken as recommended (F6, F7); whether the marsh keeps its
green ground; and whether the ground and the trees sit well enough in this game to go on to
phase B. (The pack's place in git is settled: committed without its audio.)

## 12. Phase B as built (2026-11-26): buildings, interiors, props

**Approved on 2026-11-26** ("Approve phase B, go on to phase C"). Built in a session of its own on the user's word of 2026-11-25.
**F9 (what is drawn in code): taken as recommended; the user has not spoken to it; open at the
phase B review.** Chests, dungeon doors, signposts, pickups, pressure plates and push blocks are
drawn as before and are a gap. No colour in code was changed: no seam needed it.

**Art only.** No map was re-baked (`build_maps.gd` and `build_tileset.gd` were not run), no data,
story or collision changed, and every tile and frame is in its old place, at its old size. Eight
PNGs changed: `world/tiles/greybox_tiles.png` (phase B's rows), `world/tiles/relief.png`, and
`placed.png`, `crafted.png`, `rocks.png`, `breakables.png`, `forage.png` and `torch.png` in
`gameplay/art/`, each with its flash row made from the new frames' shape. One script did it all,
cutting, moving, mirroring and recolouring the pack's own pixels; it is kept with the session's
notes (`farm-look-phase-b/scripts/fit_phase_b.gd`), not in the project: the PNGs are the source.

**How each part was fitted:**

| Part | From the pack | How |
|---|---|---|
| Roofs: clay, thatch (rows 3, 7, 16 to 18) | the red-tiled house's roof; the thatched house's roof | each roof cut into a left gable, a middle and a right gable; the pack's 32 rows made 40 by laying plain rows twice (the clay's tiles repeat every eight rows, so its join is seamless). The first eight rows are the ridge strip (`relief.png`), the next sixteen the top row, the last sixteen the eave and the plain middle |
| Slate roof (`roof_blue`) | the clay roof | recoloured to the pack's teals |
| The coop's shingles, the big barn's green boards (rows 30 to 32) | the plank house's board roof | cut the same way; the green is the pack's dark greens |
| Ground-floor wall, window, door (rows 3, 4, 7) | the stone house's wall, the pack's lattice window, its arched wooden door | a plain stretch of the wall; the lattice laid on it; the door laid on it |
| Upper floor (row 18) | the thatched house's framed paper panels | the panel, and the panel with the lattice in it |
| The chapel (row 19) | the same wall | in the pack's grey stone; a lancet of two slits of the lattice; the pack's plank door and its mirror for a pair of leaves |
| Chimney, cross, shop sign, smoke (rows 20, 21) | the stone column's lip and shaft, the grave cross halved, the fruit shop's sign, two small puffs | the smoke one picture in all four frames: still |
| Wall faces and tops, pillar (`relief.png`) | the interior walls (`TilesetWallSimple`): plum stone (dungeons), timber (houses), moss green (the ruin); the stone column | the face's rows laid again to make 24 and 16; the top flat in the wall's darkest tone; the column's shaft shortened to 28 rows. The wall tiles under the relief are the top's colour |
| Floors and ways in (row 4) | dock planks (`TilesetWater`), a patterned floor (the rug), a woven mat, the stairs down, the pack's pit | the doormat on the planks; the pits made opaque |
| Furniture (rows 5, 15, 33) | its table, bed, shelf, barrel, clay oven (the hearth, with its own fire), chair, chest of drawers, a red table (the loom: a gap), plant, candles, counter, stool, bookcase, a crate of tools, a sack | each on the plank floor |
| Decorations (row 6) | its little red flowers (and the same in yellow and in blue), a grass tuft, pebbles, orange pebbles (mushrooms), leaves, the lily pad (its water cut out) | |
| Props (rows 3, 9, 13, 14) | its round bush (the old "tree" marker), grey rock, rail fence, the camp's stone ring with water in it (the well), crate, barrel (keg), hay bale, log pile, stump, lantern on a post (lamp), grave stone (standing stone), bucket, the stall's awning over its counter, washing on a line, the line's post | |
| The marsh (rows 23, 24) | dock planks (boardwalks, turned for the other way), tall grass (reeds), the mossy ruin's wall and roof, leaves (cattails), a leaf sprig (moss), a plank, a mossy stone, the lantern on its post (dark and burning), a hole | |
| The quarry (rows 25, 26) | the brown cliff's top and face, its cave mouth and ladder, its wooden ladder turned (rails), pebbles (rubble), a blue crystal plant (the vein), a standing plank (timber prop) | |
| The farm's buildings (rows 28, 29) | earth with its log pile (the site); the plank house's boards in red (the barn's wall), with the lattice (loft) and the plank door; the round vat (the silo) | |
| `placed.png` | its dirt, flagstones, planks (paths and floors), rail fence, round bush (hedge), a bench top, the lantern on its post (the lamp post, dark and burning), flowers (beds), sprouts and bushes (saplings; the cherry's in its blossom pinks); the hand as it was | the fence and gate cut into the unit, a rail and lengths of post, so `PlacedArt` joins them as before |
| `crafted.png` | a desk (workbench), the clay oven cold and burning (furnace), its small chest, its oil lamp, a mattress (the rug's two halves), a quilt (blanket); the sprinkler as it was | |
| `rocks.png` | its grey rock; its ore rock with the spots in each ore's colour (copper, coal, iron, gold, crystal); its ladder over its pit; its barred hatch (the lift); its large rocks (boulder) and a mossy stone (great boulder) | |
| `breakables.png` | grass, short grass (cut), its pot, branch, stump, leafy weeds, round bush, log | |
| `forage.png` | red flowers on leaves (berries; the marsh's in blue), leaves (picked), its tan mushroom (grey for the bog's), pebbles (picked), a white flower and its petals, tall leaves (cattails), a tuft (picked) | |
| `torch.png` | the dungeon's stone lamp, dark and lit, with two frames of the pack's fire particle over it | |

**Lit windows (point 4):** the lattice lies where `WindowGlow.GLASS` and `BUILDING_GLASS` light
it, so neither rectangle moved.

**Gaps: kept as they were, or with no fitting piece in the pack.**

1. **What is drawn in code** (F9): chests, dungeon doors, signposts, pickups, pressure plates,
   push blocks, a site's string and pegs.
2. **The sprinkler** (crafted) and **the hand** (placed): the pack has neither; today's art.
3. **A loom:** the pack has none; its red table stands in.
4. **A half-timbered house:** the pack has none. The houses are the pack's Japanese house parts
   (clay, thatch and board roofs, paper panels, a lattice window) in Hearthvale's shapes.
5. **A slate roof and a green-board roof:** the pack's clay and board roofs recoloured in its own
   teals and greens.
6. **Cattails and reeds** in the marsh: the pack has none by name; leaves and tall grass stand in.

**What fits badly, said plainly.**

- **The village is a Japanese village now, by its parts.** The roofs are the pack's rounded
  thatch and red clay tiles, the walls stone below and paper panels above. Built in this game's
  shapes (six cells wide, a gable at each end, a window every third cell) they read as long low
  houses of another country, not the half-timbered cottages of before. That is the pack.
- **Long roofs are flat.** The pack shades a roof only near its edges, so a six-cell roof is one
  orange or one teal across its middle.
- **The quarry's walls are a bright peach from above** (the top of the pack's brown cliff),
  where they were dark stone.
- **The fence is a short rail between posts;** where `PlacedArt` joins two, the rails meet in the
  middle of a cell, and a long fence is lighter than before.
- **Many props are a little smaller,** as the pack draws them inside a cell's middle.
- **The barn's wall and the silo** are the pack's boards in red and its round vat: they read as
  a barn and a silo only by their place on the farm.

**Tests:** none needed changing. The first run failed one: the clay and slate roofs' gable-end
ridge strips were under half painted (`buildings_test`), as the pack's clay roof has two empty rows
on top; the roof is now cut from its first painted row. Then the whole suite, 1259 cases, exit 0.

## 13. Phase C as built (2026-11-26): crops, soil, items, the UI

**Waiting for the user's review.** Built in a session of its own on the user's word of
2026-11-26 ("Approve phase B, go on to phase C"). **F8, decided by the user** from the same seven
screens in each look side by side (a mock-up of parchment, made for the picture and taken out
again): **"Dark wood, light text".** The boxes keep today's dark inside and light writing; the
font tool's theme and the menus' text colours did not change.

**Art only.** No map, data, story, timing or collision changed. Four PNGs changed, each at its
old size and with its frames in their old order: `gameplay/art/crops.png`, `soil.png` and
`items.png` (each with its flash row made from the new frames' shape) and `ui/art/ui_parts.png`.
One script did it all, cutting, moving, turning and recolouring the pack's own pixels; it is kept
with the session's notes (`farm-look-phase-c/scripts/fit_phase_c.gd`), not in the project.

**How each part was fitted:**

| Part | From the pack | How |
|---|---|---|
| Seeded, sprout, withered | its seed (`Items/Food/Seed1`), its seedling (`TilesetFloorDetail.png` (0, 2)) | the seedling browned in its twigs' colours for withered; each stood on the cell's foot |
| Turnip | a dark leafy rosette (`TilesetNature.png` (4, 11)); its white root with leaves (`SeedBig2`) | growing, ripe |
| Carrot | a ferny plant (9, 10); its orange root with leaves (`SeedBig1`) | |
| Wheat | a spiky tuft (7, 10); the same in its golds | |
| Potato | a round leafy plant (10, 10); its large seed (`SeedLarge`), which is potato-shaped | |
| Pumpkin | a green ball (10, 9); an orange one (9, 9) | |
| Soil | its dirt, the darker grass set's (`TilesetFloor.png`) | bare: plain (12, 8) and with a twig (11, 11); tilled and watered: the plain dirt one and three steps darker in its own browns, its dashes the furrows |
| Items | its `Items/` (food, tools, bars, gems, jars, seeds, bomb, key, coin, arrow, bow, swords, a pouch, scrolls), its hearts (`Ui/Receptacle/`), and from its tilesets the lantern, mushroom, blossom, crystal, hay and the cauldron | picked by meaning and centred; the bow turned upright; the tools' copper and iron tiers its tools with their heads in its bars' colours; the ores its rock in each ore's colour (not its ore rocks: an ore lying where a rock was would look like the rock); the seed packets its pouch with the crop's seed in front; jam its water jar in red; the marsh's berries and mushroom recoloured as phase B's forage; egg, wool and cloth recoloured from its pale seed, nut and scroll |
| The boxes' frame | its wood panel (`Ui/Theme/Theme Wood/nine_path_panel_2.png`) | cut into four corners of 5 and edges 5 deep and 6 long (`UiParts`); the sheet stays 104x32 |
| Colours in code (point 15) | its heart, slate, near black, grass green, gold, wood orange, inventory cell | `HeartsBar` (hearts), `EnergyBar` (bar, frame, bolt), `ItemBar` (slots; the build bar shares them), `PanelFrame` (the heading's rule and diamond), `FarmPlot.RIM` (the plot's rim) |

Which icon is which piece, in full: sword `Weapons/Sword2`; bow `Weapons/Bow` turned; arrows
`Projectile/Arrow`; bomb `Projectile/Bomb` (dim: its spark put out); key `Treasure/GoldKey`;
coin `Treasure/Coin2`'s first frame; heart `Ui/Receptacle/IconHeart`; heart container and piece
`Ui/Receptacle/Heart` full and a quarter; gem `Resource/GemGreen`; lantern the lantern of
`TilesetElement` (6, 3) (the miner's: its glass and glow in greys); iron sword `Weapons/BigSword`;
berries `Food/SeedBig3`; mushroom `TilesetElement` (1, 1); bread `Food/Sushi`; blossom
`TilesetFloorDetail` (2, 0); tea `Food/TeaLeaf` (ember tea: in its fire colours); hoe, watering
can and pickaxe `Tool/`; water `Resource/Water`; turnip, carrot, potato as the crops; wheat the
golden tuft; pumpkin `Object/Gourd`; roast turnip `Food/Yakitori`; soup `Food/Noodle`; stew and
marsh stew the cauldron of `tileset_camp` (6, 3) with a brown and a green stew; pie and shepherd's
pie `Object/CrateEmpty` (the second with a white top); jam `Potion/WaterPot` in red; cake
`Projectile/CrateDynamite`; stone `Resource/Rock`; crystal `TilesetNature` (1, 15); wood
`Resource/Branch`; the bars `Resource/Bar*`; fibre `Resource/Grass`; hay `TilesetElement` (12, 5)
(the silo's hay of phase B); kit `Scroll/ScrollEmpty`; egg `Food/SeedLargeWhite` in creams; wool
`Food/Nut` in white and grey; milk `Potion/MilkPot`; cloth `Scroll/Scroll` in blues; fried egg
`Food/Sushi2`; omelette `Food/FortuneCookie`; custard `Food/Honey`.

**Gaps: kept as they were, or with no fitting piece in the pack.**

1. **Crops.** The pack has none: its plants and roots stand in, one picture for growing and one
   for ripe, as before.
2. **Four icons** are today's art: the shuttle, the cattail root, the wisp ember and the
   sprinkler (as its picture on the ground, phase B).
3. **The clock's dial** is today's (PixelLab's colours); its hand is drawn in code as before.
4. **What is drawn in code** (F9): the hearts, the energy bar and the item bar's slots are still
   drawn in code, now in the pack's colours; the pack's own heart pictures are 16 wide, too large
   for the HUD's row of 9.

**What fits badly, said plainly.**

- **Growing crops are large and leafy,** as large as the field's weeds; they are told apart by
  the tilled soil under them and by being other plants of the pack's sheet.
- **Some icons are the pack's pieces read as another thing:** a fried egg is its egg sushi, the
  seed packets its money pouch with a seed in front, the kit its blank scroll, a cake its crate of
  dynamite (it reads as a cake), hay its straw square.
- **The potato is its large seed,** an orange almond shape; the carrot a round orange root.
- **The boxes' frame is thinner** (5 pixels, was 6 with gold caps): the pack's panel has no caps.
- **Tilled soil's furrows are fainter** than the old stripes: the pack's dirt has only short
  dashes. Watered soil is a dark grey-brown.
- **The item bar's slots are grey-green,** the pack's inventory cell, under a dark-wood HUD.

**Tests:** `tests/art/farm_look_ui_and_soil_test.gd` (new): the frame's pieces lie where
`UiParts` says, clear of the dial, its edges whole and outlined on the outside, the dial in
place; the soil darker as it is worked. `tests/ui/polish_test.gd`: a box too small for a frame
is now one smaller than two corners (6 by 6; the frame's corners are 5). Every other test stood.
