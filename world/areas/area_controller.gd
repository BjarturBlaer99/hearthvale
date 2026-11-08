class_name AreaController
extends Node2D
## Runs one area scene: the village, house interiors, later the countryside and dungeon rooms
## (docs/TECH_DESIGN.md §3). Builds the HeightGrid from the `Height` layer, places the hero,
## shows hearts and prompts on the HUD, and handles interacting: picking up what's underfoot,
## talking to whoever the hero faces, using the equipped item (bow shots, bombs), opening the
## item menu, and leaving through exits. Every physics frame it lets
## HitBoxes hit HurtBoxes and the hero collect hearts; at zero hearts the hero falls and comes
## back at the area's entrance (where they arrived) with full hearts.
##
## Expects children: Height, HeightShading, Interactables, PlayerSpawn, Player, HUD, and
## optionally Entries. Puzzle pieces (push blocks, pressure plates, crystal switches) live in
## Interactables too: the area pushes blocks and presses plates. In a dungeon (`dungeon_id` set) the map is cut into rooms of
## `room_size` cells and the camera shows the hero's room. Interactables holds ItemPickups,
## Talkables (villagers, signs), dungeon doors and chests (E uses whatever has use()),
## AreaExits, combat pieces (training dummy, brambles, hearts) and Enemies, which the area
## sets up with its terrain, the hero and its random numbers. Any child whose occupies() is
## true stands in its cell; any with touches() and collect() (hearts, coins) is picked up by
## touch. Entries holds a Marker2D per entry point, named by id, at a cell's centre and
## rotated the way the hero should face on arrival (0 = right, 90 = down). PlayerSpawn is
## where a new game (or a first visit with no entry) puts the hero.

## Seconds the hero lies still after falling, before coming back at the entrance.
const RESPAWN_DELAY: float = 1.0
## How long the screen dims when the hero walks into another room.
const ROOM_FLASH: float = 0.2
## How long the hero must push against a block before it slides.
const PUSH_TIME: float = 0.35

@export var area_id: StringName = &"village"
@export var area_name: String = "Hearthvale"
## Set for dungeons: names its flags (DungeonState) for doors, chests and keys.
@export var dungeon_id: StringName
## Room size in cells for dungeons (the camera shows one room); zero: the whole area at once.
@export var room_size: Vector2i = Vector2i.ZERO

var grid: HeightGrid
var terrain: TerrainQuery
## Changes the scene when the hero takes an exit (gets the scene path). Tests replace it.
var travel: Callable
## Random numbers for enemies (wandering, drops). Randomised on load; tests can seed it.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The last arrow or bomb the hero let loose (for tests), or null.
var last_projectile: Node2D
## The room the camera shows (RoomGrid coordinates).
var current_room: Vector2i = Vector2i.ZERO
## Shades everything outside the current room (dungeons only), or null.
var room_mask: RoomMask

var _travelling: bool = false
var _push_time: float = 0.0
var _dying: bool = false
var _respawn_left: float = 0.0
## Where the hero arrived in this area, facing which way: where they come back after falling.
var _entrance_cell: Vector2i = Vector2i.ZERO
var _entrance_facing: Vector2 = Vector2.DOWN

@onready var height_layer: TileMapLayer = $Height
@onready var player: PlayerController = $Player
@onready var interactables: Node2D = $Interactables
@onready var hud: AreaHud = $HUD
@onready var _shading: HeightShading = $HeightShading


func _init() -> void:
	travel = _change_scene


