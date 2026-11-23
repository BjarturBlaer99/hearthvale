class_name PressurePlate
extends Node2D
## A stone plate in the floor (docs/TECH_DESIGN.md §6): the hero or a push block standing on
## it presses it, which sets `flag` (shutters wait on flags). Stepping off clears the flag
## again, unless the plate `latches`: then it stays pressed for good. The area checks plates
## every physics frame. Position = its cell's top-left corner.
## A plate with an `order` is one of a set (the plates sharing its `flag`) to be pressed in that
## order (PlateOrders, PlateSequence): it stays down while it is counted, and the flag is set
## for good once the last is pressed in turn.

const OUTLINE: Color = PixelGrade.INK
const PLATE: Color = Color(0.62, 0.58, 0.48)
const RUNE: Color = Color(0.95, 0.80, 0.35)

@export var flag: StringName
@export var latches: bool = false
## Its place in its set's order, 1 up; 0 for a plate of no set.
@export var order: int = 0

var pressed: bool = false


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## Updates the plate for whether something stands on it, and its flag if that changed.
func set_pressed(down: bool) -> void:
	if latches and GameState.get_flag(flag) == true:
		down = true
	if down == pressed and GameState.get_flag(flag) == down:
		return
	if down and GameState.get_flag(flag) != true:
		EventBus.sound.emit(&"plate")
	pressed = down
	GameState.set_flag(flag, down)
	queue_redraw()


## A plate of a set shows down while it is counted (PlateOrders says), whatever stands on it.
func show_counted(counted: bool) -> void:
	if counted == pressed:
		return
	pressed = counted
	queue_redraw()


func _draw() -> void:
	var sunk: float = 1.0 if pressed else 0.0
	draw_rect(Rect2(1, 1, 14, 14), OUTLINE)
	draw_rect(Rect2(2, 2 + sunk, 12, 12 - sunk), PLATE.darkened(0.25) if pressed else PLATE)
	if not pressed:
		draw_rect(Rect2(2, 2, 12, 1), PLATE.lightened(0.25))
		draw_rect(Rect2(2, 13, 12, 1), PLATE.darkened(0.35))
	var rune: Color = RUNE if pressed else PLATE.darkened(0.4)
	draw_rect(Rect2(7, 5 + sunk, 2, 6), rune)
	draw_rect(Rect2(5, 7 + sunk, 6, 2), rune)
