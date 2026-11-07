# M4 — Network Key & consequence preview (plan)

Goal (ROADMAP M4): an interactable pump node. Repairing it requires an item; using it opens a
preview (mini-map highlights of every district that changes, plus text) and then applies.

## Design
- **Pump in the world:** a `NetworkNodeMarker` for `st_aud_pump` on St. Aud's lookout tower,
  reachable at every water level. Its behaviour comes from data (`data/water/spillway.json`: district,
  target, `repair_requires`).
- **Repair:** `repair_requires` uses the shared condition vocabulary, so M4 adds a pure
  `ConditionEvaluator` (`core/quests/`, TECH_DESIGN §1). It covers the whole vocabulary, since the data
  can already contain any of it, evaluated against a GameState snapshot. `GameState.repair_network_node()`
  checks the conditions, **uses up** the items they ask for (the valve is fitted), marks the node repaired
  and emits `EventBus.network_node_repaired`. Unmet requirements are named in the message ("needs: Pump
  Valve").
- **Getting the valve:** an `ItemPickup` on Spire Nine's platform. Inventory already persists in
  GameState across maps; the HUD gains a "Carrying" line.
- **Network Key:** the player always has it (GDD: inherited). It isn't an inventory item yet.
- **Preview** (`ui/network_panel`): opens when you use a repaired node. Up/Down picks *Raise* or *Lower*
  (Lower first). It shows `WaterSolver.preview()` as text and on a **region mini-map** (`RegionMap`): a box
  per district and basin, each with a water gauge (before → after) and a level label, the network's pipes
  as lines, and the node in use drawn as an arrow in the direction of flow. Districts that change are
  outlined amber; ones whose level rises are outlined red. A rejection shows its reason and can't be
  confirmed. E confirms through `GameState.apply_water_change()`; Esc cancels. The game pauses while it's
  open.
- **Mini-map layout is data:** optional `"map": [x, y]` on districts and basins (validated by
  DataRegistry, added to the schema), so other regions lay out the same way.

## Acceptance flow (tested end to end)
1. Pump broken, no valve: using it says it needs a Pump Valve and stays broken.
2. With the valve: using it repairs it and uses up the valve.
3. Use it again: the preview for Lower says *St. Aud Hospital: flooded -> waist* and *Greenterrace: water
   rising, 50 of 100*. Confirm.
4. Use it again: the preview now warns *Greenterrace: dry -> flooded*, with Greenterrace outlined red on the
   mini-map. Confirm, and Greenterrace is flooded.
5. Load Greenterrace: its streets are deep water (visibly flooded), and the boat can sail in.

## Acceptance criteria (from ROADMAP)
- [x] draining St. Aud from the pump visibly floods Greenterrace and the preview warned about it first

## Deliberately not in M4
The third outlet in the world and its tunnel (M9), effects/quest runner (M9), a Network Key item or
upgrades, animated water transitions, sound.
