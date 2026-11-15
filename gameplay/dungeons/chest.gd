class_name Chest
extends Node2D
## A treasure chest (docs/TECH_DESIGN.md §6): face it and press E. A small key or the big key
## goes to the dungeon's count (keys belong to their dungeon); anything else goes to the
## inventory. Opened, it stays open (DungeonState.chest_flag). It stands in its cell.
## Position = the cell's top-left corner. The area calls set_dungeon().

const OUTLINE: Color = PixelGrade.INK
const WOOD: Color = Color(0.55, 0.34, 0.16)
const GOLD: Color = Color(0.95, 0.78, 0.28)
## What is said when the hero can't carry what it holds (the thing's name).
const NO_ROOM_WORDS: String = "You have no room for the %s in this chest."

@export var chest_id: StringName
@export var item_id: StringName = &"small_key"
@export var count: int = 1

var dungeon_id: StringName


func set_dungeon(id: StringName) -> void:
	dungeon_id = id
	queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


func opened() -> bool:
	return GameState.get_flag(DungeonState.chest_flag(dungeon_id, chest_id)) == true


func prompt() -> String:
	return "" if opened() else "Open the chest"


## Whether the hero can carry all of what is inside. Keys always fit: they are the dungeon's
## count, not in the pack.
func has_room() -> bool:
	return item_id == &"small_key" or item_id == &"big_key" or GameState.has_room_for(item_id, count)


## Opens it and hands over what's inside. Returns a message for the HUD (empty if already open).
## With no room for what it holds it stays shut and says so: nothing is lost to a full pack.
func use() -> String:
	if opened():
		return ""
	if not has_room():
		EventBus.sound.emit(&"nope")
		return NO_ROOM_WORDS % str(DataRegistry.get_item(item_id).get("name", item_id))
	GameState.set_flag(DungeonState.chest_flag(dungeon_id, chest_id), true)
	EventBus.sound.emit(&"item_get")
	Burst.spawn(get_parent(), position + Vector2(8, 4), &"sparkle", 1.3)
	match item_id:
		&"small_key":
			var keys: StringName = DungeonState.keys_flag(dungeon_id)
			GameState.set_flag(keys, int(GameState.get_flag(keys, 0)) + count)
		&"big_key":
			GameState.set_flag(DungeonState.big_key_flag(dungeon_id), true)
		_:
			GameState.add_item(item_id, count)
	queue_redraw()
	var item_name: String = str(DataRegistry.get_item(item_id).get("name", item_id))
	return "You got the %s!" % item_name if count == 1 else "You got %s x%d!" % [item_name, count]


func _draw() -> void:
	SoftShadow.draw(self, Vector2(8, 14), Vector2(6.5, 2))
	if opened():
		draw_rect(Rect2(1, 5, 14, 9), OUTLINE)
		draw_rect(Rect2(2, 6, 12, 7), WOOD)
		draw_rect(Rect2(3, 6, 10, 3), Color(0.06, 0.04, 0.03))
		draw_rect(Rect2(1, 1, 14, 5), OUTLINE)
		draw_rect(Rect2(2, 2, 12, 3), WOOD.lightened(0.15))
		return
	draw_rect(Rect2(1, 3, 14, 11), OUTLINE)
	draw_rect(Rect2(2, 4, 12, 9), WOOD)
	draw_rect(Rect2(2, 4, 12, 3), WOOD.lightened(0.15))
	draw_rect(Rect2(2, 7, 12, 1), GOLD.darkened(0.2))
	draw_rect(Rect2(7, 6, 2, 3), GOLD)
