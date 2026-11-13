class_name AreaController
extends Node2D
## Runs one area scene: the village, house interiors, later the countryside and dungeon rooms
## (docs/TECH_DESIGN.md §3). Builds the HeightGrid from the `Height` layer, places the hero,
## shows hearts and prompts on the HUD, and handles interacting: picking up what's underfoot,
## talking to whoever the hero faces, using the equipped item (bow shots, bombs), opening the
## item menu, and leaving through exits. Every physics frame it lets
## HitBoxes hit HurtBoxes and the hero collect hearts; at zero hearts the hero falls and comes
## back at the area's entrance (where they arrived) with full hearts. A hero who steps into a
## pit loses half a heart and is put back on the last safe cell. A `dark` area shows only what
## its lights reach: the hero's own glow (wider with a lantern) and burning torches.
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
## How long the screen stays dark as one day ends and the next begins.
const DAY_FLASH: float = 1.4
## What is said on waking: after a night in bed, after staying up until the day ran out, and
## after collapsing; and what is added when coins were lost on the way.
const SLEPT_WORDS: String = "You wake rested. The game is saved."
const WOKE_LATE_WORDS: String = "You stayed up too late, and woke in your own bed."
const COLLAPSED_WORDS: String = "You collapsed, and woke in your own bed."
const COINS_LOST_WORDS: String = " You lost %d coins on the way."
## The tune that plays outdoors at night in place of the area's own.
const NIGHT_TUNE: StringName = &"night"
## What is said when he eats (the food's name, then what it gave), and when he needn't.
const ATE_WORDS: String = "%s: %s."
const NOT_HUNGRY_WORDS: String = "You aren't hungry."
## What is said as the hero tires, and as he drops.
const TIRED_WORDS: String = "You are getting tired."
const WORN_OUT_WORDS: String = "You are too tired to run."
const SPENT_WORDS: String = "You are spent. Everything goes dark."
## How long the hero lies where he fell, out of energy, before he wakes at home.
const COLLAPSE_TIME: float = 1.3
## How long the hero must push against a block before it slides.
const PUSH_TIME: float = 0.35
## Where "Quit to title" goes.
const TITLE_SCENE: String = "res://ui/title_screen.tscn"
## The flag the game's last conversation sets, and the screen that follows once it closes.
const ENDING_FLAG: StringName = EndingSummary.FINISHED_FLAG
const ENDING_SCENE: String = "res://ui/ending_screen.tscn"
## How slow the game runs during a hit-stop.
const HIT_STOP_SCALE: float = 0.05
## Falling into a pit: the half hearts it costs, and how long the hero is gone.
const PIT_DAMAGE: int = 1
const PIT_TIME: float = 0.5
## How far the hero's own glow reaches in the dark without a lantern (px).
const DIM_RADIUS: float = 20.0
## The colour of a rule's light in the dark: all but white, so things show in their own colours.
const RULE_TINT: Color = Color(1.0, 0.97, 0.90)
## How much of a glow's colour its pool takes (the rest is white).
const POOL_TINT: float = 0.22
## Under the night sky a lamp's pool is warmer and doesn't quite bring back the day: how far
## its colour leans to the lamp's, and how strong it is.
const NIGHT_POOL_TINT: float = 0.55
const NIGHT_POOL: float = 0.78

@export var area_id: StringName = &"village"
@export var area_name: String = "Hearthvale"
## Set for dungeons: names its flags (DungeonState) for doors, chests and keys.
@export var dungeon_id: StringName
## Room size in cells for dungeons (the camera shows one room); zero: the whole area at once.
@export var room_size: Vector2i = Vector2i.ZERO
## The tune this area plays (audio/music); empty: whatever is playing carries on.
@export var music: StringName = &""
## A dark area (the crypt): only what lights reach is seen (LightRules, drawn by AreaLighting).
@export var dark: bool = false

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
## What kind of place this is for light and air (Ambience): outdoors, a house, a dungeon.
var ambience: StringName = Ambience.OUTDOOR
## The area's ambient colour and its real lights (P1b).
var lighting: AreaLighting
## The glows of the tiles that give light (lamp posts, hearths, candles): they never move.
var tile_glows: Array = []
## The trees, standing up from the ground and sorted by depth with everyone else (P1c).
var scenery: Scenery
## Grass, flowers and washing moving in the wind; cherry petals; the water's surface; mist.
var sway: TileMapLayer
## Walls with a front face and a top (P1d), or null in an area with no such walls.
var relief: WallRelief
## The houses' lit windows (P2e), if the area has any.
var windows: WindowGlow
var petals: Petals
var water: WaterSurface
var reflections: Reflections
var mist: Mist
## Specks drifting in the air.
var motes: Motes

