class_name TerrainQuery
extends RefCounted
## Whether, and how, something can step between neighbouring cells (docs/TECH_DESIGN.md §3).
## Classic top-down rules, as in A Link to the Past:
## - solid cells (trees, walls, water...), anything off the map, and cells something is
##   standing in (villagers now, enemies later): BLOCKED
## - same level, or one level up or down when either cell is stairs (ramp): WALK
## - lower: DROP, a hop down a ledge, from any height, never hurting (one-way)
## - higher without stairs: BLOCKED
## - an open pit: DROP too, so the hero can fall in (the area pulls them out) and walkers that
##   don't drop (enemies) keep out. Things that fly, and arrows, cross pits.
## Pure: works on a HeightGrid.

var grid: HeightGrid

## Cells something stands in, which nothing else may enter.
var _occupied: Dictionary[Vector2i, bool] = {}
## Cells closed to everything, flying things and arrows too: closed doors.
var _sealed: Dictionary[Vector2i, bool] = {}
## Open pits (a pit a block has filled is floor again, and not here).
var _pits: Dictionary[Vector2i, bool] = {}


func _init(height_grid: HeightGrid) -> void:
	grid = height_grid


func set_occupied(cell: Vector2i, occupied: bool = true) -> void:
	if occupied:
		_occupied[cell] = true
	else:
		_occupied.erase(cell)


func is_occupied(cell: Vector2i) -> bool:
	return _occupied.has(cell)


## Seals or unseals `cell`: a closed door stops bats and arrows as well as walkers.
func set_sealed(cell: Vector2i, sealed: bool = true) -> void:
	if sealed:
		_sealed[cell] = true
	else:
		_sealed.erase(cell)


func is_sealed(cell: Vector2i) -> bool:
	return _sealed.has(cell)


## Opens a pit at `cell`, or closes it (a block filled it).
func set_pit(cell: Vector2i, open: bool = true) -> void:
	if open:
		_pits[cell] = true
	else:
		_pits.erase(cell)


func is_pit(cell: Vector2i) -> bool:
	return _pits.has(cell)


## The level something stands at on `cell`: its terrain height.
func standing_level(cell: Vector2i) -> int:
	return grid.height_at(cell)


## For things that fly (bats): heights, stairs and ledges don't matter; solid cells and the
## map edge still block, and so do sealed cells (closed doors). Occupied cells don't (they fly
## over villagers and dummies).
func check_flight(from_cell: Vector2i, to_cell: Vector2i) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	if not grid.in_bounds(from_cell) or not grid.in_bounds(to_cell):
		result.reason = "out of bounds"
	elif grid.is_solid(to_cell):
		result.reason = "solid"
	elif is_sealed(to_cell):
		result.reason = "sealed"
	else:
		result.kind = MoveResult.Kind.WALK
		result.to_level = grid.height_at(to_cell)
	return result


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
	if is_pit(to_cell) and not is_pit(from_cell) and rise <= 0:
		result.kind = MoveResult.Kind.DROP
		result.drop = maxi(-rise, 1)
		return result
	var stairs: bool = grid.is_ramp(from_cell) or grid.is_ramp(to_cell)
	if rise == 0 or (absi(rise) == 1 and stairs):
		result.kind = MoveResult.Kind.WALK
	elif rise < 0:
		result.kind = MoveResult.Kind.DROP
		result.drop = -rise
	else:
		result.reason = "%d level(s) up with no stairs" % rise
	return result
