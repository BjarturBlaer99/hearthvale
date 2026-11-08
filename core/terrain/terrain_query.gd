class_name TerrainQuery
extends RefCounted
## Whether, and how, something can step between neighbouring cells (docs/TECH_DESIGN.md §3).
## Classic top-down rules, as in A Link to the Past:
## - solid cells (trees, walls, water...), anything off the map, and cells something is
##   standing in (villagers now, enemies later): BLOCKED
## - same level, or one level up or down when either cell is stairs (ramp): WALK
## - lower: DROP, a hop down a ledge, from any height, never hurting (one-way)
## - higher without stairs: BLOCKED
## Pure: works on a HeightGrid.

var grid: HeightGrid

## Cells something stands in, which nothing else may enter.
var _occupied: Dictionary[Vector2i, bool] = {}


func _init(height_grid: HeightGrid) -> void:
	grid = height_grid


func set_occupied(cell: Vector2i, occupied: bool = true) -> void:
	if occupied:
		_occupied[cell] = true
	else:
		_occupied.erase(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


## The level something stands at on `cell`: its terrain height.
func standing_level(cell: Vector2i) -> int:
	return grid.height_at(cell)


func check_move(from_cell: Vector2i, to_cell: Vector2i) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	if not grid.in_bounds(from_cell) or not grid.in_bounds(to_cell):
		result.reason = "out of bounds"
		return result
	if grid.is_solid(to_cell):
		result.reason = "solid"
		return result
	if is_occupied(to_cell):
		result.reason = "occupied"
		return result
	var rise: int = grid.height_at(to_cell) - grid.height_at(from_cell)
	result.to_level = grid.height_at(to_cell)
	var stairs: bool = grid.is_ramp(from_cell) or grid.is_ramp(to_cell)
	if rise == 0 or (absi(rise) == 1 and stairs):
		result.kind = MoveResult.Kind.WALK
	elif rise < 0:
		result.kind = MoveResult.Kind.DROP
		result.drop = -rise
	else:
		result.reason = "%d level(s) up with no stairs" % rise
	return result
