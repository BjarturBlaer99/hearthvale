class_name PlacedThings
extends Node2D
## What the hero has set down on his land, as it lies and stands in the area (the Homestead,
## phase 2; docs/TECH_DESIGN.md §30). GameState.homestead() says what is where; this keeps the
## area in step with it, whenever it changes (EventBus.homestead_changed):
## - lying things (paths, floors, flower beds) are drawn here, flat on the ground under
##   everyone, as the field's soil is; they are never in the way;
## - each standing thing is a PlacedThing in the area's Interactables, sorted by depth with
##   the hero; one that blocks fills its cell the moment it is set down and frees it the moment
##   it is taken up (TerrainQuery.set_occupied, as a villager or a furnishing does).
## Nothing else in the area changes for any of it: no hit box, no collision, no timing.
## It sits at the area's origin, just over the ground and its shading.

## The rim of a lying thing where nothing lies beside it: a dark line a pixel wide.
const RIM: Color = Color(0.20, 0.13, 0.10, 0.55)

var area: AreaController

## The node of what stands in each cell.
var _standing: Dictionary[Vector2i, PlacedThing] = {}
## The cells this has filled.
var _blocked: Dictionary[Vector2i, bool] = {}


func _init() -> void:
	name = "PlacedThings"


## Takes up the area it is in, and shows what is set down there already (a loaded game).
func setup(area_controller: AreaController) -> void:
	area = area_controller
	EventBus.homestead_changed.connect(sync)
	sync()


## The node of what stands in `cell`, or null.
func standing_node(cell: Vector2i) -> PlacedThing:
	return _standing.get(cell)


## Every standing thing's node, in no order.
func standing_nodes() -> Array[PlacedThing]:
	var out: Array[PlacedThing] = []
	out.assign(_standing.values())
	return out


## Brings the area in step with the homestead: nodes for what stands, the cells they fill,
## and the picture of what lies.
func sync() -> void:
	var home: Homestead = GameState.homestead()
	var wanted: Dictionary[Vector2i, Dictionary] = {}
	for thing: Dictionary in home.placed(Placement.STANDING):
		wanted[thing["cell"]] = thing
	for cell: Vector2i in _standing.keys():
		if not wanted.has(cell) or _standing[cell].item_id != wanted[cell]["item"]:
			_standing[cell].free()
			_standing.erase(cell)
	for cell: Vector2i in wanted:
		if not _standing.has(cell):
			var node: PlacedThing = PlacedThing.new()
			node.name = "Placed_%d_%d" % [cell.x, cell.y]
			node.position = Vector2(cell * GreyboxTiles.TILE_SIZE)
			area.interactables.add_child(node)
			_standing[cell] = node
		_standing[cell].show_as(wanted[cell]["item"], int(wanted[cell]["age"]))
	# A neighbour set down or taken up changes how a fence is joined.
	for node: PlacedThing in _standing.values():
		node.queue_redraw()
	_fill_cells()
	queue_redraw()


## Fills the cell of every standing thing that blocks, and frees those this had filled that
## no longer hold one.
func _fill_cells() -> void:
	var now: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _standing:
		if _standing[cell].blocks():
			now[cell] = true
	for cell: Vector2i in _blocked:
		if not now.has(cell):
			area.terrain.set_occupied(cell, false)
	for cell: Vector2i in now:
		area.terrain.set_occupied(cell, true)
	_blocked = now


func _draw() -> void:
	var home: Homestead = GameState.homestead()
	var size: float = float(GreyboxTiles.TILE_SIZE)
	for thing: Dictionary in home.placed(Placement.LYING):
		var cell: Vector2i = thing["cell"]
		var origin: Vector2 = Vector2(cell) * size
		PlacedArt.draw_thing(self, DataRegistry.get_item(thing["item"]), 0, origin)
		# A rim on each side where nothing lies beside it, so a path reads as laid, not painted.
		if home.lying_at(cell + Vector2i.UP) == &"":
			draw_rect(Rect2(origin, Vector2(size, 1.0)), RIM)
		if home.lying_at(cell + Vector2i.DOWN) == &"":
			draw_rect(Rect2(origin + Vector2(0.0, size - 1.0), Vector2(size, 1.0)), RIM)
		if home.lying_at(cell + Vector2i.LEFT) == &"":
			draw_rect(Rect2(origin, Vector2(1.0, size)), RIM)
		if home.lying_at(cell + Vector2i.RIGHT) == &"":
			draw_rect(Rect2(origin + Vector2(size - 1.0, 0.0), Vector2(1.0, size)), RIM)