var _travelling: bool = false
## The ending flag was just set: the ending screen comes when the conversation closes.
var _ending_due: bool = false
## When the current hit-stop ends (real milliseconds; 0: none).
var _hit_stop_until: int = 0
## Whether each door was open, to hear shutters lift.
var _door_open: Dictionary = {}
var _push_time: float = 0.0
var _dying: bool = false
var _respawn_left: float = 0.0
## Out of energy: the hero lies where he fell for this long, then wakes at home.
var _collapsing: bool = false
var _collapse_left: float = 0.0
## The hero's energy at the last change, to tell when he crosses into being tired.
var _energy_was: float = 0.0
var _hours: Hours
## The tune this area last asked for.
var _tune: StringName = &""
## Where the hero arrived in this area, facing which way: where they come back after falling.
var _entrance_cell: Vector2i = Vector2i.ZERO
var _entrance_facing: Vector2 = Vector2.DOWN
## Seconds left of a fall into a pit (0: not falling).
var _pit_left: float = 0.0
## The last cell the hero stood on that wasn't a pit: where a fall puts them back.
var _safe_cell: Vector2i = Vector2i.ZERO

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
	for pit: Vector2i in HeightGridBuilder.pit_cells(height_layer):
		terrain.set_pit(pit)
	spawn_markers()
	for child: Node in interactables.get_children():
		if child.has_method(&"set_dungeon"):
			child.call(&"set_dungeon", flag_scope())
		if child.has_method(&"set_terrain"):
			child.call(&"set_terrain", terrain, rng)
		if child.has_method(&"occupies") and child.call(&"occupies"):
			terrain.set_occupied(child.call(&"cell"))
		# A block that sank for good: its pit is floor.
		if child is PushBlock and (child as PushBlock).sunk:
			terrain.set_pit((child as PushBlock).cell(), false)
	_refresh_doors()
	_shading.stone_faces = dungeon_id != &""
	_shading.show_grid(grid, height_layer)
	var arrival: Dictionary = _arrival()
	_entrance_cell = arrival["cell"]
	_entrance_facing = arrival["facing"]
	player.setup(terrain, _entrance_cell, Rect2i(Vector2i.ZERO, grid.size * GreyboxTiles.TILE_SIZE))
	player.face(_entrance_facing)
	_safe_cell = _entrance_cell
	player.motor.cell_changed.connect(_on_cell_changed)
	rng.randomize()
	ambience = Ambience.kind_of(height_layer, dungeon_id)
	for enemy: Enemy in enemies():
		# Met outdoors at night, a monster is tougher (P2e). It is decided here, as the area loads.
		enemy.night = is_night_outdoors()
		enemy.setup(terrain, player, rng)
		enemy.died.connect(_on_enemy_died)
	player.set_camera_zoom(Ambience.ZOOM[ambience])
	update_room(true)
	_add_ambience()
	_update_light()
	hud.dialogue.closed.connect(_on_dialogue_closed)
	hud.item_menu.chosen.connect(_on_item_chosen)
	hud.item_menu.closed.connect(_on_item_menu_closed)
	hud.pause_menu.quit_to_title.connect(_on_quit_to_title)
	EventBus.hit_stop.connect(hit_stop)
	EventBus.quest_announced.connect(_on_quest_announced)
	for boss: Enemy in enemies():
		if boss is ArenaBoss:
			(boss as ArenaBoss).calm_music = music
	_play_tune()
	_keep_hours()
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.slept.connect(_on_slept)
	EventBus.energy_changed.connect(_on_energy_changed)
	hud.show_energy(true)
	hud.set_energy(GameState.energy, GameState.max_energy())
	_energy_was = GameState.energy
	# Arriving with something to be told (he woke here after the day ran out): say it once.
	if not GameState.arrival_notice.is_empty():
		EventBus.sound.emit(&"morning")
		hud.flash(DAY_FLASH)
		hud.show_message(GameState.arrival_notice)
		GameState.arrival_notice = ""
	hud.set_area(area_name)
	hud.set_health(GameState.health, GameState.max_health())
	hud.set_pieces(GameState.heart_pieces)
	EventBus.heart_piece_found.connect(hud.set_pieces)
	if arrival["through_entry"]:
		hud.flash()
	GameState.update_player(area_id, player.motor.cell)
	_update_hud()
	# A loaded game, or anything changed outside an area: let the quests catch up.
	Quests.refresh()