func _ready() -> void:
	if not GameState.is_started():
		GameState.new_game()
	# Draw whoever is lower on screen in front: the hero, villagers and things in Interactables
	# sort together by y (the tile layers sit at y 0, under everything).
	y_sort_enabled = true
	interactables.y_sort_enabled = true
	grid = HeightGridBuilder.from_layer(height_layer)
	terrain = TerrainQuery.new(grid)
	for child: Node in interactables.get_children():
		if child.has_method(&"set_dungeon"):
			child.call(&"set_dungeon", flag_scope())
		if child.has_method(&"occupies") and child.call(&"occupies"):
			terrain.set_occupied(child.call(&"cell"))
	_refresh_doors()
	_shading.show_grid(grid)
	var arrival: Dictionary = _arrival()
	_entrance_cell = arrival["cell"]
	_entrance_facing = arrival["facing"]
	player.setup(terrain, _entrance_cell, Rect2i(Vector2i.ZERO, grid.size * GreyboxTiles.TILE_SIZE))
	player.face(_entrance_facing)
	player.motor.cell_changed.connect(_on_cell_changed)
	rng.randomize()
	for enemy: Enemy in enemies():
		enemy.setup(terrain, player, rng)
		enemy.died.connect(_on_enemy_died)
	update_room(true)
	hud.dialogue.closed.connect(_on_dialogue_closed)
	hud.item_menu.chosen.connect(_on_item_chosen)
	hud.item_menu.closed.connect(_on_item_menu_closed)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.flag_set.connect(_on_flag_set)
	hud.set_area(area_name)
	hud.set_health(GameState.health, GameState.max_health())
	if arrival["through_entry"]:
		hud.flash()
	GameState.update_player(area_id, player.motor.cell)
	_update_hud()


func _process(delta: float) -> void:
	if _travelling:
		return
	if _dying:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			respawn()
	GameState.update_player(area_id, player.motor.cell)
	_update_hud()


func _physics_process(delta: float) -> void:
	if _travelling:
		return
	update_pushing(delta)
	update_plates()
	resolve_combat()
	collect_pickups()


## Pushing a block: holding straight against one for PUSH_TIME slides it a cell. Returns
## whether a block moved this time.
func update_pushing(delta: float) -> bool:
	var direction: Vector2i = player.pushing_toward() if player.controls_enabled else Vector2i.ZERO
	var block: PushBlock = _find(PushBlock, player.motor.cell + direction) as PushBlock if direction != Vector2i.ZERO else null
	if block == null:
		_push_time = 0.0
		return false
	_push_time += delta
	if _push_time < PUSH_TIME:
		return false
	_push_time = 0.0
	return block.try_push(direction, terrain, room_size)


## Presses or releases every plate for whether the hero or a block stands on it.
func update_plates() -> void:
	var block_cells: Array = []
	for child: Node in interactables.get_children():
		if child is PushBlock:
			block_cells.append((child as PushBlock).cell())
	for child: Node in interactables.get_children():
		if child is PressurePlate:
			var plate: PressurePlate = child
			plate.set_pressed(not _dying and PuzzleRules.plate_pressed(plate.cell(), player.motor.cell, block_cells))


func _unhandled_input(event: InputEvent) -> void:
	var used: bool = false
	if event.is_action_pressed(&"interact"):
		used = interact()
	elif event.is_action_pressed(&"use_item"):
		used = use_item()
	elif event.is_action_pressed(&"item_menu"):
		used = open_item_menu()
	if used:
		get_viewport().set_input_as_handled()


## Picks up what's underfoot, else talks to whoever the hero faces. Returns true if
## something happened.
func interact() -> bool:
	if _busy():
		return false
	var pickup: ItemPickup = pickup_under_player()
	if pickup != null:
		return pick_up(pickup)
	var talkable: Talkable = talkable_in_front()
	if talkable != null:
		return talk_to(talkable)
	var usable: Node2D = usable_in_front()
	if usable != null:
		var message: String = usable.call(&"use")
		if not message.is_empty():
			hud.show_message(message)
			return true
	return false


## The door or chest in the cell the hero faces (anything with use() and prompt()), or null.
func usable_in_front() -> Node2D:
	var front: Vector2i = player.front_cell()
	for child: Node in interactables.get_children():
		if child.has_method(&"use") and child.has_method(&"prompt") and child.call(&"covers", front):
			return child as Node2D
	return null


func doors() -> Array[DungeonDoor]:
	var out: Array[DungeonDoor] = []
	for child: Node in interactables.get_children():
		if child is DungeonDoor:
			out.append(child as DungeonDoor)
	return out


## Points the camera at the hero's room (dungeons) and dims the screen briefly when it changed.
func update_room(first: bool = false) -> void:
	var room: Vector2i = RoomGrid.room_of(player.motor.cell, room_size)
	if room == current_room and not first:
		return
	current_room = room
	var rect: Rect2i = RoomGrid.camera_rect(player.motor.cell, room_size, grid.size, GreyboxTiles.TILE_SIZE)
	player.set_camera_bounds(rect)
	if room_size != Vector2i.ZERO:
		if room_mask == null:
			room_mask = RoomMask.new()
			add_child(room_mask)
		room_mask.show_room(Rect2(rect))
	if not first:
		hud.flash(ROOM_FLASH)
		reset_blocks()


