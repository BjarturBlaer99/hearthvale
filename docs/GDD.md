# Low Tide — Game Design Document

## 1. Pitch
A **2D top-down** open-world RPG that combines Fallout-style factions and consequential choices with
Zelda-style exploration (think *A Link to the Past*), puzzles and multi-use tools. A century after a
catastrophic flood, people live on skyscrapers, mountain peaks and rusting ships. You inherit a battered
boat and a device that controls parts of the old flood-management network. **Changing the water level changes the map.**

## 2. Design pillars
1. **The water is the world.** Every tile has a height. Lower the water and rooftops become streets, shallows become paths, and drowned interiors open up. Raise it and new sea routes appear.
2. **Every lever has a cost.** Moving water helps someone and hurts someone else. The player sees the consequence on the map before committing.
3. **Tools, not keys.** Tools have several systemic uses (pull, move, bridge, stun). Puzzles have more than one solution.
4. **Real role-play.** Dialogue checks, companions with opinions, factions that remember, and quests with at least three resolutions (side A, side B, clever third path).

## 3. Core loop
Sail → discover a district → explore it at its current water height → find a network node / problem →
talk to affected people → preview and choose how to change the water (or not) → explore the changed map →
face consequences (reputation, settlement changes, new quests) → upgrade boat/character → sail on.

## 4. World
- **View**: top-down, square tiles, camera follows the player. The world is split into **districts** (one map each) joined by open sea the boat crosses.
- **Height**: every tile has a terrain height (0 = old street level, higher = buildings, cliffs, towers). Shading and outlines make height readable.
- **Water**: each district has 2–4 named **water levels** (e.g. *Flooded*, *Waist-deep*, *Drained*), each a water height. Compared with a tile's height, that gives:
  - **dry** — walkable land
  - **shallow** (1 below water) — wade slowly; small boats can't enter
  - **deep** (2+ below water) — swim or sail; dive points lead into submerged interiors
- **Settlements**: on rooftops, peaks and moored ships. Each belongs to a faction and has needs (food, medicine, power, dry land).
- **The Flood Network**: pumps, sluice gates, outlets and reservoirs linked by pipes. Water drained from one district goes somewhere — conservation drives the consequence system.
- **Traversal**:
  - Sailing between districts and through deep water.
  - **Climbing** up ledges, ladders and vine-covered walls to higher tiles (costs stamina). Dropping down is free.
  - **Gliding** (mid-game): jump off a high tile and travel further the higher you start.
  - **Diving** at dive points into separate underwater interior maps (oxygen timer). Draining the district turns some of these into normal dry interiors.

## 5. Player tools
| Tool | Uses |
|---|---|
| **Network Key** (the inherited device) | Interfaces with network nodes; raise/lower a district by one step if the node is repaired and accessible |
| **Magnetic Winch** | Fired in the aim direction. Pull enemies off balance; drag heavy machinery along rails; pull debris into gaps to make bridges; reel yourself to metal anchors across water or gaps |
| **Glider** (mid-game) | Cross gaps from high tiles |
| **Rebreather** (upgradeable) | Longer dives |
Further tools are out of scope for the vertical slice.

## 6. Combat & builds
Real-time top-down action (8-direction movement, aim with mouse or right stick). Four overlapping specializations, raised through use-based perks:
- **Scavenger** — scavenged firearms, ammo crafting, aim perks
- **Brawler** — melee weapons, stagger, dodge, stamina
- **Engineer** — turrets, traps, better winch, network hacking
- **Mutant** — biological mutations from deep-water samples: gills, regeneration, bio-shock; each has a visible social cost (some NPCs distrust you)
Water matters in fights: enemies in shallows are slowed, deep water blocks land enemies, and some creatures only hunt in water. The winch must be useful in every build.

## 7. Role-playing systems
- **Attributes** (used for dialogue/skill checks): Grit, Wits, Charm, Tech. Checks are visible to the player with the required value.
- **Factions** with reputation (-100..100):
  - **The Moorings** — ship-cities that control trade; their economy depends on high water.
  - **The Reclamation** — engineers who want to drain everything and rebuild on land.
  - **Summit Holds** — mountain farmers; isolationist, vulnerable to flooding below.
  - **The Keepers** — hidden; secretly maintain high water (central mystery). Not met openly until late game.
- **Companions**: follow the player on the map, each has a faction leaning, approves/disapproves of choices, has a personal quest, and can leave.
- **Quests**: data-driven, multi-path, with world-state consequences (see TECH_DESIGN §5).

## 8. Progression
- Character: attributes, specialization perks, mutations.
- **Boat as home**: hull (durability), engine (speed / current resistance), storage, crafting stations (workbench, lab, galley), companion berths, crane (uses winch tech). The boat deck is a small walkable map.
- Network: repairing nodes unlocks more control over the world.

## 9. Example quest — "Bitter Medicine" (vertical slice centerpiece)
The settlement **Spire Nine** has a fever outbreak. Medicine is in the drowned **St. Aud Hospital**.
Draining the hospital district via its pump station pushes water into **Greenterrace**, a farming community on terraced rooftops.

Resolutions:
1. **Drain anyway** — Spire Nine saved; Greenterrace floods; Summit Holds rep down, Reclamation up; Greenterrace refugees appear at Spire Nine.
2. **Refuse** — find a partial medicine cache by diving (hard, partial cure); Spire Nine loses people; Summit Holds rep up.
3. **Negotiate an evacuation** (Charm check, or bring supplies) — Greenterrace moves first, then drain; costs time and resources; both settlements survive but Greenterrace is changed.
4. **Repair the third outlet** — dangerous maintenance tunnel (winch puzzles, combat); diverts water to an empty reservoir; best outcome; reveals the first clue that outlets were *deliberately sabotaged*.

## 10. Central mystery
The flood was not an accident, and someone keeps the water high. Clues are found in network nodes,
sabotaged outlets, old maintenance logs and Keepers' agents. Act structure (high level, final content TBD):
- **Act 1**: learn the network; discover sabotage.
- **Act 2**: trace the Keepers; factions compete for control of the network key.
- **Act 3**: reach the central control station; decide the world's final water level — and who decides it.

## 11. Tone & look
Melancholy but hopeful. Sunlit rust, teal water, overgrown concrete. Final art target: 16×16 pixel art with a limited palette, where water depth shows as darker teal and submerged rooftops stay faintly visible under the surface.

## 12. Out of scope (for now)
Multiplayer, procedural world generation, voice acting, fluid simulation, 3D.
