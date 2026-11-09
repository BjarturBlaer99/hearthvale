class_name HeartPiece
extends Node2D
## A piece of heart lying in the world (docs/TECH_DESIGN.md §4): touch it to take it. GameState
## counts the pieces, and every fourth makes a heart container. `taken_flag` remembers it's
## gone, for good. The area collects it like a recovery heart. Position = the cell's top-left
## corner.

const RADIUS: float = 6.0
const CENTER: Vector2 = Vector2(8.0, 8.0)
const GOLD: Color = Color(0.98, 0.80, 0.30)

@export var taken_flag: StringName

var _clock: float = 0.0


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func is_there() -> bool:
	return GameState.get_flag(taken_flag) != true


## Whether a circle at `point` (area pixels) with `radius` touches it, while it's there.
func touches(point: Vector2, radius: float) -> bool:
	return is_there() and CombatRules.circles_touch(global_position + CENTER, RADIUS, point, radius)


## Takes it: one more piece toward a heart. Returns false if it was already taken.
func collect() -> bool:
	if not is_there():
		return false
	GameState.set_flag(taken_flag, true)
	EventBus.sound.emit(&"heart_get")
	Burst.spawn(get_parent(), position + CENTER, &"sparkle", 1.6)
	GameState.add_heart_piece()
	queue_redraw()
	return true


func pickup_message() -> String:
	if GameState.heart_pieces == 0:
		return "A piece of heart! Four pieces make a new heart: you have %d hearts." % GameState.hearts_max
	return "You found a piece of heart! (%d of %d)" % [GameState.heart_pieces, GameState.PIECES_PER_HEART]


func _process(delta: float) -> void:
	_clock += delta
	if is_there():
		queue_redraw()


func _draw() -> void:
	if not is_there():
		return
	var lift: float = roundf(2.0 + sin(_clock * 3.0) * 1.0)
	draw_circle(CENTER + Vector2(0, 6), 3.5, Color(0, 0, 0, 0.25))
	draw_circle(CENTER - Vector2(0, lift), 8.0, Color(GOLD, 0.15))
	ItemIcons.draw(self, &"heart_piece", Vector2(0, -lift - 1.0))
	if fmod(_clock, 1.4) < 0.3:
		var spark: Vector2 = CENTER + Vector2(5, -6 - lift)
		draw_line(spark - Vector2(2, 0), spark + Vector2(2, 0), Color(1, 1, 0.9), 1.0)
		draw_line(spark - Vector2(0, 2), spark + Vector2(0, 2), Color(1, 1, 0.9), 1.0)
