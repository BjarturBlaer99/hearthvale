class_name SeaController
extends Node2D
## The open sea between districts (TECH_DESIGN §1, world/sea). The water never changes and
## the player is always aboard. Sailing into a district's SeaPort goes there; leaving a
## district by sea brings the boat back out at that district's port.
## Expects children: Height, HeightShading, Water, Ports (SeaPort nodes), Boat, Player, HUD.

const WATER_HEIGHT: int = 4
const FIRST_DISTRICT: StringName = &"st_aud"

var grid: HeightGrid
var terrain: TerrainQuery
## Changes scene. Tests replace it to watch travel without leaving the scene.
var travel: Callable

var _leaving: bool = false

@onready var height_layer: TileMapLayer = $Height
@onready var water_layer: TileMapLayer = $Water
@onready var ports: Node2D = $Ports
@onready var boat: BoatController = $Boat
@onready var player: PlayerController = $Player
@onready var _shading: HeightShading = $HeightShading
@onready var _hud: DistrictHud = $HUD


func _init() -> void:
	travel = _change_scene


func _ready() -> void:
	if GameState.water.is_empty():
		GameState.new_game()
	grid = HeightGridBuilder.from_layer(height_layer)
	terrain = TerrainQuery.new(grid)
	_shading.show_grid(grid)
	_draw_water()
	var start: Array = _start()
	var bounds: Rect2i = Rect2i(Vector2i.ZERO, grid.size * GreyboxTiles.TILE_SIZE)
	boat.setup(terrain, WATER_HEIGHT)
	boat.set_present(true)
	boat.place(start[0], start[1])
	player.setup(terrain, WATER_HEIGHT, start[0], float(GameState.player.get("stamina", PlayerMotor.STAMINA_MAX)), bounds)
	boat.take_aboard(player)
	GameState.player["arriving"] = false
	boat.cell_changed.connect(_on_boat_cell)
	_record()
	_update_hud()


func _process(_delta: float) -> void:
	if _leaving:
		return
	_record()
	_update_hud()


## The SeaPort for `district`, or null.
func port_for(district: StringName) -> SeaPort:
	for child: Node in ports.get_children():
		var port: SeaPort = child as SeaPort
		if port != null and port.district_id == district:
			return port
	return null


## Sets course for `port`'s district. The boat is recorded as waiting off it, in case the
## water there is too low to sail in; the district takes it in if it can.
func enter_district(port: SeaPort) -> void:
	_leaving = true
	GameState.set_boat(WorldPaths.SEA_ID, port.exit_cell, port.exit_heading(), port.district_id)
	GameState.begin_voyage(port.district_id, WorldPaths.SEA_ID)
	travel.call(WorldPaths.scene_for(port.district_id))


func _on_boat_cell(cell: Vector2i) -> void:
	if _leaving:
		return
	for child: Node in ports.get_children():
		var port: SeaPort = child as SeaPort
		if port != null and port.covers(cell):
			enter_district(port)
			return


## [cell, heading]: where the boat was left at sea, else the port of the district just
## left, else the first district's port.
func _start() -> Array:
	var cell: Vector2i = GameState.boat_cell()
	if str(GameState.boat.get("where", "")) == String(WorldPaths.SEA_ID) and grid.in_bounds(cell):
		return [cell, float(GameState.boat.get("heading", 0.0))]
	var port: SeaPort = port_for(StringName(str(GameState.player.get("came_from", ""))))
	if port == null:
		port = port_for(FIRST_DISTRICT)
	return [port.exit_cell, port.exit_heading()]


func _record() -> void:
	var motor: PlayerMotor = player.motor
	GameState.update_player(WorldPaths.SEA_ID, motor.cell, motor.level, motor.stamina, true)
	GameState.set_boat(WorldPaths.SEA_ID, boat.motor.cell, boat.motor.heading)


func _draw_water() -> void:
	water_layer.clear()
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			match terrain.cell_kind(cell, WATER_HEIGHT):
				TerrainQuery.CellKind.SHALLOW:
					water_layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_SHALLOW)
				TerrainQuery.CellKind.DEEP:
					water_layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_DEEP)


func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _update_hud() -> void:
	_hud.set_water("The Spillway   open sea")
	_hud.set_status("Sailing   cell %d,%d" % [boat.motor.cell.x, boat.motor.cell.y])
	_hud.set_stamina(player.motor.stamina / PlayerMotor.STAMINA_MAX, player.motor.exhausted)
	_hud.set_prompt("Sail into a marked approach to go ashore")
