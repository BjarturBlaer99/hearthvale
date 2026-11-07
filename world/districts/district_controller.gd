class_name DistrictController
extends Node2D
## Runs one district scene (docs/TECH_DESIGN.md §3.3). Builds the HeightGrid from the
## `Height` layer, draws the water for the current level, places the player, and redraws
## when the district's water level changes. One scene serves every water level.
## Expects children: Height, HeightShading, Water, PointsOfInterest, PlayerSpawn, Player, HUD.

@export var district_id: StringName = &"st_aud"

var grid: HeightGrid
var terrain: TerrainQuery
## How long the last water redraw took, in microseconds (budget: TECH_DESIGN §11).
var last_redraw_usec: int = 0

@onready var height_layer: TileMapLayer = $Height
@onready var water_layer: TileMapLayer = $Water
@onready var player: PlayerController = $Player
@onready var points: Node2D = $PointsOfInterest
@onready var _shading: HeightShading = $HeightShading
@onready var _spawn: Marker2D = $PlayerSpawn
@onready var _hud: DistrictHud = $HUD


func _ready() -> void:
	if GameState.get_water_level(district_id) == &"":
		GameState.new_game()
	grid = HeightGridBuilder.from_layer(height_layer)
	terrain = TerrainQuery.new(grid)
	_shading.show_grid(grid)
	_redraw_water()
	var bounds: Rect2i = Rect2i(Vector2i.ZERO, grid.size * GreyboxTiles.TILE_SIZE)
	player.setup(terrain, water_height(), _start_cell(), _start_stamina(), bounds)
	player.motor.fell.connect(_on_player_fell)
	EventBus.water_level_changed.connect(_on_water_level_changed)
	EventBus.flag_set.connect(_on_flag_set)
	_refresh_points()
	_update_hud()


func _process(_delta: float) -> void:
	var motor: PlayerMotor = player.motor
	GameState.update_player(district_id, motor.cell, motor.level, motor.stamina)
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


## The point of interest the player is standing on, or null.
func point_under_player() -> PointOfInterest:
	for child: Node in points.get_children():
		var point: PointOfInterest = child as PointOfInterest
		if point != null and point.covers(player.motor.cell):
			return point
	return null


## Uses the point under the player if they can (on foot, and the water allows it).
func interact() -> bool:
	var point: PointOfInterest = point_under_player()
	if point == null or not point.usable or player.motor.state_name != PlayerMotor.GROUND:
		return false
	GameState.set_flag(point.visited_flag, true)
	_hud.show_message(point.used_message)
	return true


func _on_water_level_changed(changed_district: StringName, _level: StringName) -> void:
	if changed_district != district_id:
		return
	_redraw_water()
	player.motor.set_water_height(water_height())
	player.sync_from_motor()
	_refresh_points()
	_hud.flash()


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


func _start_cell() -> Vector2i:
	var saved: Dictionary = GameState.player
	if str(saved.get("district", "")) == String(district_id) and saved.has("cell"):
		var cell: Array = saved["cell"]
		var at: Vector2i = Vector2i(int(cell[0]), int(cell[1]))
		if grid.in_bounds(at):
			return at
	return PlayerMotor.cell_of(_spawn.position)


func _start_stamina() -> float:
	return float(GameState.player.get("stamina", PlayerMotor.STAMINA_MAX))


func _update_hud() -> void:
	var motor: PlayerMotor = player.motor
	var district_name: String = str(DataRegistry.get_district(district_id).get("name", district_id))
	_hud.set_water("%s   water: %s (height %d)" % [district_name, GameState.get_water_level(district_id), water_height()])
	_hud.set_status("%s   level %d   cell %d,%d" % [_activity(motor), motor.level, motor.cell.x, motor.cell.y])
	_hud.set_stamina(motor.stamina / PlayerMotor.STAMINA_MAX, motor.exhausted)
	_hud.set_prompt(_prompt_text(motor))


func _activity(motor: PlayerMotor) -> String:
	match motor.state_name:
		PlayerMotor.SWIM:
			return "Swimming"
		PlayerMotor.CLIMB:
			return "Climbing %d%%" % roundi(motor.climb_progress() * 100.0)
	if terrain.cell_kind(motor.cell, water_height()) == TerrainQuery.CellKind.SHALLOW:
		return "Wading"
	return "Sprinting" if motor.sprinting else "On foot"


func _prompt_text(motor: PlayerMotor) -> String:
	var point: PointOfInterest = point_under_player()
	if point == null:
		return ""
	var done: String = "  (done)" if point.visited() else ""
	if not point.usable or motor.state_name != PlayerMotor.GROUND:
		return "%s: needs dry ground%s" % [point.label, done]
	return "[E] %s%s" % [point.label, done]
