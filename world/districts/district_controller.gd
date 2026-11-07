class_name DistrictController
extends Node2D
## Runs one district scene (docs/TECH_DESIGN.md §3.3, §4). Builds the HeightGrid from the
## `Height` layer, draws the water for the current level, places the player and the boat,
## and redraws when the district's water level changes. One scene serves every level.
##
## The boat (M3): it floats only on deep water. If a water change grounds it, it moves to
## the nearest deep cell; with no deep water left it waits at sea off the Harbour, and the
## player walks out from there to board it. Sailing off the map's edge goes to the sea.
##
## Expects children: Height, HeightShading, Water, PointsOfInterest, Harbour, Mooring, Boat,
## Player, HUD. PlayerSpawn is optional (where a new game starts).

@export var district_id: StringName = &"st_aud"

var grid: HeightGrid
var terrain: TerrainQuery
## How long the last water redraw took, in microseconds (budget: TECH_DESIGN §11).
var last_redraw_usec: int = 0
## Changes scene. Tests replace it to watch travel without leaving the scene.
var travel: Callable

var _leaving: bool = false

@onready var height_layer: TileMapLayer = $Height
@onready var water_layer: TileMapLayer = $Water
@onready var player: PlayerController = $Player
@onready var boat: BoatController = $Boat
@onready var harbour: HarbourMarker = $Harbour
@onready var points: Node2D = $PointsOfInterest
@onready var _mooring: Marker2D = $Mooring
@onready var _shading: HeightShading = $HeightShading
@onready var _hud: DistrictHud = $HUD


func _init() -> void:
	travel = _change_scene


func _ready() -> void:
	if GameState.get_water_level(district_id) == &"":
		GameState.new_game()
	grid = HeightGridBuilder.from_layer(height_layer)
	terrain = TerrainQuery.new(grid)
	_shading.show_grid(grid)
	_redraw_water()
	var height: int = water_height()
	var arriving: bool = _is_arriving()
	var bounds: Rect2i = Rect2i(Vector2i.ZERO, grid.size * GreyboxTiles.TILE_SIZE)
	player.setup(terrain, height, harbour.cell() if arriving else _start_cell(), _start_stamina(), bounds)
	player.motor.fell.connect(_on_player_fell)
	boat.setup(terrain, height)
	boat.edge_reached.connect(_on_boat_edge)
	if arriving:
		_arrive_from_sea()
	else:
		_restore_boat()
	EventBus.water_level_changed.connect(_on_water_level_changed)
	EventBus.flag_set.connect(_on_flag_set)
	_refresh_points()
	_update_hud()


func _process(_delta: float) -> void:
	if _leaving:
		return
	var motor: PlayerMotor = player.motor
	GameState.update_player(district_id, motor.cell, motor.level, motor.stamina, motor.state_name == PlayerMotor.ON_BOAT)
	if boat.present:
		GameState.set_boat(district_id, boat.motor.cell, boat.motor.heading)
	harbour.boat_waiting = boat_waiting_offshore()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_cycle_water") and OS.is_debug_build():
		cycle_water_level()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
		interact()
		get_viewport().set_input_as_handled()


## The current water height, from the district's level in GameState.
func water_height() -> int:
	var current: String = String(GameState.get_water_level(district_id))
	for level: Dictionary in DataRegistry.get_district(district_id).get("levels", []):
		if str(level["id"]) == current:
			return int(level["water_height"])
	return 0


## Debug: the district's next water level, wrapping round. Bypasses the flood network.
func cycle_water_level() -> void:
	var levels: PackedStringArray = DataRegistry.level_ids(district_id)
	var index: int = levels.find(String(GameState.get_water_level(district_id)))
	GameState.set_water_level(district_id, StringName(levels[(index + 1) % levels.size()]))


# --- Interacting -----------------------------------------------------------

## Does the one thing interact means right now: go ashore, board, walk out to the waiting
## boat, or use the point of interest underfoot. Returns true if something happened.
func interact() -> bool:
	if boat.rider != null:
		return disembark()
	if can_board():
		return board()
	if can_walk_out_to_boat():
		return walk_out_to_boat()
	var point: PointOfInterest = point_under_player()
	if point == null or not point.usable or player.motor.state_name != PlayerMotor.GROUND:
		return false
	GameState.set_flag(point.visited_flag, true)
	_hud.show_message(point.used_message)
	return true


## The point of interest the player is standing on, or null.
func point_under_player() -> PointOfInterest:
	for child: Node in points.get_children():
		var point: PointOfInterest = child as PointOfInterest
		if point != null and point.covers(player.motor.cell):
			return point
	return null


