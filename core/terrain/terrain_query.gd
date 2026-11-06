class_name TerrainQuery
extends RefCounted
## What a water height means for each cell, and whether an actor can step between cells
## (docs/TECH_DESIGN.md §3.2, §3.4). Pure: works on a HeightGrid and a water height.
##
## Depth is water_height - terrain height: 0 or less is dry, 1 is shallow, 2 or more is
## deep. An actor's level is the terrain height it stands on, or the water surface
## (water_height) while swimming in deep water.

enum CellKind { DRY, SHALLOW, DEEP }

## Drops of this many levels or more onto ground hurt.
const DAMAGING_DROP: int = 3
const SHALLOW_SPEED: float = 0.5

var grid: HeightGrid


func _init(height_grid: HeightGrid) -> void:
	grid = height_grid


static func kind_for(height: int, water_height: int) -> CellKind:
	var depth: int = water_height - height
	if depth <= 0:
		return CellKind.DRY
	if depth == 1:
		return CellKind.SHALLOW
	return CellKind.DEEP


## DRY, SHALLOW or DEEP for an in-bounds `cell` at this water height.
func cell_kind(cell: Vector2i, water_height: int) -> CellKind:
	return kind_for(grid.height_at(cell), water_height)


## The level an actor occupies on `cell`: its terrain height, or the surface if deep.
func standing_level(cell: Vector2i, water_height: int) -> int:
	if cell_kind(cell, water_height) == CellKind.DEEP:
		return water_height
	return grid.height_at(cell)


## Whether, and how, an actor on `from_cell` can step onto the neighbouring `to_cell`:
## - into deep water: SWIM (from any height, never damaging)
## - same level, or one level up or down when either cell is a ramp: WALK
## - out of deep water into the shallows: WALK
## - higher: CLIMB if `to_cell` is climbable, otherwise BLOCKED
## - lower: DROP, damaging from DAMAGING_DROP levels
## Shallow destinations halve the speed.
func check_move(from_cell: Vector2i, to_cell: Vector2i, water_height: int) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	if not grid.in_bounds(from_cell) or not grid.in_bounds(to_cell):
		result.reason = "out of bounds"
		return result
	var from_kind: CellKind = cell_kind(from_cell, water_height)
	var to_kind: CellKind = cell_kind(to_cell, water_height)
	var rise: int = standing_level(to_cell, water_height) - standing_level(from_cell, water_height)
	result.to_level = standing_level(to_cell, water_height)

	if to_kind == CellKind.DEEP:
		result.kind = MoveResult.Kind.SWIM
		result.drop = maxi(0, -rise)
		return result
	var ramp: bool = grid.is_ramp(from_cell) or grid.is_ramp(to_cell)
	if rise == 0 or (absi(rise) == 1 and ramp) or (from_kind == CellKind.DEEP and to_kind == CellKind.SHALLOW):
		result.kind = MoveResult.Kind.WALK
	elif rise > 0:
		if not grid.is_climbable(to_cell):
			result.reason = "%d level(s) up and not climbable" % rise
			return result
		result.kind = MoveResult.Kind.CLIMB
	else:
		result.kind = MoveResult.Kind.DROP
		result.drop = -rise
		result.damaging = result.drop >= DAMAGING_DROP
	if to_kind == CellKind.SHALLOW:
		result.speed_scale = SHALLOW_SPEED
	return result
