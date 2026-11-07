class_name BoatRules
extends RefCounted
## Where the boat may be and how the player gets on and off it (docs/TECH_DESIGN.md §4).
## Pure: everything is answered from a TerrainQuery and a water height.

const NO_CELL: Vector2i = Vector2i(-1, -1)
const SIDES: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]


## The boat floats only on deep water inside the map.
static func floats(terrain: TerrainQuery, cell: Vector2i, water_height: int) -> bool:
	return terrain.grid.in_bounds(cell) and terrain.cell_kind(cell, water_height) == TerrainQuery.CellKind.DEEP


## The deep cell fewest grid steps from `from` (itself if it floats), or NO_CELL if the
## map has no deep water at this height. Ties go to the first found (right, down, left, up).
static func nearest_deep_cell(terrain: TerrainQuery, from: Vector2i, water_height: int) -> Vector2i:
	if not terrain.grid.in_bounds(from):
		return NO_CELL
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		if floats(terrain, cell, water_height):
			return cell
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if terrain.grid.in_bounds(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return NO_CELL


## Where a rider steps ashore: a dry or shallow cell next to the boat that is reachable on
## foot from the water (TerrainQuery says WALK, so no climbing out). Prefers the cell the
## boat is pointing at. NO_CELL when there is nowhere to land.
static func landing_cell(terrain: TerrainQuery, boat_cell: Vector2i, heading: float, water_height: int) -> Vector2i:
	var ahead: Vector2 = Vector2.from_angle(heading)
	var sides: Array[Vector2i] = SIDES.duplicate()
	sides.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).dot(ahead) > Vector2(b).dot(ahead))
	for side: Vector2i in sides:
		var cell: Vector2i = boat_cell + side
		if not terrain.grid.in_bounds(cell) or terrain.cell_kind(cell, water_height) == TerrainQuery.CellKind.DEEP:
			continue
		if terrain.check_move(boat_cell, cell, water_height).kind == MoveResult.Kind.WALK:
			return cell
	return NO_CELL


## A player can step aboard from the boat's own cell (swimming beside it) or a neighbour.
static func can_board(player_cell: Vector2i, boat_cell: Vector2i) -> bool:
	var gap: Vector2i = (player_cell - boat_cell).abs()
	return gap.x + gap.y <= 1
