class_name DungeonDoor
extends Node2D
## A door in a dungeon wall (docs/TECH_DESIGN.md §6), `size` cells (1x2 through a thick wall
## between rooms). Kinds (DungeonState):
## - open: a doorway, never closed
## - locked: interact with a small key spends the key and opens it for good
## - boss: interact with the big key opens it for good (the key isn't spent)
## - shutter: bars that lift once `open_flag` is set (a room cleared), or any of `open_flags`
##   (all of them with `needs_all`): a plate, a switch... With `stays_open`, once lifted they
##   stay lifted for good (a solved puzzle stays solved).
## - cracked: a cracked wall; a bomb's blast opens it for good (nothing else does)
## A closed door fills its cells; the area keeps them occupied. Opened locked, boss and cracked
## doors are flags in GameState (DungeonState.door_flag). Position = the top-left corner of its
## first cell. The area calls set_dungeon().

const OUTLINE: Color = PixelGrade.INK
const WOOD: Color = Color(0.45, 0.28, 0.14)
const IRON: Color = Color(0.40, 0.42, 0.46)
const GOLD: Color = Color(0.95, 0.78, 0.28)
const BOSS_RED: Color = Color(0.45, 0.12, 0.14)

@export var door_id: StringName
@export var kind: StringName = DungeonState.LOCKED
@export var size: Vector2i = Vector2i(1, 2)
## Shutters only: the flag that lifts the bars...
@export var open_flag: StringName
## ...or several (any of them lifts the bars, all of them with `needs_all`).
@export var open_flags: Array[StringName] = []
@export var needs_all: bool = false
## Shutters only: once its flags have lifted the bars, they stay up for good (a door flag).
@export var stays_open: bool = false
## Cracked walls only: the stone they're made of (dungeon walls; a ruin's lighter stone outdoors).
@export var stone: Color = Color(0.22, 0.22, 0.28)

var dungeon_id: StringName


func set_dungeon(id: StringName) -> void:
	dungeon_id = id
	if kind == DungeonState.CRACKED and _blast_box == null:
		_add_blast_box()
	queue_redraw()


var _blast_box: HurtBox


## A cracked wall listens for blasts with a HurtBox over its middle (on the enemy team, so the
## hero's bombs reach it); only a bomb's hit opens it.
func _add_blast_box() -> void:
	_blast_box = HurtBox.new()
	_blast_box.team = &"enemy"
	_blast_box.radius = 8.0
	_blast_box.position = Vector2(size) * PlayerMotor.TILE / 2.0
	_blast_box.enabled = not is_open()
	add_child(_blast_box)
	_blast_box.hit_taken.connect(_on_blasted)


func _on_blasted(hit: Hit) -> void:
	if hit.kind != &"bomb" or is_open():
		return
	GameState.set_flag(DungeonState.door_flag(dungeon_id, door_id), true)
	EventBus.sound.emit(&"secret")
	_blast_box.enabled = false
	queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			out.append(cell() + Vector2i(x, y))
	return out


func covers(at: Vector2i) -> bool:
	return Rect2i(cell(), size).has_point(at)


func is_open() -> bool:
	match kind:
		DungeonState.OPEN:
			return true
		DungeonState.SHUTTER:
			if stays_open and GameState.get_flag(DungeonState.door_flag(dungeon_id, door_id)) == true:
				return true
			return PuzzleRules.shutter_open(_shutter_values(), needs_all)
	return GameState.get_flag(DungeonState.door_flag(dungeon_id, door_id)) == true


## A shutter that `stays_open` and whose flags are met records itself open for good. The area
## calls this whenever flags change. Returns whether it just did.
func latch() -> bool:
	if kind != DungeonState.SHUTTER or not stays_open:
		return false
	var flag: StringName = DungeonState.door_flag(dungeon_id, door_id)
	if GameState.get_flag(flag) == true or not PuzzleRules.shutter_open(_shutter_values(), needs_all):
		return false
	GameState.set_flag(flag, true)
	return true


func _shutter_values() -> Array:
	var values: Array = []
	if open_flag != &"":
		values.append(GameState.get_flag(open_flag))
	for flag: StringName in open_flags:
		values.append(GameState.get_flag(flag))
	return values


## What interact does while the hero faces it (the HUD's prompt), or empty for nothing.
func prompt() -> String:
	if is_open():
		return ""
	match kind:
		DungeonState.LOCKED:
			return "Unlock the door" if _can_unlock() else "Locked door"
		DungeonState.BOSS:
			return "Open the boss door" if _can_unlock() else "Boss door"
	return ""