func can_board() -> bool:
	var on_foot: bool = player.motor.state_name == PlayerMotor.GROUND or player.motor.state_name == PlayerMotor.SWIM
	return boat.present and boat.rider == null and on_foot and BoatRules.can_board(player.motor.cell, boat.motor.cell)


func board() -> bool:
	if not can_board():
		return false
	boat.take_aboard(player)
	return true


## Where the rider would step ashore now, or BoatRules.NO_CELL.
func landing_cell() -> Vector2i:
	return BoatRules.landing_cell(terrain, boat.motor.cell, boat.motor.heading, water_height())


func disembark() -> bool:
	if boat.rider == null:
		return false
	var landing: Vector2i = landing_cell()
	if landing == BoatRules.NO_CELL:
		_hud.show_message("Nowhere to land here.")
		return false
	boat.put_ashore()
	player.disembark(landing)
	return true


## The boat is at sea, waiting off this district's harbour.
func boat_waiting_offshore() -> bool:
	return str(GameState.boat.get("where", "")) == String(WorldPaths.SEA_ID) \
		and str(GameState.boat.get("moored_at", "")) == String(district_id)


func can_walk_out_to_boat() -> bool:
	return boat_waiting_offshore() and player.motor.state_name == PlayerMotor.GROUND \
		and player.motor.cell == harbour.cell()


## Walks out along the harbour to the boat waiting at sea, and sets off.
func walk_out_to_boat() -> bool:
	if not can_walk_out_to_boat():
		return false
	GameState.set_boat(WorldPaths.SEA_ID, GameState.boat_cell(), float(GameState.boat.get("heading", 0.0)))
	_leave_for_sea()
	return true


# --- Arriving and leaving --------------------------------------------------

func _is_arriving() -> bool:
	return bool(GameState.player.get("arriving", false)) and str(GameState.player.get("district", "")) == String(district_id)


## Came in from the sea: sail in to the mooring if it's deep, otherwise the boat stays at
## sea (where the sea map left it) and the player comes ashore at the harbour.
func _arrive_from_sea() -> void:
	GameState.player["arriving"] = false
	var mooring: Vector2i = _mooring_cell()
	if BoatRules.floats(terrain, mooring, water_height()):
		boat.set_present(true)
		boat.place(mooring, _mooring.rotation)
		boat.take_aboard(player)
		GameState.set_boat(district_id, mooring, _mooring.rotation)
	else:
		boat.set_present(false)
		_hud.show_message("The water's too low to sail in. The boat waits off the harbour.")


## Puts the boat back where GameState says it is. In a new game it starts at the mooring.
func _restore_boat() -> void:
	var saved: Dictionary = GameState.boat
	if saved.is_empty():
		if BoatRules.floats(terrain, _mooring_cell(), water_height()):
			boat.set_present(true)
			boat.place(_mooring_cell(), _mooring.rotation)
			GameState.set_boat(district_id, _mooring_cell(), _mooring.rotation)
		else:
			boat.set_present(false)
			GameState.set_boat(WorldPaths.SEA_ID, GameState.NO_CELL, _mooring.rotation, district_id)
		return
	if str(saved.get("where", "")) != String(district_id):
		boat.set_present(false)
		return
	boat.set_present(true)
	var cell: Vector2i = GameState.boat_cell()
	boat.place(cell if grid.in_bounds(cell) else _mooring_cell(), float(saved.get("heading", 0.0)))
	if bool(GameState.player.get("on_boat", false)):
		boat.take_aboard(player)
	_keep_boat_afloat(false)


func _on_boat_edge(_direction: Vector2) -> void:
	if boat.rider == null or _leaving:
		return
	# Out to sea: the sea map brings the boat out at this district's port.
	GameState.set_boat(WorldPaths.SEA_ID, GameState.NO_CELL, boat.motor.heading)
	_leave_for_sea()


func _leave_for_sea() -> void:
	_leaving = true
	GameState.begin_voyage(WorldPaths.SEA_ID, district_id)
	travel.call(WorldPaths.SEA_SCENE)


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


# --- Water -----------------------------------------------------------------

func _on_water_level_changed(changed_district: StringName, _level: StringName) -> void:
	if changed_district != district_id:
		return
	_redraw_water()
	var height: int = water_height()
	player.motor.set_water_height(height)
	boat.set_water_height(height)
	_keep_boat_afloat(true)
	player.sync_from_motor()
	_refresh_points()
	_hud.flash()


