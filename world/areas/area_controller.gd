class_name AreaController
extends Node2D
## Runs one area scene: the village, house interiors, later the countryside and dungeon rooms
## (docs/TECH_DESIGN.md §3). Builds the HeightGrid from the `Height` layer, places the hero,
## shows hearts and prompts on the HUD, and handles interacting: picking up what's underfoot,
## talking to whoever the hero faces, and leaving through exits. Every physics frame it lets
## HitBoxes hit HurtBoxes and the hero collect hearts; at zero hearts the hero falls and comes
## back at the area's entrance (where they arrived) with full hearts.
##
## Expects children: Height, HeightShading, Interactables, PlayerSpawn, Player, HUD, and
## optionally Entries. Interactables holds ItemPickups, Talkables (villagers, signs),
## AreaExits, combat pieces (training dummy, brambles, hearts) and Enemies, which the area
## sets up with its terrain, the hero and its random numbers. Any child whose occupies() is
## true stands in its cell; any with touches() and collect() (hearts, coins) is picked up by
## touch. Entries holds a Marker2D per entry point, named by id, at a cell's centre and
## rotated the way the hero should face on arrival (0 = right, 90 = down). PlayerSpawn is
## where a new game (or a first visit with no entry) puts the hero.

## Seconds the hero lies still after falling, before coming back at the entrance.
const RESPAWN_DELAY: float = 1.0

@export var area_id: StringName = &"village"
@export var area_name: String = "Hearthvale"

var grid: HeightGrid
var terrain: TerrainQuery
## Changes the scene when the hero takes an exit (gets the scene path). Tests replace it.
var travel: Callable
## Random numbers for enemies (wandering, drops). Randomised on load; tests can seed it.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _travelling: bool = false
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
		if child.has_method(&"occupies") and child.call(&"occupies"):
			terrain.set_occupied(child.call(&"cell"))
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
	hud.dialogue.closed.connect(_on_dialogue_closed)
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


func _physics_process(_delta: float) -> void:
	if _travelling:
		return
	resolve_combat()
	collect_pickups()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and interact():
		get_viewport().set_input_as_handled()


## Picks up what's underfoot, else talks to whoever the hero faces. Returns true if
## something happened.
func interact() -> bool:
	if _travelling or _dying or is_talking():
		return false
	var pickup: ItemPickup = pickup_under_player()
	if pickup != null:
		return pick_up(pickup)
	var talkable: Talkable = talkable_in_front()
	if talkable != null:
		return talk_to(talkable)
	return false


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
	var exit: AreaExit = exit_at(cell)
	if exit != null:
		take_exit(exit)


func _on_dialogue_closed() -> void:
	player.controls_enabled = true


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


func _update_hud() -> void:
	hud.set_items(carrying_text())
	if is_talking():
		hud.set_prompt("")
		return
	var pickup: ItemPickup = pickup_under_player()
	if pickup != null:
		hud.set_prompt("[E] Pick up the %s" % pickup.item_name())
		return
	var talkable: Talkable = talkable_in_front()
	hud.set_prompt("[E] %s" % talkable.prompt() if talkable != null else "")