func _process(delta: float) -> void:
	if _hit_stop_until > 0 and Time.get_ticks_msec() >= _hit_stop_until:
		_end_hit_stop()
	if _travelling:
		return
	# Runs only while the game isn't paused, so the clock stops behind the pause menu.
	GameState.add_play_time(delta)
	if clock_runs():
		GameState.advance_time(delta)
		if GameState.is_day_over():
			# He is on his way home: nothing more of this area this frame (the rest of it
			# would write where he stood over where he is going).
			end_the_day()
			return
	if _dying:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			respawn()
	if _collapsing:
		_collapse_left -= delta
		if _collapse_left <= 0.0:
			_wake_at_home(COLLAPSED_WORDS)
			return
	elif GameState.is_exhausted() and not (_dying or is_in_pit() or is_talking()):
		collapse()
	if _pit_left > 0.0:
		_pit_left -= delta
		if _pit_left <= 0.0:
			_climb_out()
	_update_light()
	scenery.fade_for(standing_points(), delta)
	if reflections != null:
		reflections.follow(player)
	GameState.update_player(area_id, player.motor.cell)
	_update_hud()


func _physics_process(delta: float) -> void:
	if _travelling:
		return
	update_pushing(delta)
	update_plates()
	resolve_combat()
	collect_pickups()


## Turns the markers the map baker painted on the hidden Spawns layer into their nodes: grass
## and pots (Breakable), chickens, butterflies and fireflies (Critter). Returns how many.
func spawn_markers() -> int:
	var layer: TileMapLayer = get_node_or_null(^"Spawns") as TileMapLayer
	if layer == null:
		return 0
	layer.visible = false
	var made: int = 0
	for cell: Vector2i in layer.get_used_cells():
		var kind: String = GreyboxTiles.marker_kind(layer.get_cell_atlas_coords(cell))
		var node: Node2D = _spawned(kind)
		if node == null:
			push_warning("%s: no spawn marker '%s' at %s." % [area_id, kind, cell])
			continue
		node.name = "%s_%d_%d" % [kind.capitalize(), cell.x, cell.y]
		node.position = Vector2(cell * GreyboxTiles.TILE_SIZE)
		interactables.add_child(node)
		made += 1
	layer.clear()
	return made


func _spawned(kind: String) -> Node2D:
	if GreyboxTiles.BREAKABLE_MARKERS.has(kind):
		var breakable: Breakable = Breakable.new()
		breakable.breakable_id = StringName(kind)
		return breakable
	if Critter.KINDS.has(StringName(kind)):
		var critter: Critter = Critter.new()
		critter.kind = StringName(kind)
		return critter
	return null


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
	elif event.is_action_pressed(&"pause"):
		used = open_pause_menu()
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
			if usable is Chest:
				player.hold_up(ItemIcons.name_for((usable as Chest).item_id))
			return true
	if shut_door_in_front() != null:
		_say_shut(shut_door_in_front())
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
	player.hold_up(ItemIcons.name_for(pickup.item_id))
	return true


## Opens `talkable`'s conversation in the dialogue box; the hero stands still until it ends.
func talk_to(talkable: Talkable) -> bool:
	return _open_conversation(talkable.dialogue(), "%s's" % talkable.name)


## Opens conversation `dialogue_id` (data/dialogue) in the dialogue box; the hero stands still
## until it ends. Returns false if there's no such conversation.
func open_dialogue(dialogue_id: StringName) -> bool:
	return _open_conversation(DataRegistry.get_dialogue(dialogue_id), "'%s' in data/dialogue" % dialogue_id)


## Opens the conversation `data` (in the shape of data/dialogue: a villager's from a file, the
## hearth's built from the recipes). `what` names it if it is empty.
func _open_conversation(data: Dictionary, what: String) -> bool:
	if data.is_empty():
		push_warning("%s: no dialogue: %s." % [area_id, what])
		return false
	player.controls_enabled = false
	hud.set_prompt("")
	hud.dialogue.open(DialogueRunner.new(data, GameState))
	return true