## Puts back every push block outside the hero's room (one jammed in a corner is back in place
## on the way back in). Returns how many moved.
func reset_blocks() -> int:
	var moved: int = 0
	for child: Node in interactables.get_children():
		if child is PushBlock and RoomGrid.room_of((child as PushBlock).cell(), room_size) != current_room:
			if (child as PushBlock).reset(terrain):
				moved += 1
	return moved


## What doors and chests name their flags by: the dungeon, or outside dungeons the area (a
## cracked wall in the countryside).
func flag_scope() -> StringName:
	return dungeon_id if dungeon_id != &"" else area_id


## "Ruin Cellar   Keys: 1   Big key" in a dungeon; just the name elsewhere.
func area_text() -> String:
	if dungeon_id == &"":
		return area_name
	var keys: int = int(GameState.get_flag(DungeonState.keys_flag(dungeon_id), 0))
	var big_key: bool = GameState.get_flag(DungeonState.big_key_flag(dungeon_id)) == true
	return "%s   Keys: %d%s" % [area_name, keys, "   Big key" if big_key else ""]


func pickup_under_player() -> ItemPickup:
	return _find(ItemPickup, player.motor.cell) as ItemPickup


## The villager or sign in the cell the hero faces, or null.
func talkable_in_front() -> Talkable:
	return _find(Talkable, player.front_cell()) as Talkable


func exit_at(cell: Vector2i) -> AreaExit:
	return _find(AreaExit, cell) as AreaExit


func talkables() -> Array[Talkable]:
	var out: Array[Talkable] = []
	for child: Node in interactables.get_children():
		if child is Talkable:
			out.append(child as Talkable)
	return out


func pick_up(pickup: ItemPickup) -> bool:
	if not pickup.take():
		return false
	hud.show_message("You pick up the %s." % pickup.item_name())
	return true


## Opens `talkable`'s conversation in the dialogue box; the hero stands still until it ends.
func talk_to(talkable: Talkable) -> bool:
	var data: Dictionary = talkable.dialogue()
	if data.is_empty():
		push_warning("%s: no dialogue '%s' in data/dialogue." % [talkable.name, talkable.dialogue_id])
		return false
	player.controls_enabled = false
	hud.set_prompt("")
	hud.dialogue.open(DialogueRunner.new(data, GameState))
	return true


func is_talking() -> bool:
	return hud.dialogue.is_open()


## Uses the item on the item button: the bow shoots an arrow the way the hero faces (one ammo,
## and the hero stands still for its cooldown); bombs are set down at the hero's feet. Says so
## and does nothing with nothing equipped or no ammo left. Returns whether it was used.
func use_item() -> bool:
	if _busy() or not player.controls_enabled:
		return false
	var item: Dictionary = DataRegistry.get_item(GameState.equipped)
	if item.is_empty():
		hud.show_message("Nothing on the item button yet.")
		return false
	var ammo: String = Inventory.ammo_for(item)
	if not ammo.is_empty() and GameState.item_count(StringName(ammo)) <= 0:
		hud.show_message("Out of %s." % str(DataRegistry.get_item(StringName(ammo)).get("name", ammo)).to_lower())
		return false
	match str(item.get("type", "")):
		"weapon_ranged":
			return _shoot(item, StringName(ammo))
		"bomb":
			return _set_bomb(item)
	return false


## Opens the item menu with the equippable items held. Returns whether it opened.
func open_item_menu() -> bool:
	if _busy() or not player.controls_enabled:
		return false
	var held: Array[Dictionary] = Inventory.equippable_held(GameState.inventory, DataRegistry.entries(&"items"))
	if held.is_empty():
		hud.show_message("No items yet.")
		return false
	player.controls_enabled = false
	hud.set_prompt("")
	hud.item_menu.open(held, GameState.equipped)
	return true


func is_in_menu() -> bool:
	return hud.item_menu.is_open()


## "Item: Bow (Arrows x10)" for the HUD.
static func equipped_text() -> String:
	var item: Dictionary = DataRegistry.get_item(GameState.equipped)
	return "Item: %s" % (ItemMenu.describe(item) if not item.is_empty() else "none")


