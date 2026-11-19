class_name Furnishing
extends Talkable
## Something that stands in the hero's home (crafting, 2026-11-17, docs/TECH_DESIGN.md §28):
## the workbench, which is there from the start, and what the workbench makes for the house:
## the furnace, the storage chest, the standing lamp and the woven rug, and (the Homestead, phase
## 4) the wool blanket over the bed. Each has its own place
## (the scene says where); until it is made it isn't there at all: not seen, not in the way,
## not faced. The workbench opens the crafting list and the chest its stacks (the area does
## both); the furnace talks (GameState.furnace_dialogue: what it holds, or what to smelt); the
## lamp gives light; the rug lies on the floor and is walked over.
## Position = the top-left corner of its (first) cell.

const SHEET: Texture2D = preload("res://gameplay/art/crafted.png")
## Frames in the order tools/art/make_sprites.gd paints them (a test checks).
const FRAMES: Dictionary = {
	&"workbench": 0, &"furnace": 1, &"furnace_lit": 2, &"chest": 3, &"lamp": 4, &"rug_l": 5, &"rug_r": 6,
	&"sprinkler": 7, &"blanket": 8,
}
const SIZE: Vector2i = Vector2i(16, 16)
const WORKBENCH: StringName = &"workbench"
const FURNACE: StringName = &"furnace"
const CHEST: StringName = &"chest"
const LAMP: StringName = &"lamp"
const RUG: StringName = &"rug"
## The wool blanket (the Homestead, phase 4): it lies over the bed, for show.
const BLANKET: StringName = &"blanket"
## What facing one and interacting opens: the crafting list, the chest's stacks, or nothing
## (the furnace talks; the lamp and the rug do nothing).
const CRAFT: StringName = &"craft"
const STORE: StringName = &"store"
const PROMPTS: Dictionary = {WORKBENCH: "Use the workbench", FURNACE: "Use the furnace", CHEST: "Open the chest"}
## Where the lamp's flame and the furnace's mouth are in their cells (px).
const LAMP_AT: Vector2 = Vector2(8, 3)
const FIRE_AT: Vector2 = Vector2(8, 9)

## Which furnishing this is (WORKBENCH, FURNACE, CHEST, LAMP or RUG).
@export var furnishing_id: StringName = WORKBENCH
## There from the start (the workbench), not made.
@export var always: bool = false
## The room it stands in (the Homestead, phase 3): empty for the farmhouse ("home/<id>"), or a
## building's ("shed"): then its flag is "<room>/<piece>".
@export var room: StringName = &""
## Its own name in its room, if it is not its kind's (the shed's two chests: chest_a, chest_b).
@export var piece: StringName = &""
## The key of the furnace or chest it is (GameState.furnace(key), store(key)): empty for the
## farmhouse's.
@export var keeps: StringName = &""


func _ready() -> void:
	EventBus.furnace_changed.connect(queue_redraw)
	EventBus.day_started.connect(_on_day_started)


## Whether it stands in the house: the workbench always, the rest once made.
func is_there() -> bool:
	return always or GameState.is_furnished(furnished_key())


## What GameState.is_furnished() is asked: its kind, or in a building's room "<room>/<piece>".
func furnished_key() -> StringName:
	if room == &"":
		return furnishing_id
	return StringName("%s/%s" % [room, piece if piece != &"" else furnishing_id])


## Whether it fills its cell. The rug lies flat: it is walked over. The blanket lies on the bed,
## which fills its cell itself.
func is_solid() -> bool:
	return furnishing_id != RUG and furnishing_id != BLANKET


## What interacting with it opens (CRAFT, STORE), or &"".
func opens() -> StringName:
	match furnishing_id:
		WORKBENCH:
			return CRAFT
		CHEST:
			return STORE
	return &""


## Only what does something when faced is there to be faced: the workbench, the chest, the
## furnace.
func covers(at: Vector2i) -> bool:
	return is_there() and PROMPTS.has(furnishing_id) and at == cell()


func occupies() -> bool:
	return is_there() and is_solid()


func prompt() -> String:
	return str(PROMPTS.get(furnishing_id, ""))


## The furnace's words; nothing for the rest (the area opens their lists).
func dialogue() -> Dictionary:
	return GameState.furnace_dialogue(keeps) if furnishing_id == FURNACE else {}


## Whether the furnace is burning: lit today, its bars not ready yet.
func is_burning() -> bool:
	return furnishing_id == FURNACE and is_there() and GameState.furnace(keeps).is_burning(GameState.day)


## The light it gives now (an Ambience.glow), or {}: the lamp's, and the furnace's while it
## burns.
func glow_now() -> Dictionary:
	if not is_there():
		return {}
	if furnishing_id == LAMP:
		return Ambience.glow(position + LAMP_AT, 30.0, Ambience.LAMP, 0.36, false)
	if is_burning():
		return Ambience.glow(position + FIRE_AT, 30.0, Ambience.FIRE, 0.38, true)
	return {}


## The frames it shows now, left to right (the rug is two cells wide).
func frames() -> Array[StringName]:
	match furnishing_id:
		RUG:
			return [&"rug_l", &"rug_r"]
		FURNACE:
			return [&"furnace_lit" if is_burning() else &"furnace"]
	return [furnishing_id]


func _draw() -> void:
	if not is_there():
		return
	if is_solid():
		SoftShadow.draw(self, Vector2(8, 15), Vector2(7, 1.6), 0.8)
	var shown: Array[StringName] = frames()
	for index: int in shown.size():
		SpriteSheet.draw(self, SHEET, int(FRAMES[shown[index]]), SIZE, Vector2(index * SIZE.x, 0))


func _on_day_started(_day: int) -> void:
	queue_redraw()
