class_name Torch
extends Node2D
## A standing brazier (docs/TECH_DESIGN.md §6). The hero lights it with interact while carrying a
## lantern. Burning, it sets `flag` (shutters can wait on it) and lights the dark around it.
## - `always_lit`: burns from the start and never goes out (the crypt's first rooms).
## - `burn_time` above zero: goes out by itself after that many seconds, flickering first
##   (light them all in time). Such a torch starts every visit unlit.
## - otherwise it burns until something snuffs it (the Shade), and its flag keeps it lit across
##   visits.
## It stands in its cell. Position = its cell's top-left corner. The area calls set_dungeon().

const SHEET: Texture2D = preload("res://gameplay/art/torch.png")
## Frames in the order tools/art/make_sprites.gd paints them (a test checks).
const FRAMES: Dictionary = {&"unlit": 0, &"flame_a": 1, &"flame_b": 2}
const SIZE: Vector2i = Vector2i(16, 24)
## A timed torch flickers for this long before it goes out.
const WARNING_TIME: float = 1.5
## Where its flame is, from its cell's corner: the middle of its light.
const FLAME_AT: Vector2 = Vector2(8, 2)

## Set while it burns, cleared when it goes out. Optional.
@export var flag: StringName
@export var always_lit: bool = false
## Seconds it burns once lit; zero: until snuffed.
@export var burn_time: float = 0.0
## How far its light reaches (px).
@export var light_radius: float = 60.0

var _lit: bool = false
var _lit_for: float = 0.0
var _clock: float = 0.0


## Called by the area on load (GameState is ready by then): works out whether it starts lit.
func set_dungeon(_id: StringName) -> void:
	if always_lit:
		_lit = true
	elif burn_time > 0.0:
		_lit = false
		if flag != &"" and GameState.get_flag(flag) == true:
			GameState.set_flag(flag, false)
	else:
		_lit = flag != &"" and GameState.get_flag(flag) == true
	queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


func is_lit() -> bool:
	return _lit


## Sets it burning. Returns whether it caught (false: it already burned).
func light() -> bool:
	if _lit:
		return false
	_lit = true
	_lit_for = 0.0
	if flag != &"":
		GameState.set_flag(flag, true)
	EventBus.sound.emit(&"torch")
	Burst.spawn(get_parent(), position + FLAME_AT, &"spark")
	queue_redraw()
	return true


## Puts it out. Returns whether it was burning (an `always_lit` one never goes out).
func snuff() -> bool:
	if not _lit or always_lit:
		return false
	_lit = false
	if flag != &"":
		GameState.set_flag(flag, false)
	queue_redraw()
	return true


## Its light in the dark (LightRules), breathing a little, or empty when it isn't burning.
func light_source() -> Dictionary:
	if not _lit:
		return {}
	return LightRules.light(position + FLAME_AT, light_radius * (1.0 + 0.04 * sin(_clock * 9.0)))


## What interact does while the hero faces it (the HUD's prompt), or empty for nothing.
func prompt() -> String:
	if _lit:
		return ""
	return "Light the torch" if has_lantern() else "An unlit torch"


## The hero interacts facing it: lights it, if they carry a lantern. Returns a message for the
## HUD (empty: nothing to say).
func use() -> String:
	if _lit:
		return ""
	if not has_lantern():
		EventBus.sound.emit(&"nope")
		return "The torch is cold. It needs a flame."
	light()
	return "The torch catches. It won't burn for long." if burn_time > 0.0 else "The torch catches."


static func has_lantern() -> bool:
	return not Inventory.held_of_type(GameState.inventory, DataRegistry.entries(&"items"), "lantern").is_empty()


func _process(delta: float) -> void:
	_clock += delta
	if not _lit:
		return
	if burn_time > 0.0:
		_lit_for += delta
		if not PuzzleRules.torch_burning(_lit_for, burn_time):
			snuff()
			EventBus.sound.emit(&"snuff")
			return
	queue_redraw()


func _draw() -> void:
	SoftShadow.draw(self, Vector2(8, 14), Vector2(5, 1.5))
	var frame: StringName = &"unlit"
	if _lit:
		frame = &"flame_a" if int(_clock * 8.0) % 2 == 0 else &"flame_b"
		# About to go out: the flame gutters.
		if burn_time > 0.0 and burn_time - _lit_for < WARNING_TIME and int(_clock * 12.0) % 3 == 0:
			frame = &"unlit"
	SpriteSheet.draw(self, SHEET, FRAMES[frame], SIZE, Vector2(0, -9))
