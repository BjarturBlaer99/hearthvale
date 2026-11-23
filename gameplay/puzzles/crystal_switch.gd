class_name CrystalSwitch
extends Node2D
## A crystal on a pedestal (docs/TECH_DESIGN.md §6): hit it with the sword, an arrow or a bomb
## and it sets `flag` (or flips it, with `toggles`); the crystal shows red when the flag is off
## and blue when on. It stands in its cell. Its HurtBox (on the enemy team, so the hero's hits
## reach it) is made in code. Position = its cell's top-left corner.
## With a `hold_time` it turns back (dungeon-difficulty-plan.md, decision 13): a hit makes it
## blue for that long, blinking white in its last second, then red again; it starts every visit
## red. Shutters waiting on several such crystals need them blue at the same time.

## After a hit, more hits are ignored this long (one swing, one change).
const LOCKOUT: float = 0.4
const SHEET: Texture2D = preload("res://gameplay/art/crystal.png")
## Frames in the order they stand in the sheet (art/sheets.json; a test checks).
const FRAMES: Dictionary = {&"red": 0, &"blue": 1, &"white": 2}
const OUTLINE: Color = PixelGrade.INK
const RED: Color = Color(0.92, 0.28, 0.30)
const BLUE: Color = Color(0.35, 0.62, 0.98)
const STONE: Color = Color(0.50, 0.50, 0.56)
const KINDS: Array[StringName] = [&"sword", &"arrow", &"bomb"]
## How long before turning back a crystal blinks, and how fast.
const WARNING_TIME: float = 1.0
const BLINKS_PER_SECOND: float = 8.0

@export var flag: StringName
@export var toggles: bool = false
## Seconds it stays blue after a hit before it turns back to red; 0: it stays.
@export var hold_time: float = 0.0

var hurt_box: HurtBox

var _lockout: float = 0.0
var _flash: float = 0.0
## How long it has been blue since the last hit (a crystal that turns back).
var _on_for: float = 0.0


func _ready() -> void:
	hurt_box = HurtBox.new()
	hurt_box.team = &"enemy"
	hurt_box.radius = 6.0
	hurt_box.position = Vector2(8, 6)
	add_child(hurt_box)
	hurt_box.hit_taken.connect(_on_hit)
	set_process(false)
	# One that turns back starts every visit red.
	if hold_time > 0.0 and flag != &"" and is_on():
		GameState.set_flag(flag, false)


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


func is_on() -> bool:
	return GameState.get_flag(flag) == true


func _on_hit(hit: Hit) -> void:
	if _lockout > 0.0 or not KINDS.has(hit.kind):
		return
	# One that turns back is blue again for its whole time, whatever it was.
	GameState.set_flag(flag, not is_on() if toggles and hold_time <= 0.0 else true)
	_on_for = 0.0
	EventBus.sound.emit(&"crystal")
	Burst.spawn(get_parent(), position + Vector2(8, 4), &"sparkle")
	_lockout = LOCKOUT
	_flash = 0.15
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_lockout = maxf(0.0, _lockout - delta)
	_flash = maxf(0.0, _flash - delta)
	var holding: bool = hold_time > 0.0 and is_on()
	if holding:
		_on_for += delta
		if not PuzzleRules.crystal_holding(_on_for, hold_time):
			GameState.set_flag(flag, false)
			EventBus.sound.emit(&"snuff")
			holding = false
	queue_redraw()
	if _lockout <= 0.0 and _flash <= 0.0 and not holding:
		set_process(false)


## Whether it is in its last second before turning back (it blinks white).
func is_warning() -> bool:
	return is_on() and PuzzleRules.crystal_warning(_on_for, hold_time, WARNING_TIME)


func _draw() -> void:
	SoftShadow.draw(self, Vector2(8, 14), Vector2(6.5, 2))
	var blink: bool = is_warning() and int(_on_for * BLINKS_PER_SECOND) % 2 == 0
	var frame: StringName = &"white" if _flash > 0.0 or blink else (&"blue" if is_on() else &"red")
	SpriteSheet.draw(self, SHEET, FRAMES[frame], Vector2i(16, 16), Vector2(0, -1))
