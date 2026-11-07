# M3 — Boat & sea map (plan)

Goal (ROADMAP M3): board and disembark, arcade sailing on deep tiles, and a small sea map linking
St. Aud, Spire Nine and Greenterrace.

## The gap in "moved to the nearest deep tile"
Drained St. Aud and dry Greenterrace have **no** deep tiles at all, so "nearest deep tile" has no
answer there, and a naive rule could strand the player for good. Resolution: every district has a
**Harbour** (a landing cell that is dry at every water level) and a **Mooring** (where the boat
comes in). When the water drops:
- if the district still has deep water, the boat moves to the nearest deep tile (rider and all);
- if it has none, the boat **waits at sea off the harbour**: a rider steps ashore where the boat
  was, and you board again by walking out from the Harbour.

Arriving from the sea works the same way: if the mooring is deep, you sail in aboard; otherwise the
boat waits outside and you come ashore at the Harbour.

## Design
- **`BoatMotor`** (`core/boat/`, pure): steer-toward-input arcade sailing. The boat turns toward the
  stick or keys at a fixed rate, thrusts along its heading, and sideways speed dies quickly (the
  drift). It floats only on deep cells; shores and shallows stop it, grid-checked like the player.
  Sailing off a district's edge goes to the sea.
- **`BoatRules`** (pure): whether a cell floats the boat, the nearest deep cell, where a rider can
  land (dry or shallow next to the boat, reachable on foot, preferring the cell ahead), and whether a
  player can board (same or neighbouring cell).
- **Player `on_boat` state** (TECH_DESIGN §4's state list): `board()` / `ride()` / `disembark()` on
  `PlayerMotor`. Movement input steers the boat instead; the rider is drawn head-and-shoulders.
- **Sea map** (`world/sea/sea.tscn`): a 48×30 greybox sea at a fixed water height, with three
  islands ringed by shallows. Each island has a **SeaPort**: sail into it to enter that district.
  Leaving a district by sea puts the boat back at that port's exit, heading away.
- **Districts:** Spire Nine (32×32, a terraced settlement on a spire, one fixed water level: it's
  added to the data as a single-level district with no network nodes) and Greenterrace (32×32,
  terraced rooftops; its levels are already in the data: dry = water 1, flooded = water 3). St. Aud
  gets a pier on its west edge for its Harbour.
- **Travel state lives in GameState:** `boat` = map it's on, cell, heading and the district it waits
  outside; `player` gains `on_boat`, `arriving` and `came_from`. Scenes are rebuilt from that on
  every load. Scene paths follow TECH_DESIGN §1: `world/districts/<id>/<id>.tscn`.
- Map layouts are baked by one generalised tool (`tools/greybox/build_maps.gd`), replacing
  `build_st_aud.gd`.

## Why the water matters to the boat (the acceptance test)
| District | Level | Boat |
|---|---|---|
| St. Aud | flooded (4) | sails streets, rubble and low roofs |
| St. Aud | waist (2) | streets only (rubble is shallow, low roofs are dry) |
| St. Aud | drained (0) | no deep water: waits at sea off the harbour |
| Greenterrace | flooded (3) | sails the streets |
| Greenterrace | dry (1) | streets are shallow: waits at sea off the harbour |

## Steps
1. Data: Spire Nine as a single-level district; update the tests that list district ids.
2. `BoatMotor`, `BoatRules`, `PlayerMotor` on-boat state, with unit tests.
3. Layouts and scenes: sea, Spire Nine, Greenterrace, plus St. Aud's pier. Add `SeaPort`,
   `HarbourMarker` and a Mooring marker.
4. `BoatController` + scene, `SeaController`, `DistrictController` (boarding, landing, harbour, edge
   exit, stranding), `PlayerController` rider visuals, and GameState travel helpers.
5. Tests: boat motor and rules; boat-reachable water per level from the real maps; sea connectivity
   between all three ports; travel round trips through the controllers (scene changes stubbed).
6. Visual check, docs.

## Acceptance criteria (from ROADMAP)
- [x] you can sail between all three
- [x] after a water change the boat can reach different places (or gets stranded and is moved to the
      nearest deep tile)

## Deliberately not in M3
Boat upgrades, deck map, crane, storage (M10); sea currents and weather; boat damage; NPCs in
Spire Nine; quest content; network nodes (M4).
