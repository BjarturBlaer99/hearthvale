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
| `gameplay/player/player_sheet.png` | the hero, 25 frames x 3 facings | code: `make_player_sprite.gd` | 2026-11-19 | Hearthvale's own |
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
| `gameplay/art/rocks.png` | rocks, ladder, lift, boulders | code: `make_sprites.gd` | 2026-11-18 | Hearthvale's own |
| `gameplay/art/crafted.png` | furnishings | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/breakables.png` | grass, pots, wood, weeds, bushes, logs | code: `make_sprites.gd` | 2026-11-18 | Hearthvale's own |
| `gameplay/art/critters.png` | hens, butterflies | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/animals.png` | sheep, cows | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `gameplay/art/torch.png` | torches | code: `make_sprites.gd` | 2026-11-12 | Hearthvale's own |
| `gameplay/art/placed.png` | things set down on the homestead | code: `make_sprites.gd` | 2026-11-19 | Hearthvale's own |
| `world/tiles/greybox_tiles.png` | the tile atlas | code: `make_tile_texture.gd`; the two site tiles (row 28) edited by hand, the string and peg taken out (a script, the tool polish) | 2026-11-19 | Hearthvale's own |
| `world/tiles/scenery.png` | tall trees | code: `make_scenery.gd` | 2026-11-16 | Hearthvale's own |
| `world/tiles/relief.png` | wall faces and tops, pillar, ridges | code: `make_relief.gd` | 2026-11-19 | Hearthvale's own |
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
