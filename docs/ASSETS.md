# Hearthvale's assets

Every art asset the game ships, where it came from and on what terms, so a release can be checked.
Since 2026-11-19 the art is PNG (`docs/progress/png-art-plan.md`): each PNG is its own source, edited
in Aseprite or replaced. **When you change or replace a picture, change its row here:** who made it
(you, or the tool), when, and, for AI-made art, the tool, your plan or tier, the date, and the tool's
licence terms on that date (a link, and a line quoting what matters: commercial use, attribution).

Until then every row reads: *made in code by Hearthvale's own tool, Hearthvale's own work*. The tools
painted each picture from ASCII art written for this game (no outside art) and are kept, retired, in
`tools/retired/` and in git history (the last commit that ran them: the switch to PNG, 2026-11-19).

## Art

| File | What it is | Made by | Date | Terms |
|---|---|---|---|---|
| `gameplay/player/player_sheet.png` | the hero, 25 frames x 3 facings | code: `make_player_sprite.gd`; redrawn by a script in the look of PixelLab's `art/incoming/hero.png` (its colours, spiky hair, a deeper scarf), every pixel in its place (new-art plan, step 3) | 2026-11-20 | Hearthvale's own; PixelLab, free plan, made 2026-11-20: see "PixelLab" below |
| `gameplay/art/held_tools.png` | the tools in his hands | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/villager.png` | villagers (marker colours) | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/slime.png` | slime | the user's art from PixelLab (`art/incoming/slime.png`, three frames of 256x256 brought 2026-11-23), fitted to 16x16 by a script: shrunk to about a fifth by the colour covering most of each pixel, its own colours, its outline, a pixel for each eye, the white flash row added | 2026-11-23 | PixelLab, made 2026-11-23: see "PixelLab" below |
| `gameplay/art/wisp.png` | Bogwisp | code: `make_sprites.gd` | 2026-11-17 | Hearthvale's own |
| `gameplay/art/bat.png` | bat | the user's art from PixelLab (`art/incoming/bat.png`, three frames of 256x256 brought 2026-11-23), fitted to 16x16 by a script as the slime was, its face's colour and a pixel for each eye kept | 2026-11-23 | PixelLab, made 2026-11-23: see "PixelLab" below |
| `gameplay/art/goblin.png` | goblin archer | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/warden.png` | the Iron Warden | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/shade.png` | the Crypt Shade | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/items.png` | item icons | **Ninja Adventure since 2026-11-26** (farm-look plan, phase C): 70 of the 74 icons are its items (`Items/`: food, tools, bars, gems, jars, seeds, the bomb, key, coin, arrow, bow and swords), its hearts (`Ui/Receptacle/`) and pieces of its tilesets (the lantern, mushroom, blossom, crystal, hay, the cauldron for the stews), picked by meaning, centred, some turned or recoloured (the copper and iron tools in its bars' colours, the ores its rock in each ore's colour, the seed packets its pouch with a seed in front) by a one-off script (the plan's section 13 says which is which); **the shuttle, the cattail root, the wisp ember and the sprinkler are still `make_sprites.gd`'s** (Hearthvale's own: the pack has nothing like them) | 2026-11-26 | CC0 (the four kept Hearthvale's own): see "Ninja Adventure" below |
| `gameplay/art/soil.png` | the plot's soil | **Ninja Adventure since 2026-11-26** (farm-look plan, phase C): its dirt (`TilesetFloor.png`, the darker grass set's): bare plain and with a twig; tilled and watered the same dirt one and three steps darker in its own browns, its dashes the furrows, by a one-off script | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/crops.png` | crops | **Ninja Adventure since 2026-11-26** (farm-look plan, phase C): the pack has no crops, so its plants and roots stand in: a seed (`Items/Food/Seed1`), a seedling (`TilesetFloorDetail.png`) and the same browned (withered), and for each crop a plant of `TilesetNature.png` growing and its root or fruit ripe (turnip and carrot its two roots with leaves, potato its large seed, wheat a spiky tuft and the same in gold, pumpkin a green ball and an orange one), each stood on the cell's foot by a one-off script | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/forage.png` | forage spots | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): its flowers, leaves, mushroom, pebbles, petals and tall leaves, cut and recoloured by a one-off script; until then `make_sprites.gd` | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/crystal.png` | crystal switches | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/dummy.png` | the training dummy | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/brambles.png` | brambles | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/rocks.png` | rocks, ladder, lift, boulders | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): its grey rock, its ore rock with its spots in each ore's colour, its ladder over its pit, its barred hatch, its large rock and a mossy stone, cut and recoloured by a one-off script; until then `make_sprites.gd` and two PixelLab boulders | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/crafted.png` | furnishings | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): its desk, clay oven (cold and burning), small chest, oil lamp, mattress and quilt, cut by a one-off script; **the sprinkler is still `make_sprites.gd`'s** (Hearthvale's own) | 2026-11-26 | CC0 (the sprinkler Hearthvale's own): see "Ninja Adventure" below |
| `gameplay/art/breakables.png` | grass, pots, wood, weeds, bushes, logs | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): its grass, short grass, pot, branch, stump, leafy weeds, bush and log, cut by a one-off script; until then `make_sprites.gd` and four PixelLab pictures | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/critters.png` | hens, butterflies | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/animals.png` | sheep, cows | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/torch.png` | torches | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): the dungeon's stone lamp with two frames of its fire particle, by a one-off script; until then `make_sprites.gd` | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `gameplay/art/placed.png` | things set down on the homestead | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): its dirt, flagstones, planks, rail fence (cut into unit, rail and posts), bush, bench, lantern post, flowers and sprouts, cut and recoloured by a one-off script; **the hand is still `make_sprites.gd`'s** (Hearthvale's own) | 2026-11-26 | CC0 (the hand Hearthvale's own): see "Ninja Adventure" below |
| `world/tiles/greybox_tiles.png` | the tile atlas | code: `make_tile_texture.gd`; the two site tiles (row 28) edited by hand, the string and peg taken out (a script, the tool polish); the three flowers and the tuft (row 6) and the closed canopy (row 22): PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1); the roofs, walls, windows, door and chimney (rows 3, 4, 7, 16 to 18, 20, 30 and 31): redrawn by a script in the colours of PixelLab's `art/incoming/houses.png`, the roof surfaces new patterns, the rest the old shapes recoloured (step 2); the grass (heights 0 to 2), the path, the water, the dungeon stone (floor, walls, pillar, pits, ledges) and the marsh's ground warmed by role, every pixel of an old colour to its new one, in place, by a one-off script (warm-ground plan, step 1; the silo's grey kept); the grass and the solid grass (rows 0 and 8, all heights), the path (row 2), the dungeon floor (4, 4), the ledge (row 10), the marsh's ground and its solid twin (row 23, columns 0 and 1) and the quarry's earth and its solid twin (row 25, columns 0 and 1) given more grain in place: plain pixels turned to each tile's own shades and lights, no new colour, every height the same pattern, seamless (a one-off script, warm-ground plan, step 2). **Since the farm-look plan's phase A (2026-11-25) the ground tiles are Ninja Adventure's,** each in its old place, cut and recoloured by a one-off script: the grass and the solid grass (rows 0 and 8: its flat green, its yellow-green, a blend between; heights 3 to 7 its olive, mud and sands), the path (row 2: its dirt), the stairs (row 1: its steps), the water (row 11 and the tile at (5, 3): its water's colour), the dungeon floor (4, 4) and the ledge (row 10: its dark cobbles, the ledge a step lighter), the quarry's earth and its solid twin (row 25, columns 0 and 1: its darker dirt), the marsh's ground and its solid twin (row 23, columns 0 and 1: its flat grass in its darker green) and the closed canopy (2, 22: the middle of its pine). **Since phase B (2026-11-26) the houses, roofs and walls, the farm's buildings, the floors and ways in, the furniture, the decorations and props, the marsh's and the quarry's pieces are Ninja Adventure's too** (rows 3 to 7, 9, 13 to 21, 23 and 24 but the marsh's ground, 25 and 26 but the quarry's earth, 28 to 33), each in its old place, cut, moved, mirrored and recoloured by a one-off script (the plan's section 12 says from what). The marker rows 12 and 27 are as they were | 2026-11-26 | Hearthvale's own; PixelLab's colours and pictures as above (PixelLab, free plan, made 2026-11-20: see "PixelLab" below); the ground tiles and phase B's tiles CC0: see "Ninja Adventure" below |
| `world/tiles/scenery.png` | tall trees: seven pictures of 48x48 | **Ninja Adventure** (`TilesetNature.png`), cut and placed by a one-off script (farm-look plan, phase A): its round tree, its large green tree, its pine, its large and its small blossom tree, its tree on roots and the same mirrored; none shrunk, none recoloured | 2026-11-25 | CC0: see "Ninja Adventure" below |
| `world/tiles/relief.png` | wall faces and tops, pillar, ridges | **Ninja Adventure since 2026-11-26** (farm-look plan, phase B): the faces and tops from its interior walls (plum stone, timber, moss green), the pillar from its stone column, the ridges the first rows of its roofs, by a one-off script; until then `make_relief.gd` and PixelLab's colours | 2026-11-26 | CC0: see "Ninja Adventure" below |
| `world/tiles/ground_details.png` | small still details on the ground: 26 frames of 16x16, in the order of `art/sheets.json` (ten for grass, six for the path, four for the dungeon floor and the ledge, three for the quarry's earth, three for the marsh) | **Ninja Adventure**, cut and recoloured by a one-off script (farm-look plan, phase A): its four floor marks, its cross mark and its mound (`TilesetFloor.png`), its petals, pebbles and gravel (`TilesetFloorDetail.png`), each in the pack's colours for the ground it lies on; no frame of the earlier sheet is kept | 2026-11-25 | CC0: see "Ninja Adventure" below |
| `world/tiles/ground_edges.png` | the ground's edges: grass lapping over a path (eight heights, fifteen pieces for the sides and four for corners), the water's bank (the same nineteen), a cliff's face in earth and in cut stone | **Ninja Adventure**, cut and recoloured by a one-off script (farm-look plan, phase A): the edge tiles of its dirt with the dirt cut out (`TilesetFloor.png`), in the grass's colour at each height; the earth and the foam of its water's bank (`TilesetWater.png`), laid from the cell's edge inwards as thick as in its straight edge tile; the foot of its rock face (`TilesetRelief.png`), and the same in its cobbles' tones | 2026-11-25 | CC0: see "Ninja Adventure" below |
| `ui/title/backdrop.png` | the title screen's picture | code: `make_title.gd` | 2026-11-12 | Hearthvale's own |
| `ui/art/ui_parts.png` | the boxes' wooden frame (nine pieces) and the clock's dial | **the frame is Ninja Adventure's since 2026-11-26** (farm-look plan, phase C): its wood panel (`Ui/Theme/Theme Wood/nine_path_panel_2.png`) cut into four corners of 5 and four edges 5 deep by a one-off script; **the dial is still the one drawn by a script from PixelLab's `art/incoming/ui.png`** (new-art plan, step 4: the pack has no dial) | 2026-11-26 | the frame CC0 (see "Ninja Adventure" below); the dial PixelLab, free plan, made 2026-11-20: see "PixelLab" below |

The dates are each PNG's last commit before the switch; the PNGs are the ones the tools baked at
the switch (each byte for byte what was in the repo).

## Ninja Adventure

**"Ninja Adventure - Asset Pack"**, by **Pixel-Boy and AAA**
(https://pixel-boy.itch.io/ninja-adventure-asset-pack). The user chose it on 2026-11-25
(`docs/progress/farm-look-plan.md`).

- **Licence: CC0 1.0 Universal** (https://creativecommons.org/publicdomain/zero/1.0/). The pack's
  own `LICENSE.txt` is the text of CC0 1.0, and its `README.md` and its page say: "They are released
  under the Creative Commons Zero (CC0) license. You can use any and all of the assets found in this
  package in your own games, even commercial ones. Attribution is not required but appreciated."
  Read on the page and in the zip on 2026-11-25.
- **Credit:** none is needed. A link to the page is asked for kindly ("Placing a link to this
  itchio page somewhere would be awesome"): the game's credits should name Pixel-Boy and AAA and the
  page.
- **Downloaded:** 2026-11-25, the page's free download ("Ninja Adventure - Asset Pack.zip", the
  pack's update 8 of 2026-03-29; 94,022,790 bytes; SHA-256
  `95a06f4fdcfd1882f061a45ff313b7c905dbe2de1e8512b281d7937df62a7b15`). Nothing was paid and no
  account or details were given.
- **Where it is:** untouched in `art/packs/ninja-adventure/` (Godot ignores `art/`), with its
  `LICENSE.txt`. **Committed without its `Audio` folder** (the user's word, 2026-11-25: "Yes,
  without audio"): 2,046 files, 9.9 MB, byte for byte as downloaded (`.gitattributes` keeps git
  from converting line endings there). The `Audio` folder (188 files, 100.1 MB of the pack's
  109.9 MB) is left out by `.gitignore`: its music and sound are never used, this game makes its
  own. `art/packs/README.md` says so beside the pack.
- **What came from it:** the ground tiles of `world/tiles/greybox_tiles.png` named in its row,
  `world/tiles/scenery.png`, `world/tiles/ground_details.png` and `world/tiles/ground_edges.png`
  (farm-look plan, phase A); and since phase B (2026-11-26) the buildings, interiors and props of
  `greybox_tiles.png`, `world/tiles/relief.png`, and `placed.png` (but the hand), `crafted.png`
  (but the sprinkler), `rocks.png`, `breakables.png`, `forage.png` and `torch.png` in
  `gameplay/art/`. Each was fitted by a script that cuts, moves, mirrors and recolours;
  nothing was generated from it, and nothing was drawn anew in its style.

## PixelLab

The four sheets in `art/incoming/` (`nature.png`, `houses.png`, `hero.png`, `ui.png`) were made by the
user with PixelLab (pixellab.ai) on its **free plan**, on **2026-11-20** (the downloads' own names carry
the time). PixelLab's Terms of Service, as they stood on that date (https://www.pixellab.ai/termsofservice,
"Last Updated: 2026-10-30"), make no difference between plans:
- 1.3: "You own the copyrights to your creations, permitting usage for both commercial and non-commercial
  purposes with no need for permission."
- 3.3: the user keeps ownership and may use, modify and distribute the outputs for any purpose but
  training other models, and is responsible for them not infringing anyone's rights.
- 4.1: use must also follow the Open RAIL-M licence (its use restrictions).
- No attribution is asked for.

Two more, `art/incoming/slime.png` and `bat.png`, were made by the user with PixelLab on **2026-11-23**,
at 10:24 and 10:29 (the user's word). The terms above are as they were read on 2026-11-20; they were
not read again for these two.

Every PNG that holds PixelLab's pictures, or is drawn in their colours, says so in its row above.

## Made in code, and still made in code

| Asset | Made by | Terms |
|---|---|---|
| `ui/font/hearth_font.tres`, `ui/font/hearth_heading.tres`, `ui/theme.tres` | `tools/art/make_font.gd` | Hearthvale's own |
| `audio/sfx/*.wav`, `audio/music/*.wav` | `tools/audio/make_audio.gd` | Hearthvale's own |
| shadows, bursts, lights, water, mist, the hearts, the energy bar, the item bar's slots, the dial's hand and the rest drawn at runtime (since step 4 of the new art, in the colours of PixelLab's UI sheet; since the farm-look plan's phase A the water's glints, foam and swell are in Ninja Adventure's water colours, and the grass's fringe, the bank and the cliff faces are no longer drawn in code: they are `world/tiles/ground_edges.png`) | the game's code | Hearthvale's own |

## Outside code

| What | Licence |
|---|---|
| gdUnit4 (`addons/gdUnit4/`, tests only, not shipped) | MIT |
| Godot Engine | MIT |
