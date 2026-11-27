class_name MenuPointer
extends RefCounted
## Where the mouse points in a menu (the user's request, 2026-11-15), pure: a menu's list is
## lines of text one under another, and this says which of them a point is on. The menu asks
## it about its own list (MenuInput.line_under) and puts its cursor there.

## Not on any line.
const NONE: int = -1


## Which line of a list `local` is on: 0 for the first. `local` is measured from the list's
## top-left corner; the list is `width` wide and has `lines` lines, each `line_height` high.
## NONE if the point is above, below or beside the lines.
static func line_at(local: Vector2, width: float, line_height: float, lines: int) -> int:
	if line_height <= 0.0 or lines <= 0 or local.x < 0.0 or local.x >= width or local.y < 0.0:
		return NONE
	var line: int = floori(local.y / line_height)
	return line if line < lines else NONE


## Which of `widths` (parts laid side by side from the left, each so wide, with `gap` between
## them) `x` is on: 0 for the first. NONE if it is on a gap or past the last. (Tilda's "Buy"
## and "Sell".)
static func part_at(x: float, widths: PackedFloat32Array, gap: float) -> int:
	var left: float = 0.0
	for i: int in widths.size():
		if x >= left and x < left + widths[i]:
			return i
		left += widths[i] + gap
	return NONE


## Which cell of a grid `local` is on: 0 for the top-left one, then along each row (the screen
## that arranges the item bar). `local` is measured from the grid's top-left corner; the grid is
## `columns` cells wide and has `cells` in all, each `cell_size`, with `gap` between them both
## ways. NONE if the point is on a gap, outside the grid, or past the last cell.
static func cell_at(local: Vector2, cell_size: Vector2, gap: float, columns: int, cells: int) -> int:
	if columns <= 0 or cells <= 0 or cell_size.x <= 0.0 or cell_size.y <= 0.0 or local.x < 0.0 or local.y < 0.0:
		return NONE
	var pitch: Vector2 = cell_size + Vector2(gap, gap)
	var column: int = floori(local.x / pitch.x)
	var row: int = floori(local.y / pitch.y)
	if column >= columns or local.x - float(column) * pitch.x >= cell_size.x or local.y - float(row) * pitch.y >= cell_size.y:
		return NONE
	var cell: int = row * columns + column
	return cell if cell < cells else NONE
