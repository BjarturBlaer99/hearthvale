class_name BarCursor
extends RefCounted
## The cursor of the screen that arranges the item bar (step B2 of
## docs/progress/icons-axe-bar-plan.md, the user's Q12), pure: the bar's columns laid out in
## rows of HandBar.SLOTS (two rows at least, more when more columns are in use), the slot the
## cursor is on, and the slot whose thing is lifted. A choice on a slot lifts what is in it; a
## choice on another slot sets it down there (a move for HandBar.moved(): a swap, or into an
## empty slot); a choice on its own slot, or put_back(), puts it back. BarMenu draws it and
## GameState makes the moves.

## Slots to a row: the bar's nine.
const COLUMNS: int = HandBar.SLOTS
## Rows shown however few columns are in use.
const MIN_ROWS: int = 2
## No slot.
const NONE: int = -1
## What choose() returns when nothing is to be moved.
const NO_MOVE: Vector2i = Vector2i(NONE, NONE)

## How many slots the screen shows, which the cursor is on, and which is lifted (NONE: none).
var cells: int = COLUMNS * MIN_ROWS
var at: int = 0
var lifted: int = NONE


## How many rows show for a bar of `columns` columns: two, or as many as it fills.
static func rows_for(columns: int) -> int:
	return maxi(MIN_ROWS, ceili(float(maxi(columns, 0)) / float(COLUMNS)))


## Lays out a bar of `columns` columns, keeping the cursor and the lifted slot where they can be.
func set_columns(columns: int) -> void:
	cells = rows_for(columns) * COLUMNS
	at = clampi(at, 0, cells - 1)
	if lifted >= cells:
		lifted = NONE


func rows() -> int:
	@warning_ignore("integer_division")
	return cells / COLUMNS


## Steps `step` slots along (negative: back), round and round through every row.
func step(step_by: int) -> void:
	at = wrapi(at + step_by, 0, cells)


## Steps `step` rows down (negative: up), round and round, staying in the same column.
func step_row(step_by: int) -> void:
	@warning_ignore("integer_division")
	var row: int = wrapi(at / COLUMNS + step_by, 0, rows())
	at = row * COLUMNS + at % COLUMNS


## Puts the cursor on slot `index` (where the mouse points). Returns whether it moved: false for
## no such slot or the one it is on.
func point(index: int) -> bool:
	if index < 0 or index >= cells or index == at:
		return false
	at = index
	return true


func is_lifting() -> bool:
	return lifted != NONE


## A choice on slot `index` (the cursor goes there), `filled` saying whether something is in it.
## With nothing lifted: lifts what is in it (nothing for an empty slot). With something lifted:
## on its own slot puts it back; on another, sets it down there, and returns the move
## (Vector2i(from, to)) for HandBar.moved(). NO_MOVE otherwise.
func choose(index: int, filled: bool) -> Vector2i:
	if index < 0 or index >= cells:
		return NO_MOVE
	at = index
	if lifted == NONE:
		if filled:
			lifted = index
		return NO_MOVE
	var from: int = lifted
	lifted = NONE
	return NO_MOVE if from == index else Vector2i(from, index)


## Puts back what is lifted. Returns whether something was.
func put_back() -> bool:
	if lifted == NONE:
		return false
	lifted = NONE
	return true
