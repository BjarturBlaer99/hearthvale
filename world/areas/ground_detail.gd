class_name GroundDetail
extends Node2D
## The small still details on an area's ground (the warm-ground plan, step 3): drawn from
## world/tiles/ground_details.png, just above the Height layer and under everything else.
## GroundDetails (pure) says which cell gets which; this node gathers what holds a cell and
## draws. For show only: nothing that moves, hits or collides reads it, and nothing in it moves.
## - It is made only where the rules say (outdoors, the quarry and the dungeons; never a house
##   or a farm building's room).
## - It is put together as the area loads, and again on the hero's land when the homestead or
##   the plot changes (EventBus.homestead_changed, farm_changed): a detail goes from a cell that
##   gets something on it and comes back when it is cleared.
## - While something lies to be picked up, or the build ghost is over a cell, the detail there
##   isn't drawn.
## Drawn once into the node's canvas item and redrawn only on a change: nothing per frame.

const SHEET: Texture2D = preload("res://world/tiles/ground_details.png")
const T: int = GreyboxTiles.TILE_SIZE

var rules: GroundDetails
## Every cell that has a detail, and which (before the ones hidden for now).
var picks: Dictionary = {}
var _area: AreaController
## The Height layer's tiles: cell -> atlas coords. Read once; no map changes in play.
var _tiles: Dictionary = {}
## Cells whose detail isn't drawn for now: under something to pick up, or under the ghost.
var _hidden: Dictionary = {}
var _ghost_cells: Array[Vector2i] = []
var _dirty: bool = false


## A ground detail for `area`, or null where its kind of place has none.
static func make(area: AreaController) -> GroundDetail:
	var detail_rules: GroundDetails = GroundDetails.new(DataRegistry.get_rules(DataRegistry.RULES_GROUND_DETAIL))
	if not detail_rules.shows_in(area.ambience):
		return null
	var node: GroundDetail = GroundDetail.new()
	node.name = "GroundDetail"
	node.rules = detail_rules
	node._area = area
	for cell: Vector2i in area.height_layer.get_used_cells():
		node._tiles[cell] = area.height_layer.get_cell_atlas_coords(cell)
	return node


## Connects to what changes it, and puts it together. Called once it is in the area's tree.
func setup() -> void:
	var interactables: Node = _area.interactables
	interactables.child_entered_tree.connect(_on_thing_came)
	interactables.child_exiting_tree.connect(_on_thing_came)
	if GameState.homestead_rules().is_land(_area.area_id):
		EventBus.homestead_changed.connect(_changed)
		EventBus.farm_changed.connect(_changed)
	if _area.build != null:
		_area.build.ghost_moved.connect(_on_ghost_moved)
	rebuild()


## Puts the details together again from what holds each cell now.
func rebuild() -> void:
	_dirty = false
	picks = rules.place(_tiles, held_cells(_area))
	_refresh_hidden()
	queue_redraw()


## The detail drawn in `cell` now, or &"".
func shown_at(cell: Vector2i) -> StringName:
	if _hidden.has(cell):
		return &""
	return picks.get(cell, &"")


## How many details are drawn now.
func shown_count() -> int:
	var count: int = 0
	for cell: Vector2i in picks:
		if not _hidden.has(cell):
			count += 1
	return count


## Every cell of `area` that holds something, so neither it nor its neighbours get a detail:
## the tiles of every layer but the Height layer (decor, props), what stands in Interactables
## (but creatures, which walk about), the plot, and on the hero's land what lies or stands
## there and every building and site.
static func held_cells(area: AreaController) -> Dictionary:
	var held: Dictionary = {}
	for child: Node in area.get_children():
		if child is TileMapLayer and child != area.height_layer:
			for cell: Vector2i in (child as TileMapLayer).get_used_cells():
				held[cell] = true
	for child: Node in area.interactables.get_children():
		if not child is Node2D or child.is_queued_for_deletion() or _walks(child):
			continue
		var cell: Vector2i = cell_of(child as Node2D)
		if GameState.is_debris_cleared(area.area_id, cell) and (child is Rock or child is Breakable):
			continue
		held[cell] = true
	if area.plot != null:
		for cell: Vector2i in area.plot.cells():
			held[cell] = true
	if GameState.homestead_rules().is_land(area.area_id):
		var land: Homestead = GameState.homestead()
		for layer: StringName in Placement.LAYERS:
			for thing: Dictionary in land.placed(layer):
				held[thing["cell"]] = true
		for id: StringName in land.building_ids():
			for cell: Vector2i in Buildings.cells_of(DataRegistry.get_building(id), land.building_at(id)):
				held[cell] = true
	return held


## The cell `thing` is in: its own word for it, or the cell under its top-left corner.
static func cell_of(thing: Node2D) -> Vector2i:
	if thing.has_method(&"cell"):
		return thing.call(&"cell")
	return Vector2i((thing.position / float(T)).floor())


## Whether `thing` walks about (monsters, critters, animals): where it stood at the start holds
## nothing.
static func _walks(thing: Node) -> bool:
	return thing is Enemy or thing is Critter or thing is Animal


## Whether `thing` is something lying to be picked up.
static func _lies(thing: Node) -> bool:
	return thing is ItemDrop or thing is ItemPickup or thing is HeartPickup


func _changed() -> void:
	if _dirty:
		return
	_dirty = true
	rebuild.call_deferred()


func _on_thing_came(thing: Node) -> void:
	if _lies(thing):
		_refresh_hidden.call_deferred()


func _on_ghost_moved(cells: Array[Vector2i]) -> void:
	_ghost_cells = cells
	_refresh_hidden()


func _refresh_hidden() -> void:
	if not is_instance_valid(_area) or _area.interactables == null:
		return
	var hidden: Dictionary = {}
	for child: Node in _area.interactables.get_children():
		if child is ItemDrop and (child as ItemDrop).taken:
			continue
		if _lies(child) and not child.is_queued_for_deletion() and child.is_inside_tree():
			hidden[cell_of(child as Node2D)] = true
	for cell: Vector2i in _ghost_cells:
		hidden[cell] = true
	if hidden == _hidden:
		return
	_hidden = hidden
	queue_redraw()


## A tint for a detail on `tile`: grass on a rise is lighter, and so is what grows on it.
static func tint_of(tile: Vector2i) -> Color:
	if GroundDetails.ground_of(tile) != GroundDetails.GRASS or tile.x <= 0:
		return Color.WHITE
	var low: Color = GreyboxTiles.GROUND_COLORS[0]
	var here: Color = GreyboxTiles.GROUND_COLORS[tile.x]
	return Color(here.r / low.r, here.g / low.g, here.b / low.b)


func _draw() -> void:
	for cell: Vector2i in picks:
		if _hidden.has(cell):
			continue
		var detail: StringName = picks[cell]
		var frame: int = int(GroundDetails.FRAMES.get(detail, -1))
		if frame < 0:
			continue
		var target: Rect2 = SpriteSheet.target_of(Vector2(cell * T), Vector2i(T, T), rules.is_mirrored(cell, detail))
		draw_texture_rect_region(SHEET, target, Rect2(frame * T, 0, T, T), tint_of(_tiles.get(cell, Vector2i.ZERO)))
