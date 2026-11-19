class_name PlacedBuildings
extends Node2D
## The buildings of the hero's land, as they stand in the area (the Homestead, phase 3;
## docs/TECH_DESIGN.md §30). GameState.homestead() says which stand where, and whether each is
## a site today; this keeps the area in step with it whenever it changes
## (EventBus.homestead_changed, which a morning that finishes one emits too):
## - each is drawn flat on the ground, as the farmhouse's tiles are, with the shadow it casts
##   east and south, over the paths and floors under it (BuildingArt); a site is its one
##   picture; a roof's ridge is a strip of the area's scenery, sorted as the farmhouse's is, so
##   the hero walks behind it;
## - each is a BuildingSpot in the area's Interactables, which is what he faces;
## - each fills its cells (TerrainQuery.set_occupied): a site all of them, a building all but
##   its door;
## - the Well's cells are water to the can (fills_can_at);
## - a building with a room that stands has a door (an AreaExit on its door's cell, into its
##   room's entry "door") and, under the area's Entries, the entry "<id>_door" on its doorstep,
##   where its room's doormat leads: so the door follows the building wherever it stands.
## - a building whose data says "lit_at_night" (the Coop, the Barn, the Shed) has its windows
##   glow with the lamps, from dusk to dawn, once it stands (`glow`; tool polish, D11).
## Nothing else in the area changes for any of it: no hit box, no collision, no timing.
## It sits at the area's origin, just over what lies on the ground.

var area: AreaController

## The spot of each building, by id.
var _spots: Dictionary[StringName, BuildingSpot] = {}
## The ridge strips of each building's roof, by id.
var _ridges: Dictionary[StringName, Array] = {}
## How each building was shown at the last sync: "x,y:site" or "x,y:big", by id.
var _shown: Dictionary[StringName, String] = {}
## The door of each building with a room that stands, by id.
var _doors: Dictionary[StringName, AreaExit] = {}
## The cells this has filled.
var _filled: Dictionary[Vector2i, bool] = {}
## The glow of the standing buildings' windows, lit with the lamps (the area says when).
## Made in setup(), so one never set up leaves nothing behind.
var glow: WindowGlow


func _init() -> void:
	name = "PlacedBuildings"


## Takes up the area it is in, and shows what stands there already (a loaded game).
func setup(area_controller: AreaController) -> void:
	area = area_controller
	glow = WindowGlow.unlit("BuildingWindows")
	add_child(glow)
	EventBus.homestead_changed.connect(sync)
	sync()


## The spot of building `id`, or null.
func spot(id: StringName) -> BuildingSpot:
	return _spots.get(id)


## Every building's spot, by id.
func spots() -> Array[BuildingSpot]:
	var out: Array[BuildingSpot] = []
	for id: StringName in GameState.homestead().building_ids():
		if _spots.has(id):
			out.append(_spots[id])
	return out


## The ridge strips of building `id`'s roof (Sprite2D in the area's scenery).
func ridges_of(id: StringName) -> Array:
	return _ridges.get(id, [])


## The door of building `id` (an AreaExit into its room), or null for one with no room, or a site.
func door(id: StringName) -> AreaExit:
	return _doors.get(id)


## The entry before building `id`'s door, where its room's doormat leads.
static func door_entry(id: StringName) -> StringName:
	return StringName("%s_door" % id)


## Puts the entry "<id>_door" on the doorstep of every building with a room that stands in
## `area` (the homestead), under its Entries, and takes away those of buildings that are gone
## or a site. It runs before the hero is placed, so coming out of a room he arrives there.
static func mark_doors(area: AreaController) -> void:
	if not GameState.homestead_rules().is_land(area.area_id):
		return
	var entries: Node = area.get_node_or_null(^"Entries")
	if entries == null:
		return
	var home: Homestead = GameState.homestead()
	for id: StringName in DataRegistry.ids(&"buildings"):
		var building: Dictionary = DataRegistry.get_building(id)
		if not Buildings.has_door(building):
			continue
		var marker: Marker2D = entries.get_node_or_null(NodePath(String(door_entry(id)))) as Marker2D
		if not GameState.is_built(id):
			if marker != null:
				marker.free()
			continue
		if marker == null:
			marker = Marker2D.new()
			marker.name = String(door_entry(id))
			# Facing south, out of the door.
			marker.rotation = PI / 2.0
			entries.add_child(marker)
		marker.position = GridBody.cell_center(Buildings.doorstep_of(building, home.building_at(id)))


## Whether the can fills at `cell`: a cell of a building that fills it (the Well), standing.
func fills_can_at(cell: Vector2i) -> bool:
	var id: StringName = GameState.building_covering(area.area_id, cell)
	return id != &"" and GameState.is_built(id) and Buildings.fills_can(DataRegistry.get_building(id))