func _shoot(bow: Dictionary, ammo: StringName) -> bool:
	var stats: Dictionary = bow.get("stats", {})
	var direction: Vector2i = player.facing_direction()
	if not player.motor.attack(direction, float(stats.get("cooldown", 0.45))):
		return false
	GameState.add_item(ammo, -1)
	var arrow: Arrow = Arrow.new()
	arrow.setup(terrain, Vector2(direction), int(stats.get("damage", 2)), float(stats.get("speed", 180.0)),
		&"hero", float(stats.get("knockback", 20.0)))
	arrow.position = player.motor.position + Vector2(direction) * 8.0
	interactables.add_child(arrow)
	last_projectile = arrow
	player.sync_from_motor()
	return true


func _set_bomb(item: Dictionary) -> bool:
	if player.motor.state_name != PlayerMotor.GROUND:
		return false
	GameState.add_item(StringName(str(item["id"])), -1)
	var bomb: Bomb = Bomb.new()
	bomb.setup(item.get("stats", {}))
	bomb.position = player.motor.position
	interactables.add_child(bomb)
	last_projectile = bomb
	return true


## Talking, in the item menu, going through a door or down: no interacting or items.
func _busy() -> bool:
	return _travelling or _dying or is_talking() or is_in_menu()


## Lets every active HitBox in this area hit the HurtBoxes it touches (TECH_DESIGN §4).
## Returns how many hits landed.
func resolve_combat() -> int:
	var hit_boxes: Array[HitBox] = []
	for node: Node in get_tree().get_nodes_in_group(HitBox.GROUP):
		if node is HitBox and is_ancestor_of(node) and (node as HitBox).active:
			hit_boxes.append(node as HitBox)
	var hurt_boxes: Array[HurtBox] = []
	for node: Node in get_tree().get_nodes_in_group(HurtBox.GROUP):
		if node is HurtBox and is_ancestor_of(node):
			hurt_boxes.append(node as HurtBox)
	var landed: int = 0
	for hit_box: HitBox in hit_boxes:
		for hurt_box: HurtBox in hurt_boxes:
			if hit_box.try_hit(hurt_box):
				landed += 1
	return landed


## The hero picks up every heart and coin they touch. Returns how many.
func collect_pickups() -> int:
	if _dying:
		return 0
	var collected: int = 0
	var at: Vector2 = player.hurt_box.global_position
	for child: Node in interactables.get_children():
		if child.has_method(&"touches") and child.has_method(&"collect") \
				and child.call(&"touches", at, player.hurt_box.radius) and child.call(&"collect"):
			collected += 1
			if child.has_method(&"pickup_message"):
				hud.show_message(str(child.call(&"pickup_message")))
	return collected


func enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for child: Node in interactables.get_children():
		if child is Enemy:
			out.append(child as Enemy)
	return out


## True from the moment the hero runs out of hearts until they come back.
func is_dying() -> bool:
	return _dying


## Brings the hero back at the area's entrance with full hearts.
func respawn() -> void:
	_dying = false
	GameState.set_health(GameState.max_health())
	player.motor.place(_entrance_cell)
	player.face(_entrance_facing)
	update_room()
	player.controls_enabled = not is_talking()
	hud.flash()
	hud.show_message("You wake up back at the entrance.")


## Leaves through `exit`: records where the hero is going in GameState, then changes scene.
func take_exit(exit: AreaExit) -> void:
	if _travelling:
		return
	_travelling = true
	player.controls_enabled = false
	GameState.go_to(exit.target_area, exit.target_entry)
	travel.call(WorldPaths.scene_for(exit.target_area))


## The entry point `entry_id` (a Marker2D under Entries), or null.
func entry_marker(entry_id: StringName) -> Marker2D:
	var entries: Node = get_node_or_null(^"Entries")
	if entries == null or String(entry_id).is_empty():
		return null
	return entries.get_node_or_null(NodePath(String(entry_id))) as Marker2D


## The way an entry marker points, snapped to the nearest of the four directions.
static func entry_facing(marker: Node2D) -> Vector2:
	var pointing: Vector2 = Vector2.RIGHT.rotated(marker.rotation)
	if absf(pointing.x) > absf(pointing.y):
		return Vector2(signf(pointing.x), 0.0)
	return Vector2(0.0, signf(pointing.y))


