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
| `gameplay/player/player_sheet.png` | the hero, 25 frames x 3 facings | code: `make_player_sprite.gd`; redrawn by a script in the look of PixelLab's `art/incoming/hero.png` (its colours, spiky hair, a deeper scarf), every pixel in its place (new-art plan, step 3) | 2026-11-20 | Hearthvale's own; PixelLab: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `gameplay/art/held_tools.png` | the tools in his hands | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/villager.png` | villagers (marker colours) | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/slime.png` | slime | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/wisp.png` | Bogwisp | code: `make_sprites.gd` | 2026-11-17 | Hearthvale's own |
| `gameplay/art/bat.png` | bat | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
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
| `gameplay/art/rocks.png` | rocks, ladder, lift, boulders | code: `make_sprites.gd`; the boulder and the great boulder: PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1) | 2026-11-20 | Hearthvale's own; the two boulders PixelLab: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `gameplay/art/crafted.png` | furnishings | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/breakables.png` | grass, pots, wood, weeds, bushes, logs | code: `make_sprites.gd`; grass, cut grass, the stump and the bush: PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1) | 2026-11-20 | Hearthvale's own; those four PixelLab: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `gameplay/art/critters.png` | hens, butterflies | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/animals.png` | sheep, cows | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/torch.png` | torches | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/placed.png` | things set down on the homestead | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `world/tiles/greybox_tiles.png` | the tile atlas | code: `make_tile_texture.gd`; the two site tiles (row 28) edited by hand, the string and peg taken out (a script, the tool polish); the three flowers and the tuft (row 6) and the closed canopy (row 22): PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1); the roofs, walls, windows, door and chimney (rows 3, 4, 7, 16 to 18, 20, 30 and 31): redrawn by a script in the colours of PixelLab's `art/incoming/houses.png`, the roof surfaces new patterns, the rest the old shapes recoloured (step 2) | 2026-11-20 | Hearthvale's own; those tiles PixelLab's colours and, for the five of step 1, its pictures: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `world/tiles/scenery.png` | tall trees | PixelLab (`art/incoming/nature.png`), fitted to size by a script (new-art plan, step 1); the soft shadows kept from `make_scenery.gd` | 2026-11-20 | PixelLab: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `world/tiles/relief.png` | wall faces and tops, pillar, ridges | code: `make_relief.gd`; the red, blue, thatch and shingle ridges recoloured in `art/incoming/houses.png`'s colours (new-art plan, step 2) | 2026-11-20 | Hearthvale's own; PixelLab: the user's plan, the date made and the terms on that date **not yet recorded** (asked 2026-11-20) |
| `ui/title/backdrop.png` | the title screen's picture | code: `make_title.gd` | 2026-11-12 | Hearthvale's own |

The dates are each PNG's last commit before the switch; the PNGs are the ones the tools baked at
the switch (each byte for byte what was in the repo).

## Made in code, and still made in code

| Asset | Made by | Terms |
|---|---|---|
| `ui/font/hearth_font.tres`, `ui/font/hearth_heading.tres`, `ui/theme.tres` | `tools/art/make_font.gd` | Hearthvale's own |
| `audio/sfx/*.wav`, `audio/music/*.wav` | `tools/audio/make_audio.gd` | Hearthvale's own |
| shadows, bursts, lights, water, mist, UI frames and the rest drawn at runtime | the game's code | Hearthvale's own |

## Outside code

| What | Licence |
|---|---|
| gdUnit4 (`addons/gdUnit4/`, tests only, not shipped) | MIT |
| Godot Engine | MIT |
