class_name Breakable
extends Node2D
## Tall grass, a clay pot (docs/TECH_DESIGN.md §6), set up from data/breakables/<breakable_id>.json.
## It stands in its cell until a blow its data lets through ("breaks_on": the sword, a bomb)
## cuts or breaks it: its sound, a burst of leaves or shards, its cell freed, and its drop table
## rolled, the drop left in its cell. Grass leaves stubble you can walk over (its "broken"
## frame); a pot is just gone. It's back on the next visit (not saved). The area spawns
## breakables from the map's Spawns markers and calls set_terrain(). Position = the cell's
## top-left corner.
## Two things its data may also say (crafting, 2026-11-17: a fallen branch, an old stump):
## "hits", the blows it takes (one unless said), and "returns": "daily", which keeps it broken
## until the next morning instead of the next visit (a flag remembers the day: `cut_flag()`).

const SHEET: Texture2D = preload("res://gameplay/art/breakables.png")
## Frames in the order tools/art/make_sprites.gd paints them (a test checks).
const FRAMES: Dictionary = {&"grass": 0, &"grass_cut": 1, &"pot": 2, &"branch": 3, &"stump": 4}
const SIZE: Vector2i = Vector2i(16, 16)

@export var breakable_id: StringName = &"grass"

## The area it stands in: with its cell, that names the flag a daily one is remembered by.
var area_id: StringName = &""
var data: Dictionary = {}
var broken: bool = false
## How many more blows it takes.
var hits_left: int = 1
## What it dropped (null if nothing, or not broken yet).
var dropped: Node2D
## Gives the drop roll (0 to 1). Tests replace it to choose a drop.
var roll_drop: Callable
var hurt_box: HurtBox

var _terrain: TerrainQuery


func _ready() -> void:
	data = DataRegistry.get_breakable(breakable_id)
	if data.is_empty():
		push_warning("%s: no breakable '%s' in data/breakables." % [name, breakable_id])
	roll_drop = func() -> float: return randf()
	hits_left = maxi(int(data.get("hits", 1)), 1)
	# One that comes back only in the morning, and was broken today, is gone already.
	broken = is_daily() and cut_today()
	hurt_box = HurtBox.new()
	hurt_box.team = &"enemy"
	hurt_box.radius = 6.0
	hurt_box.position = Vector2(8, 8)
	hurt_box.enabled = not broken
	add_child(hurt_box)
	hurt_box.hit_taken.connect(_on_hit)


## The area hands over its terrain (to free the cell once broken) and its random numbers.
func set_terrain(terrain: TerrainQuery, rng: RandomNumberGenerator) -> void:
	_terrain = terrain
	roll_drop = func() -> float: return rng.randf()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## Whole, it stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return not broken


## Whether a blow of `kind` (Hit.kind) breaks it.
func breaks_on(kind: StringName) -> bool:
	return (data.get("breaks_on", []) as Array).has(String(kind))


## Whether it stays broken until the next morning (its data's "returns": "daily").
func is_daily() -> bool:
	return str(data.get("returns", "")) == "daily"


## The flag a daily one keeps the day it was broken in: "cut/<area>/<x>,<y>".
func cut_flag() -> StringName:
	return StringName("cut/%s/%d,%d" % [area_id, cell().x, cell().y])


## Broken today: there is nothing here until tomorrow.
func cut_today() -> bool:
	return int(GameState.get_flag(cut_flag(), 0)) >= GameState.day


func _on_hit(hit: Hit) -> void:
	if broken or not breaks_on(hit.kind):
		return
	hits_left -= 1
	if hits_left <= 0:
		smash()
	else:
		chip()


## A blow that doesn't break it yet: its sound, and a little of what it throws up.
func chip() -> void:
	EventBus.sound.emit(StringName(str(data.get("sound", "cut"))))
	if get_parent() != null:
		Burst.spawn(get_parent(), position + Vector2(8, 8), StringName(str(data.get("burst", "leaves"))), 0.5)


## Cuts or breaks it now. Returns its drop (null for nothing).
func smash() -> Node2D:
	if broken:
		return null
	broken = true
	hurt_box.enabled = false
	if is_daily():
		GameState.set_flag(cut_flag(), GameState.day)
	if _terrain != null:
		_terrain.set_occupied(cell(), false)
	EventBus.sound.emit(StringName(str(data.get("sound", "cut"))))
	if get_parent() != null:
		Burst.spawn(get_parent(), position + Vector2(8, 8), StringName(str(data.get("burst", "leaves"))))
	dropped = _drop()
	queue_redraw()
	return dropped


func _drop() -> Node2D:
	var drop: Dictionary = DropTable.roll(data.get("drops", []), roll_drop.call())
	var node: Node2D = null
	match str(drop.get("type", "")):
		"heart":
			node = HeartPickup.new()
		"item":
			var item: ItemDrop = ItemDrop.new()
			item.item_id = StringName(str(drop.get("item", "coin")))
			item.count = int(drop.get("count", 1))
			node = item
	if node != null and get_parent() != null:
		node.position = position
		get_parent().add_child(node)
	return node


func _draw() -> void:
	var frames: Dictionary = data.get("frames", {})
	var frame: StringName = StringName(str(frames.get("broken" if broken else "whole", "")))
	if not FRAMES.has(frame):
		return
	if not broken:
		SoftShadow.draw(self, Vector2(8, 14), Vector2(5, 1.5), 0.8)
	SpriteSheet.draw(self, SHEET, FRAMES[frame], SIZE, Vector2.ZERO)