## Brings the area in step with the homestead: a spot, ridges and filled cells for each
## building, and the picture of all of them.
func sync() -> void:
	var home: Homestead = GameState.homestead()
	var ids: Array[StringName] = home.building_ids()
	for id: StringName in _spots.keys():
		if not ids.has(id):
			_spots[id].free()
			_spots.erase(id)
			_drop_ridges(id)
			_shown.erase(id)
	for id: StringName in ids:
		var at: Vector2i = home.building_at(id)
		var site: bool = not GameState.is_built(id)
		var big: bool = GameState.is_big(id)
		var shown: String = "%s:%s" % [Farm.key(at), "site" if site else ("big" if big else "")]
		if not _spots.has(id):
			var node: BuildingSpot = BuildingSpot.new()
			node.name = "Building_%s" % id
			area.interactables.add_child(node)
			_spots[id] = node
		if _shown.get(id, "") != shown:
			_spots[id].show_as(id, at)
			_drop_ridges(id)
			if not site:
				_stand_ridges(id, at, big)
			_shown[id] = shown
	_place_doors()
	mark_doors(area)
	_fill_cells()
	if glow != null:
		glow.set_windows(window_glass())
	queue_redraw()


## The glass of every window of the standing buildings that light theirs at night (area px).
func window_glass() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var home: Homestead = GameState.homestead()
	for id: StringName in home.building_ids():
		var building: Dictionary = DataRegistry.get_building(id)
		if not GameState.is_built(id) or not Buildings.lit_at_night(building):
			continue
		var origin: Vector2i = home.building_at(id) * GreyboxTiles.TILE_SIZE
		var laid: Dictionary = BuildingArt.tiles(building, GameState.is_big(id), false)
		for cell: Vector2i in laid:
			var glass: Variant = WindowGlow.BUILDING_GLASS.get(str(laid[cell]))
			if glass != null:
				out.append(Rect2(Vector2(origin + cell * GreyboxTiles.TILE_SIZE + (glass as Rect2i).position), Vector2((glass as Rect2i).size)))
	return out


## A door on the door's cell of every building with a room that stands, into its room; none
## for a site, or a building that is gone.
func _place_doors() -> void:
	var home: Homestead = GameState.homestead()
	for id: StringName in _doors.keys():
		if not home.has_building(id) or not GameState.is_built(id):
			_doors[id].free()
			_doors.erase(id)
	for id: StringName in home.building_ids():
		var building: Dictionary = DataRegistry.get_building(id)
		if not Buildings.has_door(building) or not GameState.is_built(id):
			continue
		if not _doors.has(id):
			var exit: AreaExit = AreaExit.new()
			exit.name = "Door_%s" % id
			exit.target_area = Buildings.room_of(building)
			exit.target_entry = &"door"
			area.interactables.add_child(exit)
			_doors[id] = exit
		_doors[id].position = Vector2(Buildings.door_cell(building, home.building_at(id)) * GreyboxTiles.TILE_SIZE)


## Raises the strips of ridge over building `id`'s roof, standing at `at`, among the area's
## scenery: sorted just inside its top edge, as the farmhouse's are, so whoever walks behind it
## is drawn first and the ridge covers his feet.
func _stand_ridges(id: StringName, at: Vector2i, big: bool) -> void:
	var strips: Array = []
	var origin: Vector2 = Vector2(at * GreyboxTiles.TILE_SIZE)
	for strip: Dictionary in BuildingArt.ridges(DataRegistry.get_building(id), big):
		var piece: Sprite2D = Sprite2D.new()
		piece.name = "Ridge_%s_%d" % [id, strips.size()]
		piece.texture = BuildingArt.relief()
		piece.region_enabled = true
		piece.region_rect = strip["region"]
		piece.centered = false
		piece.offset = Vector2(0.0, -float(ReliefAtlas.RIDGE_SIZE.y) - 1.0)
		piece.position = origin + Vector2(strip["cell"] as Vector2i) * BuildingArt.T + Vector2(0.0, 1.0)
		area.scenery.add_child(piece)
		strips.append(piece)
	_ridges[id] = strips


func _drop_ridges(id: StringName) -> void:
	for piece: Variant in _ridges.get(id, []):
		if is_instance_valid(piece):
			(piece as Node).free()
	_ridges.erase(id)


## Fills the cells of every building and site, and frees those this had filled that no longer
## hold one. A building's door is left open: it is walked into.
func _fill_cells() -> void:
	var home: Homestead = GameState.homestead()
	var now: Dictionary[Vector2i, bool] = {}
	for id: StringName in home.building_ids():
		for cell: Vector2i in Buildings.filled_cells(DataRegistry.get_building(id), home.building_at(id), GameState.is_built(id)):
			now[cell] = true
	for cell: Vector2i in _filled:
		if not now.has(cell):
			area.terrain.set_occupied(cell, false)
	for cell: Vector2i in now:
		area.terrain.set_occupied(cell, true)
	_filled = now


func _draw() -> void:
	var home: Homestead = GameState.homestead()
	for id: StringName in home.building_ids():
		var building: Dictionary = DataRegistry.get_building(id)
		BuildingArt.draw(self, building, Vector2(home.building_at(id) * GreyboxTiles.TILE_SIZE), GameState.is_big(id), not GameState.is_built(id))