## Pauses the game behind the pause menu (Esc / Start). Returns whether it opened.
func open_pause_menu() -> bool:
	if _busy():
		return false
	hud.set_prompt("")
	hud.pause_menu.open(pause_status())
	return true


func is_paused() -> bool:
	return hud.pause_menu.is_open()


## The pause menu's summary: hearts and heart pieces, keys in a dungeon, and the play time.
func pause_status() -> String:
	var lines: PackedStringArray = ["Hearts %d   Heart pieces %d of %d" % [GameState.hearts_max, GameState.heart_pieces, GameState.PIECES_PER_HEART]]
	if dungeon_id != &"":
		var keys: int = int(GameState.get_flag(DungeonState.keys_flag(dungeon_id), 0))
		var big_key: bool = GameState.get_flag(DungeonState.big_key_flag(dungeon_id)) == true
		lines.append("%s   Small keys %d%s" % [area_name, keys, "   Big key" if big_key else ""])
	else:
		lines.append(area_name)
	lines.append("Time played %s" % GameState.format_play_time(GameState.play_time))
	return "\n".join(lines)


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
		EventBus.sound.emit(&"nope")
		hud.show_message("Nothing on the item button yet.")
		return false
	var ammo: String = Inventory.ammo_for(item)
	if not ammo.is_empty() and GameState.item_count(StringName(ammo)) <= 0:
		EventBus.sound.emit(&"nope")
		hud.show_message("Out of %s." % str(DataRegistry.get_item(StringName(ammo)).get("name", ammo)).to_lower())
		return false
	match str(item.get("type", "")):
		"weapon_ranged":
			return _shoot(item, StringName(ammo))
		"bomb":
			return _set_bomb(item)
	return false


## Opens the item menu with the equippable items held, then the food. Returns whether it
## opened.
func open_item_menu() -> bool:
	if _busy() or not player.controls_enabled:
		return false
	var held: Array[Dictionary] = Inventory.equippable_held(GameState.inventory, DataRegistry.entries(&"items"))
	held.append_array(Food.edible_held(GameState.inventory, DataRegistry.entries(&"items")))
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
	GameState.spend_energy(GameState.energy_rules().cost(EnergyRules.SHOT))
	GameState.add_item(ammo, -1)
	EventBus.sound.emit(&"arrow")
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
	EventBus.sound.emit(&"bomb_set")
	var bomb: Bomb = Bomb.new()
	bomb.setup(item.get("stats", {}))
	bomb.position = player.motor.position
	interactables.add_child(bomb)
	last_projectile = bomb
	return true


## Talking, in the item menu, going through a door or down: no interacting or items.
func _busy() -> bool:
	return _travelling or _dying or _collapsing or is_in_pit() or is_talking() or is_in_menu() or is_paused()


## The lights in this area (LightRules lights): the hero's own, and every torch burning in the
## room on screen (light doesn't pass a dungeon's walls).
func lights() -> Array:
	var out: Array = [LightRules.light(player.position + Vector2(0, -8), hero_light_radius())]
	for child: Node in interactables.get_children():
		if child is Torch and (child as Torch).is_lit() 				and RoomGrid.room_of((child as Torch).cell(), room_size) == RoomGrid.room_of(player.motor.cell, room_size):
			out.append((child as Torch).light_source())
	return out


## How far the hero's light reaches: the widest lantern carried, else a dim glow.
func hero_light_radius() -> float:
	return Inventory.light_radius(GameState.inventory, DataRegistry.entries(&"items"), DIM_RADIUS)


## How lit `cell` is right now, 0 to 1 (always 1 in an area that isn't dark).
func brightness_at(cell: Vector2i) -> float:
	return LightRules.brightness(GridBody.cell_center(cell), lights()) if dark else 1.0


## Whether the day's clock runs here and now (GDD §6): not in a dungeon, where there is no
## day; not in a conversation or the item menu; not while the hero is down or in a pit. (Behind
## the pause menu nothing runs at all.)
func clock_runs() -> bool:
	return ambience != Ambience.DUNGEON and not (is_talking() or is_in_menu() or _dying or _collapsing or is_in_pit())


## The day ran out (02:00): he passes out, which costs what collapsing costs (GDD §6), and
## wakes by his bed.
func end_the_day() -> void:
	_wake_at_home(WOKE_LATE_WORDS)


