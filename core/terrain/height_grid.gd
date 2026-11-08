class_name HeightGrid
extends RefCounted
## Terrain height and traversal flags for every cell of one area (docs/TECH_DESIGN.md §3).
## Plain data, so terrain rules are testable without scenes. Areas build it from their
## `Height` TileMapLayer (HeightGridBuilder); tests use from_rows().
##
## Heights 0-7 are ground levels: cliffs, plateaus, ledges. Flags: `solid` cells (trees,
## walls, roofs, water, fences) can never be entered; `ramp` cells are stairs, which let you
## walk up or down one level.

const MAX_HEIGHT: int = 7
const FLAG_SOLID: int = 1
const FLAG_RAMP: int = 2

var size: Vector2i = Vector2i.ZERO

var _heights: PackedByteArray = PackedByteArray()
var _flags: PackedByteArray = PackedByteArray()


func _init(grid_size: Vector2i = Vector2i.ZERO, fill_height: int = 0) -> void:
	size = Vector2i(maxi(grid_size.x, 0), maxi(grid_size.y, 0))
	_heights.resize(size.x * size.y)
	_heights.fill(clampi(fill_height, 0, MAX_HEIGHT))
	_flags.resize(size.x * size.y)
	_flags.fill(0)


## Builds a grid from text rows. Each row is space-separated cells: a height digit 0-7,
## then optional flags, `s` solid and `r` ramp (stairs). Example: "0 0 1r 2 0s".
## Returns null (with an error) if the rows are malformed or of different lengths.
static func from_rows(rows: PackedStringArray) -> HeightGrid:
	var parsed: Array[PackedStringArray] = []
	for row: String in rows:
		parsed.append(row.split(" ", false))
	var width: int = parsed[0].size() if not parsed.is_empty() else 0
	var grid: HeightGrid = HeightGrid.new(Vector2i(width, parsed.size()))
	for y: int in parsed.size():
		if parsed[y].size() != width:
			push_error("HeightGrid.from_rows: row %d has %d cells, expected %d." % [y, parsed[y].size(), width])
			return null
		for x: int in width:
			var token: String = parsed[y][x]
			var height: int = token.unicode_at(0) - 48
			if height < 0 or height > MAX_HEIGHT:
				push_error("HeightGrid.from_rows: '%s' at (%d, %d) must start with a height 0-%d." % [token, x, y, MAX_HEIGHT])
				return null
			var cell: Vector2i = Vector2i(x, y)
			grid.set_height(cell, height)
			for flag: String in token.substr(1):
				match flag:
					"s":
						grid.set_solid(cell, true)
					"r":
						grid.set_ramp(cell, true)
					_:
						push_error("HeightGrid.from_rows: unknown flag '%s' in '%s' at (%d, %d)." % [flag, token, x, y])
						return null
	return grid


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Terrain height of `cell`, or -1 outside the grid.
func height_at(cell: Vector2i) -> int:
	return _heights[_index(cell)] if in_bounds(cell) else -1


func set_height(cell: Vector2i, height: int) -> void:
	if in_bounds(cell):
		_heights[_index(cell)] = clampi(height, 0, MAX_HEIGHT)


## Solid cells (trees, walls, roofs, water, fences) can never be entered.
func is_solid(cell: Vector2i) -> bool:
	return in_bounds(cell) and (_flags[_index(cell)] & FLAG_SOLID) != 0


func set_solid(cell: Vector2i, solid: bool) -> void:
	_set_flag(cell, FLAG_SOLID, solid)


## A ramp is stairs: walk up or down one level from or onto it.
func is_ramp(cell: Vector2i) -> bool:
	return in_bounds(cell) and (_flags[_index(cell)] & FLAG_RAMP) != 0


func set_ramp(cell: Vector2i, ramp: bool) -> void:
	_set_flag(cell, FLAG_RAMP, ramp)


func _index(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func _set_flag(cell: Vector2i, flag: int, on: bool) -> void:
	if not in_bounds(cell):
		return
	var i: int = _index(cell)
	_flags[i] = (_flags[i] | flag) if on else (_flags[i] & ~flag)
