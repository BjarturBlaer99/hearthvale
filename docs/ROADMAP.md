# Low Tide — Roadmap

Goal: a **vertical slice** of one region, *The Spillway*, that proves the core idea: changing water
levels changes the map and every change has a cost. Everything uses placeholder art (flat-colored tiles).

**Slice content**: Spire Nine (settlement), St. Aud Hospital district (3 water levels: flooded / waist / drained),
Greenterrace (farming rooftops, 2 levels: dry / flooded), Old Reservoir (empty basin), a small sea map joining them,
the maintenance tunnel, the quest *Bitter Medicine* with all 4 resolutions, 2 factions present (Reclamation, Summit Holds), 1 companion.

Work milestones in order. Stop after each and report against its acceptance criteria.

---

## M0 — Project skeleton
- Godot project set up for 2D pixel art (480×270 base, integer scaling, nearest filter), folder layout from TECH_DESIGN §1, gdUnit4 installed, autoload stubs.
- `DataRegistry` loads JSON from `res://data` and validates required fields.
- A test that passes; a test scene that loads.
**Done when**: headless test command runs green; `godot --path .` opens a test scene; `docs/progress/LOG.md` exists.

## M1 — Water & terrain logic (no visuals)
- `WaterNetwork`, `WaterSolver`, `WaterChangeResult` (TECH_DESIGN §3.1) loaded from `data/water/spillway.json`.
- `HeightGrid`, `TerrainQuery` and the movement rules (TECH_DESIGN §3.2, §3.4).
- `GameState` holds water levels; `EventBus.water_level_changed` fires on apply.
**Done when**: tests cover conservation, cascade into Greenterrace, basin capacity, rejection with reason, preview equals apply, dry/shallow/deep classification per level, climb/drop/ramp rules, and save/load round trip of water state.

## M2 — Player & district greybox
- Top-down player: 8-direction move, sprint, climb (stamina), drop down, wade, swim. Camera2D follow with limits. Keyboard + gamepad.
- Greybox St. Aud district (~64×64 tiles, flat colors by height) with a `Height` layer; `Water` layer redraws from water height; debug key cycles water levels.
**Done when**: each water level changes where you can walk; something is reachable only at specific levels (a rooftop door reachable by swimming only when flooded; a subway entrance only when drained); state survives level changes.

## M3 — Boat & sea map
- Board/disembark, arcade sailing on deep tiles, small sea map linking St. Aud, Spire Nine and Greenterrace.
**Done when**: you can sail between all three; after a water change the boat can reach different places (or gets stranded and is moved to the nearest deep tile).

## M4 — Network Key & consequence preview
- Interactable pump node; repairing it requires an item; using it opens a preview (mini-map highlights of every district that changes + text) and then applies.
**Done when**: draining St. Aud from the pump visibly floods Greenterrace and the preview warned about it first.

## M5 — Diving & interiors
- Dive points load an underwater interior with an oxygen timer; the same interior loads dry when St. Aud is drained.
**Done when**: the hospital's ground floor can be explored both ways and loot/flags persist between them.

## M6 — Winch
- `WinchTarget` with the four modes (pull_to_player, pull_player_to, drag, bridge).
- One puzzle room per mode in the greybox.
**Done when**: each mode works with keyboard/mouse and gamepad; at least one puzzle can be solved two different ways.

## M7 — Combat
- Health, hitboxes, stagger, dodge. One melee weapon (arc swing), one scavenged firearm (projectiles), winch stagger.
- Two enemy types: drowned-scavenger (land) and lurker (water creature; trapped in pits when drained).
**Done when**: enemies patrol/chase/attack with AStarGrid2D at every water level and respect land/water rules; player can die and respawn at last save.

## M8 — Dialogue, attributes, factions
- DialogueRunner + UI, attributes (Grit, Wits, Charm, Tech), visible checks, reputation for Reclamation and Summit Holds, one following companion with approval.
**Done when**: data-only dialogue with a check, a reputation effect and a companion reaction plays end-to-end.

## M9 — Quest: Bitter Medicine
- QuestRunner + journal UI. Implement the quest from GDD §9 purely in data (plus any new condition/effect *types* needed).
- Maintenance tunnel greybox (winch puzzles + combat) → repairing the third outlet routes water to Old Reservoir.
**Done when**: all 4 resolutions are completable in play, each sets different world state (settlement NPCs, reputation, water), and a test verifies each path is reachable.

## M10 — Boat home & save
- Walkable boat deck map with storage, one crafting station and a companion berth. Save/load from a menu at any time.
**Done when**: a save made mid-quest reloads to identical world state (water, flags, quest, inventory, reputation, boat, player position and height).

## M11 — Slice polish & playtest
- Main menu, pause, basic settings, onboarding hints, end-of-slice screen with the first sabotage clue.
- Fix top issues from `LOG.md`.
**Done when**: a new player can complete the slice in 30–60 min with no developer help.

---

## After the slice (not now)
Glider, mutations, more districts and factions, Keepers storyline, real pixel art and audio, animated water edges, world streaming.
