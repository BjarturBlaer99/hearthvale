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
## - the Well's cells are water to the can (fills_can_at).
## Nothing else in the area changes for any of it: no hit box, no collision, no timing.
## It sits at the area's origin, just over what lies on the ground.

var area: AreaController

## The spot of each building, by id.
var _spots: Dictionary[StringName, BuildingSpot] = {}
## The ridge strips of each building's roof, by id.
var _ridges: Dictionary[StringName, Array] = {}
## How each building was shown at the last sync: "x,y:site" or "x,y:big", by id.
var _shown: Dictionary[StringName, String] = {}
## The cells this has filled.
var _filled: Dictionary[Vector2i, bool] = {}


func _init() -> void:
	name = "PlacedBuildings"


## Takes up the area it is in, and shows what stands there already (a loaded game).
func setup(area_controller: AreaController) -> void:
	area = area_controller
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
	_fill_cells()
	queue_redraw()


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