## Out of energy (GDD §5): the hero drops where he stands, can't be hurt, and after
## COLLAPSE_TIME wakes at home. It can happen anywhere, a dungeon too.
func collapse() -> void:
	if _collapsing or _travelling:
		return
	_collapsing = true
	_collapse_left = COLLAPSE_TIME
	EventBus.sound.emit(&"collapse")
	player.controls_enabled = false
	player.hurt_box.enabled = false
	player.lie_down()
	hud.set_prompt("")
	hud.show_message(SPENT_WORDS)


func is_collapsing() -> bool:
	return _collapsing


## The next day begins with the hero by his bed: half his energy, some of his coins gone
## (GameState.collapse), his hearts as they were, and the game saved. The home area says
## `words` as it loads.
func _wake_at_home(words: String) -> void:
	if _travelling:
		return
	_travelling = true
	player.controls_enabled = false
	var lost: int = GameState.collapse()
	GameState.arrival_notice = words + (COINS_LOST_WORDS % lost if lost > 0 else "")
	GameState.go_to(WorldPaths.HOME_AREA, WorldPaths.HOME_BED)
	SaveSystem.save_game()
	travel.call(WorldPaths.scene_for(WorldPaths.HOME_AREA))


## The bar follows the hero's energy, and a line says so as he tires.
func _on_energy_changed(current: float, maximum: float) -> void:
	hud.set_energy(current, maximum)
	var rules: EnergyRules = GameState.energy_rules()
	if rules.can_sprint(_energy_was) and not rules.can_sprint(current) and not rules.is_spent(current):
		hud.show_message(WORN_OUT_WORDS)
	elif not rules.is_low(_energy_was) and rules.is_low(current) and not rules.is_spent(current):
		hud.show_message(TIRED_WORDS)
	_energy_was = current


## The hero slept in his bed (GameState.sleep, from the bed's conversation): the morning comes
## up out of the dark, and the game is saved.
func _on_slept(_day: int) -> void:
	GameState.update_player(area_id, player.motor.cell)
	SaveSystem.save_game()
	EventBus.sound.emit(&"morning")
	hud.flash(DAY_FLASH)
	hud.show_message(SLEPT_WORDS)


## Whether it is night out of doors here and now: monsters are tougher, and the night tune
## plays.
func is_night_outdoors() -> bool:
	return has_daylight() and GameState.day_clock().is_night(GameState.minute)


## Who keeps what hours (data/rules/hours.json).
func hours() -> Hours:
	if _hours == null:
		_hours = Hours.new(DataRegistry.get_rules(DataRegistry.RULES_HOURS))
	return _hours


## The tune for here and now: the area's own, or the night's out of doors after nightfall.
func tune_now() -> StringName:
	return NIGHT_TUNE if music != &"" and is_night_outdoors() else music


## Asks for the tune for here and now, when it is another than the one last asked for (so a
## tune something else has asked for meanwhile, a boss's, is left to play).
func _play_tune() -> void:
	var tune: StringName = tune_now()
	if tune == &"" or tune == _tune:
		return
	_tune = tune
	EventBus.music_requested.emit(tune)


## The doors that keep hours (AreaExit.hours).
func doors_with_hours() -> Array[AreaExit]:
	var out: Array[AreaExit] = []
	for child: Node in interactables.get_children():
		if child is AreaExit and (child as AreaExit).hours != &"":
			out.append(child as AreaExit)
	return out


## Whether `door` is shut at this hour.
func is_shut(door: AreaExit) -> bool:
	return door.hours != &"" and not hours().is_open(door.hours, GameState.minute)


## The shut door in the cell the hero faces, or null.
func shut_door_in_front() -> AreaExit:
	for door: AreaExit in doors_with_hours():
		if door.covers(player.front_cell()) and is_shut(door):
			return door
	return null


## Tells the hero that `door` is shut.
func _say_shut(door: AreaExit) -> void:
	EventBus.sound.emit(&"nope")
	hud.show_message(hours().shut_words(door.hours))


