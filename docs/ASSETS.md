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
| `gameplay/art/items.png` | item icons | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/soil.png` | the plot's soil | code: `make_sprites.gd` | 2026-11-13 | Hearthvale's own |
| `gameplay/art/crops.png` | crops | code: `make_sprites.gd` | 2026-11-13 | Hearthvale's own |
| `gameplay/art/forage.png` | forage spots | code: `make_sprites.gd` | 2026-11-16 | Hearthvale's own |
| `gameplay/art/crystal.png` | crystal switches | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/dummy.png` | the training dummy | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/brambles.png` | brambles | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/rocks.png` | rocks, ladder, lift, boulders | code: `make_sprites.gd`; the boulder and the great boulder: PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1) | 2026-11-20 | Hearthvale's own; the two boulders PixelLab, free plan, made 2026-11-20: see "PixelLab" below |
| `gameplay/art/crafted.png` | furnishings | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/breakables.png` | grass, pots, wood, weeds, bushes, logs | code: `make_sprites.gd`; grass, cut grass, the stump and the bush: PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1) | 2026-11-20 | Hearthvale's own; those four PixelLab, free plan, made 2026-11-20: see "PixelLab" below |
| `gameplay/art/critters.png` | hens, butterflies | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/animals.png` | sheep, cows | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/torch.png` | torches | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/placed.png` | things set down on the homestead | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `world/tiles/greybox_tiles.png` | the tile atlas | code: `make_tile_texture.gd`; the two site tiles (row 28) edited by hand, the string and peg taken out (a script, the tool polish); the three flowers and the tuft (row 6) and the closed canopy (row 22): PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1); the roofs, walls, windows, door and chimney (rows 3, 4, 7, 16 to 18, 20, 30 and 31): redrawn by a script in the colours of PixelLab's `art/incoming/houses.png`, the roof surfaces new patterns, the rest the old shapes recoloured (step 2); the grass (heights 0 to 2), the path, the water, the dungeon stone (floor, walls, pillar, pits, ledges) and the marsh's ground warmed by role, every pixel of an old colour to its new one, in place, by a one-off script (warm-ground plan, step 1; the silo's grey kept); the grass and the solid grass (rows 0 and 8, all heights), the path (row 2), the dungeon floor (4, 4), the ledge (row 10), the marsh's ground and its solid twin (row 23, columns 0 and 1) and the quarry's earth and its solid twin (row 25, columns 0 and 1) given more grain in place: plain pixels turned to each tile's own shades and lights, no new colour, every height the same pattern, seamless (a one-off script, warm-ground plan, step 2) | 2026-11-25 | Hearthvale's own; those tiles PixelLab's colours and, for the five of step 1, its pictures (PixelLab, free plan, made 2026-11-20: see "PixelLab" below) |
| `world/tiles/scenery.png` | tall trees | PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1); the soft shadows kept from `make_scenery.gd` | 2026-11-20 | PixelLab, free plan, made 2026-11-20: see "PixelLab" below |
| `world/tiles/relief.png` | wall faces and tops, pillar, ridges | code: `make_relief.gd`; the red, blue, thatch and shingle ridges recoloured in `art/incoming/houses.png`'s colours (new-art plan, step 2); the dungeon stone's faces, top and pillar warmed to plum-grey with the atlas's stone, by a one-off script (warm-ground plan, step 1) | 2026-11-25 | Hearthvale's own; PixelLab, free plan, made 2026-11-20: see "PixelLab" below |
| `world/tiles/ground_details.png` | small still details on the ground: 26 frames of 16x16 (clover, daisies, buttercups, blades, sunlit and shaded patches, pebbles and a worn spot on grass; pebbles, ruts, a sprig, a sandy patch, a flat stone and specks on the path; a crack, moss and dust on the dungeon floor, a crack on the ledge; grit, crumbs and a crack in the quarry's earth; moss, a damp patch and a sprig in the marsh) | painted from ASCII by a one-off script (warm-ground plan, step 3; the script is not kept: the PNG is the source), every colour one of the atlas's own ground colours, the flowers its creams and yellows | 2026-11-25 | Hearthvale's own |
| `ui/title/backdrop.png` | the title screen's picture | code: `make_title.gd` | 2026-11-12 | Hearthvale's own |
| `ui/art/ui_parts.png` | the boxes' wooden frame (nine pieces) and the clock's dial | drawn by a script from PixelLab's `art/incoming/ui.png`: the frame's rows cut from its dialogue box, the gold caps, the dial's ring and face in its watch's colours (new-art plan, step 4) | 2026-11-20 | PixelLab, free plan, made 2026-11-20: see "PixelLab" below |

The dates are each PNG's last commit before the switch; the PNGs are the ones the tools baked at
the switch (each byte for byte what was in the repo).

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
| shadows, bursts, lights, water, mist, the hearts, the energy bar, the item bar's slots, the dial's hand and the rest drawn at runtime (since step 4 of the new art, in the colours of PixelLab's UI sheet) | the game's code | Hearthvale's own |

## Outside code

| What | Licence |
|---|---|
| gdUnit4 (`addons/gdUnit4/`, tests only, not shipped) | MIT |
| Godot Engine | MIT |