## A grounded boat moves to the nearest deep cell, rider and all. With no deep water left
## it goes out to wait at sea off the harbour, and a rider steps ashore where it was.
func _keep_boat_afloat(announce: bool) -> void:
	var height: int = water_height()
	if not boat.present or BoatRules.floats(terrain, boat.motor.cell, height):
		return
	var target: Vector2i = BoatRules.nearest_deep_cell(terrain, boat.motor.cell, height)
	if target != BoatRules.NO_CELL:
		boat.place(target, boat.motor.heading)
		if announce:
			_hud.show_message("The boat drifted out to deeper water.")
		return
	var aground: Vector2i = boat.motor.cell
	if boat.rider != null:
		boat.put_ashore()
		player.disembark(aground)
	boat.set_present(false)
	GameState.set_boat(WorldPaths.SEA_ID, GameState.NO_CELL, boat.motor.heading, district_id)
	if announce:
		_hud.show_message("Too shallow for the boat. It waits at sea off the harbour.")


func _on_flag_set(_flag: StringName, _value: Variant) -> void:
	for child: Node in points.get_children():
		(child as Node2D).queue_redraw()


func _on_player_fell(levels: int, damaging: bool) -> void:
	if damaging:
		_hud.show_message("You fell %d levels. That would hurt (health arrives in M7)." % levels)


func _redraw_water() -> void:
	var started: int = Time.get_ticks_usec()
	var height: int = water_height()
	water_layer.clear()
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			match terrain.cell_kind(cell, height):
				TerrainQuery.CellKind.SHALLOW:
					water_layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_SHALLOW)
				TerrainQuery.CellKind.DEEP:
					water_layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_DEEP)
	last_redraw_usec = Time.get_ticks_usec() - started


func _refresh_points() -> void:
	var height: int = water_height()
	for child: Node in points.get_children():
		var point: PointOfInterest = child as PointOfInterest
		if point != null:
			point.usable = point.is_usable_at(terrain, height)


# --- Starting positions ----------------------------------------------------

func _mooring_cell() -> Vector2i:
	return PlayerMotor.cell_of(_mooring.position)


func _start_cell() -> Vector2i:
	var saved: Dictionary = GameState.player
	if str(saved.get("district", "")) == String(district_id) and saved.has("cell"):
		var cell: Array = saved["cell"]
		var at: Vector2i = Vector2i(int(cell[0]), int(cell[1]))
		if grid.in_bounds(at):
			return at
	var spawn: Marker2D = get_node_or_null("PlayerSpawn")
	return PlayerMotor.cell_of(spawn.position) if spawn != null else harbour.cell()


func _start_stamina() -> float:
	return float(GameState.player.get("stamina", PlayerMotor.STAMINA_MAX))


# --- HUD -------------------------------------------------------------------

func _update_hud() -> void:
	var motor: PlayerMotor = player.motor
	var district_name: String = str(DataRegistry.get_district(district_id).get("name", district_id))
	_hud.set_water("%s   water: %s (height %d)" % [district_name, GameState.get_water_level(district_id), water_height()])
	_hud.set_status("%s   level %d   cell %d,%d" % [_activity(motor), motor.level, motor.cell.x, motor.cell.y])
	_hud.set_stamina(motor.stamina / PlayerMotor.STAMINA_MAX, motor.exhausted)
	_hud.set_prompt(_prompt_text(motor))


func _activity(motor: PlayerMotor) -> String:
	match motor.state_name:
		PlayerMotor.ON_BOAT:
			return "Sailing"
		PlayerMotor.SWIM:
			return "Swimming"
		PlayerMotor.CLIMB:
			return "Climbing %d%%" % roundi(motor.climb_progress() * 100.0)
	if terrain.cell_kind(motor.cell, water_height()) == TerrainQuery.CellKind.SHALLOW:
		return "Wading"
	return "Sprinting" if motor.sprinting else "On foot"


func _prompt_text(motor: PlayerMotor) -> String:
	if boat.rider != null:
		return "[E] Go ashore" if landing_cell() != BoatRules.NO_CELL else "Sail off the edge to reach the open sea"
	if can_board():
		return "[E] Board the boat"
	if can_walk_out_to_boat():
		return "[E] Walk out to the boat"
	var point: PointOfInterest = point_under_player()
	if point == null:
		return ""
	var done: String = "  (done)" if point.visited() else ""
	if not point.usable or motor.state_name != PlayerMotor.GROUND:
		return "%s: needs dry ground%s" % [point.label, done]
	return "[E] %s%s" % [point.label, done]