## Keeps everyone's hours (GDD §6). A door that keeps hours is solid while it is shut. Villagers
## who stand outdoors go home for the night and are back in the morning: gone, they can't be
## seen or talked to, and their cell is free. Nobody leaves in the middle of a conversation,
## and nobody comes back onto the hero.
func _keep_hours() -> void:
	for door: AreaExit in doors_with_hours():
		for x: int in door.size.x:
			for y: int in door.size.y:
				terrain.set_occupied(door.cell() + Vector2i(x, y), is_shut(door))
	if not has_daylight() or is_talking():
		return
	var out: bool = hours().villagers_out(GameState.minute)
	for child: Node in interactables.get_children():
		var villager: Villager = child as Villager
		if villager == null or villager.present == out or (out and player.motor.cell == villager.cell()):
			continue
		villager.set_present(out)
		terrain.set_occupied(villager.cell(), out)


## A new minute of the day: the hours kept, and the tune.
func _on_time_changed(_day: int, _minute: int) -> void:
	_keep_hours()
	_play_tune()


## Whether the day's light falls here: outdoors, and not in a place that is dark by rule.
func has_daylight() -> bool:
	return ambience == Ambience.OUTDOOR and not dark


## Hands the lights of this moment to the area's lighting: those that reach what the camera
## shows. Outdoors the ambient colour is the hour's.
func _update_light() -> void:
	if lighting == null:
		return
	if has_daylight():
		lighting.set_ambient(GameState.daylight())
	if windows != null:
		windows.set_lit(GameState.day_clock().lamps_lit(GameState.minute))
	var room: Rect2i = RoomGrid.camera_rect(player.motor.cell, room_size, grid.size, GreyboxTiles.TILE_SIZE)
	lighting.show_lights(scene_lights(), Rect2(room))


## The area's light and air, for show only: its ambient colour and real lights (P1b), and
## specks in the air.
func _add_ambience() -> void:
	lighting = AreaLighting.new()
	lighting.setup(ambience, dark)
	add_child(lighting)
	var decor: TileMapLayer = get_node_or_null(^"Decor") as TileMapLayer
	tile_glows = Ambience.tile_glows([height_layer, decor])
	motes = Motes.new()
	motes.kind = ambience
	add_child(motes)
	# Nature (P1c): tall trees the hero walks behind, wind, water, petals and mist.
	scenery = Scenery.new()
	add_child(scenery)
	scenery.build(decor)
	# Buildings (P1d): walls with a face and a top, pillars that stand, roofs with a ridge.
	scenery.build_stone(height_layer)
	relief = WallRelief.make(height_layer, grid.size, room_size)
	if relief != null:
		add_child(relief)
		move_child(relief, height_layer.get_index() + 1)
	sway = SwayLayer.take_from(decor)
	if sway != null:
		add_child(sway)
		move_child(sway, decor.get_index() + 1)
	water = WaterSurface.make(height_layer, grid.size)
	if water != null:
		add_child(water)
		move_child(water, height_layer.get_index() + 1)
		reflections = Reflections.new()
		reflections.setup(water, scenery)
		add_child(reflections)
		move_child(reflections, water.get_index() + 1)
	# Houses' windows, lit with the lamps (P2e): over the walls and whatever is painted on them,
	# under everything that stands in front of a wall.
	windows = WindowGlow.make(height_layer)
	if windows != null:
		add_child(windows)
		var under: Node = height_layer
		for layer: Node in [water, reflections, relief]:
			if layer != null and layer.get_index() > under.get_index():
				under = layer
		move_child(windows, under.get_index() + 1)
	petals = Petals.new()
	add_child(petals)
	move_child(petals, _shading.get_index() + 1)
	petals.setup(scenery.cherry_feet(), ground_at)
	if Ambience.has_mist(area_id):
		mist = Mist.new()
		add_child(mist)


## What `cell` is to something light landing on it: "open" ground, "water", or "" (a wall, a
## tree, off the map).
func ground_at(cell: Vector2i) -> String:
	if not grid.in_bounds(cell):
		return ""
	if height_layer.get_cell_atlas_coords(cell) == GreyboxTiles.coords("water"):
		return "water"
	return "" if grid.is_solid(cell) else "open"


## Where the hero, every enemy and everything that can be picked up stands (area px): a tree's
## crown fades while any of them is behind it, so nothing that matters is hidden. Grass, pots
## and signs don't count: they stay where they are, and the trees would never come back.
func standing_points() -> Array[Vector2]:
	var out: Array[Vector2] = [player.position]
	for child: Node in interactables.get_children():
		if not child is Node2D or not (child as Node2D).visible:
			continue
		if child is Enemy or child is ItemPickup or child.has_method(&"collect"):
			out.append((child as Node2D).position)
	return out


