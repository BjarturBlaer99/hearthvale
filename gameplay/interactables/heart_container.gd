class_name HeartContainer
extends Node2D
## A heart container (docs/TECH_DESIGN.md §4): it appears once `appears_flag` is set (its boss
## beaten), and touching it adds a heart and fills them all. `taken_flag` remembers it's gone,
## for good. The area collects it like a recovery heart, then opens the conversation
## `dialogue_id` if it has one (the end of the slice). Position = the cell's top-left corner.

const RADIUS: float = 6.0
const CENTER: Vector2 = Vector2(8.0, 8.0)
const GOLD: Color = Color(0.98, 0.80, 0.30)

@export var appears_flag: StringName
@export var taken_flag: StringName
## A conversation (data/dialogue) to open once it's taken; empty: just a message.
@export var dialogue_id: StringName

var _clock: float = 0.0


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Whether it's there to take: appeared and not yet taken.
func is_there() -> bool:
	return GameState.get_flag(appears_flag) == true and GameState.get_flag(taken_flag) != true


## Whether a circle at `point` (area pixels) with `radius` touches it, while it's there.
func touches(point: Vector2, radius: float) -> bool:
	return is_there() and CombatRules.circles_touch(global_position + CENTER, RADIUS, point, radius)


## Adds a heart and fills them all. Returns false if it isn't there.
func collect() -> bool:
	if not is_there():
		return false
	GameState.set_flag(taken_flag, true)
	EventBus.sound.emit(&"heart_get")
	Burst.spawn(get_parent(), position + CENTER, &"sparkle", 1.6)
	GameState.add_heart_container()
	queue_redraw()
	return true


func pickup_message() -> String:
	return "You got a Heart Container! You have %d hearts." % GameState.hearts_max


func _process(delta: float) -> void:
	_clock += delta
	if is_there():
		queue_redraw()


func _draw() -> void:
	if not is_there():
		return
	var lift: float = roundf(3.0 + sin(_clock * 3.0) * 1.5)
	SoftShadow.draw(self, CENTER + Vector2(0, 6), Vector2(4, 1.8))
	draw_circle(CENTER - Vector2(0, lift), 10.0, Color(GOLD, 0.18))
	ItemIcons.draw(self, &"heart_container", Vector2(0, -lift - 1.0))
	var twinkle: float = fmod(_clock, 1.2)
	if twinkle < 0.3:
		var spark: Vector2 = CENTER + Vector2(6, -7 - lift)
		var size: float = 2.0 + twinkle * 6.0
		draw_line(spark - Vector2(size, 0), spark + Vector2(size, 0), Color(1, 1, 0.9), 1.0)
		draw_line(spark - Vector2(0, size), spark + Vector2(0, size), Color(1, 1, 0.9), 1.0)