## The hero interacts facing it: opens a locked door (spending a key) or the boss door (with
## the big key) when they can. Returns a message for the HUD (empty: nothing to say).
func use() -> String:
	if is_open():
		return ""
	match kind:
		DungeonState.LOCKED, DungeonState.BOSS:
			if not _can_unlock():
				EventBus.sound.emit(&"nope")
				return "It's locked. A small key would open it." if kind == DungeonState.LOCKED \
					else "The boss door. Only the big key opens it."
			var cost: int = DungeonState.key_cost(kind)
			if cost > 0:
				GameState.set_flag(DungeonState.keys_flag(dungeon_id), _keys() - cost)
			GameState.set_flag(DungeonState.door_flag(dungeon_id, door_id), true)
			EventBus.sound.emit(&"door")
			queue_redraw()
			return "The door opens."
		DungeonState.SHUTTER:
			return "Bars block the way."
		DungeonState.CRACKED:
			return "The wall is cracked. Something strong might break it."
	return ""


func _keys() -> int:
	return int(GameState.get_flag(DungeonState.keys_flag(dungeon_id), 0))


func _can_unlock() -> bool:
	return DungeonState.can_unlock(kind, _keys(), GameState.get_flag(DungeonState.big_key_flag(dungeon_id)) == true)


func _draw() -> void:
	if is_open():
		if kind == DungeonState.CRACKED:
			_draw_rubble()
		return
	var area: Rect2 = Rect2(Vector2.ZERO, Vector2(size) * PlayerMotor.TILE)
	match kind:
		# A door straddles two rooms' walls and each room shows only its own half, so every cell
		# gets its own lock.
		DungeonState.LOCKED:
			draw_rect(area, OUTLINE)
			draw_rect(area.grow(-1.0), WOOD)
			for x: float in range(4, int(area.size.x), 5):
				draw_line(Vector2(x, 1), Vector2(x, area.size.y - 1), WOOD.darkened(0.3), 1.0)
			for center: Vector2 in _cell_centers():
				_lock(center, 3.0)
		DungeonState.BOSS:
			draw_rect(area, OUTLINE)
			draw_rect(area.grow(-1.0), BOSS_RED)
			for center: Vector2 in _cell_centers():
				draw_rect(Rect2(1, center.y - 1.0, area.size.x - 2.0, 2.0), IRON)
				_lock(center, 4.0)
		DungeonState.CRACKED:
			_draw_cracked(area)
		DungeonState.SHUTTER:
			draw_rect(area, Color(0, 0, 0, 0.45))
			for x: float in range(2, int(area.size.x), 4):
				draw_rect(Rect2(x, 0, 2, area.size.y), OUTLINE)
				draw_rect(Rect2(x, 0, 1, area.size.y), IRON)
			draw_rect(Rect2(0, 2, area.size.x, 2), IRON.darkened(0.2))


## A crack-riddled stretch of dungeon wall.
func _draw_cracked(area: Rect2) -> void:
	draw_rect(area, stone)
	for y: float in range(3, int(area.size.y), 4):
		draw_line(Vector2(0, y + 0.5), Vector2(area.size.x, y + 0.5), stone.darkened(0.5), 1.0)
	var crack: Color = Color(0.06, 0.05, 0.07)
	for center: Vector2 in _cell_centers():
		var points: PackedVector2Array = [center + Vector2(-5, -6), center + Vector2(-1, -2), center + Vector2(-3, 1), center + Vector2(1, 4), center + Vector2(4, 7)]
		draw_polyline(points, crack, 1.5)
		draw_line(center + Vector2(-1, -2), center + Vector2(4, -4), crack, 1.0)
		draw_line(center + Vector2(1, 4), center + Vector2(-3, 7), crack, 1.0)


## What's left of a cracked wall once blown open: rubble at the sides.
func _draw_rubble() -> void:
	var rubble: Color = stone.lightened(0.3)
	for center: Vector2 in _cell_centers():
		for bit: Vector3 in [Vector3(-6, 5, 2.0), Vector3(5, 6, 1.5), Vector3(-4, -5, 1.5), Vector3(6, -4, 2.0)]:
			draw_circle(center + Vector2(bit.x, bit.y), bit.z + 0.8, OUTLINE)
			draw_circle(center + Vector2(bit.x, bit.y), bit.z, rubble)


func _cell_centers() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: int in size.y:
		for x: int in size.x:
			out.append((Vector2(x, y) + Vector2(0.5, 0.5)) * PlayerMotor.TILE)
	return out


func _lock(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 1.0, OUTLINE)
	draw_circle(center, radius, GOLD)
	draw_rect(Rect2(center + Vector2(-0.5, -radius * 0.4), Vector2(1, radius * 0.9)), OUTLINE)