## Every light to draw right now (AreaLighting.light dictionaries).
## - In a `dark` area: a pool for each of the rule's lights (lights()), at the rule's place and
##   radius, and nothing else that could show what the rule says is dark. Glows sit inside a
##   light's fully lit core.
## - Elsewhere: a glow for everything that shines; and where the ambient colour is dim, a pool
##   round the hero and round each glow.
func scene_lights() -> Array:
	var out: Array = []
	var glows: Array = glows_now()
	if dark:
		for rule: Dictionary in lights():
			out.append(AreaLighting.light(rule["at"], float(rule["radius"]), RULE_TINT, AreaLighting.POOL, 1.0, false, true))
		for glow: Dictionary in glows:
			if _inside_a_core(glow, lights()):
				out.append(AreaLighting.light(glow["at"], float(glow["radius"]), glow["color"], AreaLighting.GLOW, float(glow["strength"]), glow["flickers"]))
		return out
	# Indoors the hero stands in a pool of his own. Outdoors the night is dim, not dark, and
	# only lamps make pools.
	if lighting.is_dim() and not has_daylight():
		out.append(AreaLighting.light(player.position + Vector2(0, -8), Ambience.HERO_POOL, Color.WHITE, AreaLighting.POOL))
	var tint: float = NIGHT_POOL_TINT if has_daylight() else POOL_TINT
	var strength: float = NIGHT_POOL if has_daylight() else 1.0
	for glow: Dictionary in glows:
		if lighting.is_dim():
			out.append(AreaLighting.light(glow["at"], float(glow["radius"]) * Ambience.REACH, Color.WHITE.lerp(glow["color"], tint), AreaLighting.POOL, strength, glow["flickers"]))
		out.append(AreaLighting.light(glow["at"], float(glow["radius"]), glow["color"], AreaLighting.GLOW, float(glow["strength"]), glow["flickers"]))
	return out


## Everything that glows right now (Ambience.glow dictionaries): the tiles that give light,
## burning torches, crystals, and a lantern the hero carries.
func glows_now() -> Array:
	var out: Array = Ambience.shining(tile_glows, GameState.day_clock().lamps_lit(GameState.minute))
	for child: Node in interactables.get_children():
		if child is Torch and (child as Torch).is_lit():
			out.append(Ambience.glow((child as Torch).position + Torch.FLAME_AT, 30.0, Ambience.FIRE, 0.40, true))
		elif child is CrystalSwitch:
			var crystal: CrystalSwitch = child
			out.append(Ambience.glow(crystal.position + Vector2(8, 6), 18.0, CrystalSwitch.BLUE if crystal.is_on() else CrystalSwitch.RED, 0.30, false))
	if hero_light_radius() > DIM_RADIUS:
		out.append(Ambience.glow(player.position + Vector2(0, -8), hero_light_radius() * 0.5, Ambience.LAMP, 0.16, true))
	return out


## Whether `glow` lies wholly inside the fully lit core of one of `rule_lights`: there it can
## add its colour without showing anything the rule says is dark.
static func _inside_a_core(glow: Dictionary, rule_lights: Array) -> bool:
	for rule: Dictionary in rule_lights:
		var core: float = float(rule["radius"]) * LightRules.CORE
		if (glow["at"] as Vector2).distance_to(rule["at"]) + float(glow["radius"]) <= core:
			return true
	return false


## The hero stepped into a pit: PIT_DAMAGE off their hearts and gone for PIT_TIME, then back on
## the last safe cell they stood on (or, if that was their last heart, at the entrance).
func fall_into_pit() -> void:
	if is_in_pit() or _dying:
		return
	_pit_left = PIT_TIME
	player.controls_enabled = false
	player.hurt_box.enabled = false
	# Into the middle of the pit, and no sliding on across it.
	player.motor.place(player.motor.cell)
	player.fall_in(PIT_TIME)
	player.sync_from_motor()
	EventBus.sound.emit(&"fall")
	GameState.damage(PIT_DAMAGE)


## True from the moment the hero drops into a pit until they're back at its edge.
func is_in_pit() -> bool:
	return _pit_left > 0.0


func _climb_out() -> void:
	_pit_left = 0.0
	if _dying:
		return
	_end_pit_fall()
	player.motor.place(_safe_cell)
	player.motor.invincible_left = PlayerMotor.INVINCIBLE_TIME
	player.sync_from_motor()
	player.controls_enabled = not is_talking()
	update_room()


