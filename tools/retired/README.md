# Retired art tools

These painted Hearthvale's art from ASCII until 2026-11-19, when the art became PNG
(`docs/progress/png-art-plan.md`). Each wrote one or more PNGs, which are now the source:

| Tool | Painted |
|---|---|
| `make_player_sprite.gd` | `gameplay/player/player_sheet.png` |
| `make_sprites.gd` | every sheet in `gameplay/art/` |
| `make_scenery.gd` | `world/tiles/scenery.png` |
| `make_relief.gd` | `world/tiles/relief.png` |
| `make_title.gd` | `ui/title/backdrop.png` |
| `make_tile_texture.gd` | `world/tiles/greybox_tiles.png` |
| `pixel_grade_bake.gd` | the warm grade and soft outlines every tool applied as it baked (the old `PixelGrade`) |

They are kept as a record of how each picture was drawn. **Never run them:** they would paint over
the PNGs, and they are out of date the moment a PNG is edited. Godot ignores this folder
(`.gdignore`), so it neither compiles them nor can run them; to read one, open it as text. The last
commit that ran them is in git history (the switch to PNG).

Still made in code, and not here: the fonts (`tools/art/make_font.gd`) and the sound
(`tools/audio/make_audio.gd`). Map work keeps going without painting: `tools/greybox/build_tileset.gd`
reads the tile atlas PNG, and `build_maps.gd` bakes the maps.