## "Carrying: ..." for the HUD, from the inventory in GameState.
static func carrying_text() -> String:
	var names: PackedStringArray = []
	for stack: Dictionary in GameState.inventory:
		var item_name: String = str(DataRegistry.get_item(stack["id"]).get("name", stack["id"]))
		names.append(item_name if int(stack["count"]) == 1 else "%s x%d" % [item_name, int(stack["count"])])
	return "Carrying: %s" % (", ".join(names) if not names.is_empty() else "nothing")


## Where the hero starts: the entry point they came through, else where they were (a loaded
## game), else PlayerSpawn. { "cell": Vector2i, "facing": Vector2, "through_entry": bool }
func _arrival() -> Dictionary:
	var saved: Dictionary = GameState.player
	var spawn: Dictionary = {
		"cell": PlayerMotor.cell_of(($PlayerSpawn as Node2D).position),
		"facing": Vector2.DOWN,
		"through_entry": false,
	}
	if str(saved.get("area", "")) != String(area_id):
		return spawn
	if saved.has("entry"):
		var marker: Marker2D = entry_marker(StringName(str(saved["entry"])))
		if marker == null:
			push_warning("%s: no entry point '%s'; starting at PlayerSpawn." % [area_id, saved["entry"]])
			return spawn
		return {"cell": PlayerMotor.cell_of(marker.position), "facing": entry_facing(marker), "through_entry": true}
	if saved.has("cell"):
		var cell: Array = saved["cell"]
		var at: Vector2i = Vector2i(int(cell[0]), int(cell[1]))
		if grid.in_bounds(at):
			return {"cell": at, "facing": Vector2.DOWN, "through_entry": false}
	return spawn


## The first Interactables child of `type` that covers `cell`, or null.
func _find(type: Script, cell: Vector2i) -> Node2D:
	for child: Node in interactables.get_children():
		if is_instance_of(child, type) and child.call(&"covers", cell):
			return child as Node2D
	return null


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _on_cell_changed(cell: Vector2i) -> void:
	update_room()
	var exit: AreaExit = exit_at(cell)
	if exit != null:
		take_exit(exit)


func _on_dialogue_closed() -> void:
	player.controls_enabled = true


func _on_item_chosen(item_id: StringName) -> void:
	GameState.equip(item_id)


func _on_item_menu_closed() -> void:
	player.controls_enabled = not (_dying or _travelling or is_talking())


func _on_health_changed(current: int, maximum: int) -> void:
	hud.set_health(current, maximum)
	if GameState.is_dead() and not _dying:
		_fall()


## Out of hearts: the hero lies still for RESPAWN_DELAY, then respawn().
func _fall() -> void:
	_dying = true
	_respawn_left = RESPAWN_DELAY
	player.controls_enabled = false
	player.motor.die()
	player.sync_from_motor()


func _on_flag_set(_flag: StringName, _value: Variant) -> void:
	for child: Node in interactables.get_children():
		(child as Node2D).queue_redraw()
	_refresh_doors()


## Closed doors fill their cells; open ones don't. Shutters that stay open remember opening.
func _refresh_doors() -> void:
	for door: DungeonDoor in doors():
		door.latch()
		for cell: Vector2i in door.cells():
			terrain.set_occupied(cell, not door.is_open())


## When the last enemy sharing a clear flag falls, the flag is set (a shutter may open).
func _on_enemy_died(enemy: Enemy) -> void:
	if enemy.clear_flag == &"":
		return
	for other: Enemy in enemies():
		if other.clear_flag == enemy.clear_flag and not other.is_dead():
			return
	GameState.set_flag(enemy.clear_flag, true)


func _update_hud() -> void:
	hud.set_area(area_text())
	hud.set_items(carrying_text())
	hud.set_equipped(equipped_text())
	if is_talking() or is_in_menu():
		hud.set_prompt("")
		return
	var pickup: ItemPickup = pickup_under_player()
	if pickup != null:
		hud.set_prompt("[E] Pick up the %s" % pickup.item_name())
		return
	var talkable: Talkable = talkable_in_front()
	if talkable != null:
		hud.set_prompt("[E] %s" % talkable.prompt())
		return
	var usable: Node2D = usable_in_front()
	var text: String = str(usable.call(&"prompt")) if usable != null else ""
	hud.set_prompt("[E] %s" % text if not text.is_empty() else "")