func _end_pit_fall() -> void:
	player.end_fall()
	player.hurt_box.enabled = true


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
			if child is HeartContainer:
				player.hold_up(&"heart_container")
			var follow: Variant = child.get(&"dialogue_id")
			if typeof(follow) == TYPE_STRING_NAME and follow != &"" and open_dialogue(follow):
				continue
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
	_pit_left = 0.0
	_end_pit_fall()
	_safe_cell = _entrance_cell
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
	# A door that keeps hours is shut outside them (GDD §6): the hero stays, and is told.
	if is_shut(exit):
		_say_shut(exit)
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
	if is_in_pit():
		return
	update_room()
	if terrain.is_pit(cell):
		fall_into_pit()
		return
	_safe_cell = cell
	var exit: AreaExit = exit_at(cell)
	if exit != null:
		take_exit(exit)
	elif shut_door_in_front() != null:
		# He has walked up to a door that is shut: he is told why it won't open.
		_say_shut(shut_door_in_front())


func _on_dialogue_closed() -> void:
	player.controls_enabled = true
	if _ending_due:
		show_ending()


## Leaves for the ending screen (the game's last conversation just closed). The hero's place
## is kept, so "Keep exploring" brings them back here.
func show_ending() -> void:
	_ending_due = false
	_travelling = true
	player.controls_enabled = false
	GameState.update_player(area_id, player.motor.cell)
	travel.call(ENDING_SCENE)


## A moment's near-freeze for weight (EventBus.hit_stop): the game runs at HIT_STOP_SCALE for
## `seconds` of real time. Overlapping stops last until the latest ends.
func hit_stop(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_hit_stop_until = maxi(_hit_stop_until, Time.get_ticks_msec() + int(seconds * 1000.0))
	Engine.time_scale = HIT_STOP_SCALE


func is_hit_stopped() -> bool:
	return _hit_stop_until > 0


func _end_hit_stop() -> void:
	_hit_stop_until = 0
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	_end_hit_stop()


func _on_quest_announced(quest_id: StringName, what: StringName) -> void:
	hud.show_notice(Quests.announcement(quest_id, what))


func _on_quit_to_title() -> void:
	_travelling = true
	player.controls_enabled = false
	travel.call(TITLE_SCENE)


## The item menu's choice: something for the item button is put on it; food is eaten.
func _on_item_chosen(item_id: StringName) -> void:
	var item: Dictionary = DataRegistry.get_item(item_id)
	if not Food.is_food(item):
		GameState.equip(item_id)
	elif GameState.eat(item_id):
		EventBus.sound.emit(&"eat")
		hud.show_message(ATE_WORDS % [str(item.get("name", item_id)), Food.gives_text(item)])
	else:
		EventBus.sound.emit(&"nope")
		hud.show_message(NOT_HUNGRY_WORDS)


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


func _on_flag_set(flag: StringName, value: Variant) -> void:
	if flag == ENDING_FLAG and value == true:
		_ending_due = true
	for child: Node in interactables.get_children():
		(child as Node2D).queue_redraw()
	_refresh_doors()


## Closed doors fill and seal their cells (nothing passes, not even arrows); open ones don't.
## Shutters that stay open remember opening.
func _refresh_doors() -> void:
	for door: DungeonDoor in doors():
		door.latch()
		var open: bool = door.is_open()
		if open and _door_open.has(door) and not _door_open[door] and door.kind == DungeonState.SHUTTER:
			EventBus.sound.emit(&"solved")
		_door_open[door] = open
		for cell: Vector2i in door.cells():
			terrain.set_occupied(cell, not open)
			terrain.set_sealed(cell, not open)


## When the last enemy sharing a clear flag falls, the flag is set (a shutter may open).
func _on_enemy_died(enemy: Enemy) -> void:
	if enemy.clear_flag == &"":
		return
	for other: Enemy in enemies():
		if other.clear_flag == enemy.clear_flag and not other.is_dead():
			return
	GameState.set_flag(enemy.clear_flag, true)


func _update_hud() -> void:
	hud.set_clock(GameState.time_text())
	hud.set_area(area_text())
	# The corner says only what there is to say: nothing carried, no line.
	hud.set_items(carrying_text() if not GameState.inventory.is_empty() else "")
	hud.set_equipped(equipped_text() if not DataRegistry.get_item(GameState.equipped).is_empty() else "")
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
