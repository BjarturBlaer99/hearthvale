class_name Scenery
extends Node2D
## Tall scenery (P1c, docs/TECH_DESIGN.md §3): the trees of an area as pictures that stand up
## from the ground, taller and wider than a cell, sorted by depth with the hero and everyone
## else. A tree still blocks exactly its own cell; its crown only overlaps the cells behind it,
## so the hero walks behind a tree and in front of it.
##
## build() takes the tree tiles off the Decor layer and stands a picture in each one's cell.
## A crown fades while anything stands behind it (fade_for), so nothing is ever hidden. The
## trees stand still: they swayed in the wind until 2026-11-13. For show only.

## How see-through a crown gets with something behind it, and how fast it changes (per second).
const FADED: float = 0.4
const FADE_SPEED: float = 5.0
## The part of a tree that can hide something, from its foot: half its width, its height, and
## how far above the foot the crown ends.
const CROWN_HALF_WIDTH: float = 16.0
const CROWN_TOP: float = 45.0
const CROWN_BOTTOM: float = 9.0
## Every roof tile kind (GreyboxTiles): the solid roofs, their ridge and eave details, and the
## house fronts' roofs with gable ends, and the two roofs of the hero's buildings
## (GreyboxTiles.ROOF_B_KINDS).
const ROOF_TILES: Array[String] = [
	"roof", "roof_blue", "roof_top", "roof_eave", "roof_blue_top", "roof_blue_eave",
	"roof_l", "roof_r", "roof_top_l", "roof_top_r", "roof_eave_l", "roof_eave_r",
	"roof_blue_l", "roof_blue_r", "roof_blue_top_l", "roof_blue_top_r", "roof_blue_eave_l", "roof_blue_eave_r",
	"roof_thatch", "roof_thatch_l", "roof_thatch_r", "roof_thatch_top", "roof_thatch_top_l", "roof_thatch_top_r",
	"roof_thatch_eave", "roof_thatch_eave_l", "roof_thatch_eave_r",
	"roof_shingle", "roof_shingle_l", "roof_shingle_r", "roof_shingle_top", "roof_shingle_top_l", "roof_shingle_top_r",
	"roof_shingle_eave", "roof_shingle_eave_l", "roof_shingle_eave_r",
	"roof_green", "roof_green_l", "roof_green_r", "roof_green_top", "roof_green_top_l", "roof_green_top_r",
	"roof_green_eave", "roof_green_eave_l", "roof_green_eave_r",
]

## The tree standing in each cell.
var by_cell: Dictionary[Vector2i, Sprite2D] = {}
## Things of stone that stand taller than their cell (P1d): the pillar in each cell, and the
## strip of ridge over each cell of a roof's top row. They don't fade: a
## pillar hides no more than the feet of whoever is behind it, and a ridge the same.
var pillars: Dictionary[Vector2i, Sprite2D] = {}
var ridges: Dictionary[Vector2i, Sprite2D] = {}

var _faded: Dictionary[Vector2i, bool] = {}


func _init() -> void:
	name = "Scenery"
	y_sort_enabled = true


## Where a tree in `cell` meets the ground (area px): the place it is depth-sorted by.
static func foot_of(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * GreyboxTiles.TILE_SIZE + 8.0, cell.y * GreyboxTiles.TILE_SIZE + 14.0)


## Whether a tree with its foot at `foot` hides something standing at `point` (its feet, or the
## corner of its cell): it stands behind the tree, under the crown or within half a cell of it.
static func hides(foot: Vector2, point: Vector2) -> bool:
	if point.y >= foot.y - 1.0:
		return false
	var crown: Rect2 = Rect2(foot.x - CROWN_HALF_WIDTH - 8.0, foot.y - CROWN_TOP - 4.0, CROWN_HALF_WIDTH * 2.0 + 16.0, CROWN_TOP - CROWN_BOTTOM + 16.0)
	return crown.has_point(point)


## The kind of tall picture (SceneryAtlas.FROM_DECOR) the Decor tile at atlas `coords` becomes,
## or empty if it isn't one.
static func kind_of_tile(coords: Vector2i) -> String:
	for tile: String in SceneryAtlas.FROM_DECOR:
		if GreyboxTiles.coords(tile) == coords:
			return SceneryAtlas.FROM_DECOR[tile]
	return ""


## Takes every tree tile off `decor` and stands its tall picture in that cell. Returns how many.
func build(decor: TileMapLayer) -> int:
	if decor == null:
		return 0
	var texture: Texture2D = load(SceneryAtlas.TEXTURE_PATH)
	for cell: Vector2i in decor.get_used_cells():
		var kind: String = kind_of_tile(decor.get_cell_atlas_coords(cell))
		if kind == "":
			continue
		decor.erase_cell(cell)
		_stand(cell, kind, texture)
	return by_cell.size()


## Stands a tree of `kind` (a SceneryAtlas kind) in `cell`, as build() does for a tree of the
## map: a sapling the hero set down has grown (the Homestead). It only shows the tree: whoever
## asks sees to it that the cell is filled. Returns it (the one there already, if one is).
func stand(cell: Vector2i, kind: String) -> Sprite2D:
	return by_cell[cell] if by_cell.has(cell) else _stand(cell, kind, load(SceneryAtlas.TEXTURE_PATH))


## Takes away the tree standing in `cell` (one the hero has taken up again). Returns whether
## one stood there.
func fell(cell: Vector2i) -> bool:
	if not by_cell.has(cell):
		return false
	by_cell[cell].free()
	by_cell.erase(cell)
	_faded.erase(cell)
	return true


func _stand(cell: Vector2i, kind: String, texture: Texture2D) -> Sprite2D:
	var tree: Sprite2D = Sprite2D.new()
	tree.name = "%s_%d_%d" % [kind.capitalize(), cell.x, cell.y]
	tree.texture = texture
	tree.region_enabled = true
	tree.region_rect = SceneryAtlas.region(SceneryAtlas.variant(kind, cell))
	tree.centered = false
	tree.offset = -SceneryAtlas.FOOT
	tree.position = foot_of(cell)
	tree.set_meta(&"kind", kind)
	add_child(tree)
	by_cell[cell] = tree
	return tree


## Stands a tall pillar on every pillar tile of `layer` (the Height layer, which keeps the tile:
## the cell blocks as it did), and raises a strip of ridge over the top row of every roof where
## the cell to its north isn't more roof. Returns how many it added.
func build_stone(layer: TileMapLayer) -> int:
	var texture: Texture2D = load(ReliefAtlas.TEXTURE_PATH)
	for cell: Vector2i in layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("pillar")):
		var pillar: Sprite2D = _stone(texture, ReliefAtlas.pillar())
		pillar.name = "Pillar_%d_%d" % [cell.x, cell.y]
		pillar.offset = -ReliefAtlas.PILLAR_FOOT
		pillar.position = foot_of(cell)
		pillars[cell] = pillar
	for cell: Vector2i in layer.get_used_cells():
		var ridge: Array = ReliefAtlas.ridge_of(kind_at(layer, cell))
		if ridge.is_empty() or not ReliefAtlas.ridge_of(kind_at(layer, cell + Vector2i.UP)).is_empty() or is_roof(kind_at(layer, cell + Vector2i.UP)):
			continue
		var strip: Sprite2D = _stone(texture, ReliefAtlas.ridge(ridge[0], ridge[1]))
		strip.name = "Ridge_%d_%d" % [cell.x, cell.y]
		# Sorted just inside the building's top edge: whoever walks behind the house is drawn
		# first, and the ridge covers their feet.
		strip.offset = Vector2(0.0, -float(ReliefAtlas.RIDGE_SIZE.y) - 1.0)
		strip.position = Vector2(cell.x * GreyboxTiles.TILE_SIZE, cell.y * GreyboxTiles.TILE_SIZE + 1.0)
		ridges[cell] = strip
	return pillars.size() + ridges.size()


## The GreyboxTiles kind of the house or roof tile at `cell` of `layer`, or empty for anything
## else (HOUSE_KINDS and the roof DETAIL_KINDS are the only tiles a ridge cares about).
static func kind_at(layer: TileMapLayer, cell: Vector2i) -> String:
	var coords: Vector2i = layer.get_cell_atlas_coords(cell)
	if coords.x < 0:
		return ""
	for kind: String in ROOF_TILES:
		if GreyboxTiles.coords(kind) == coords:
			return kind
	return ""


static func is_roof(kind: String) -> bool:
	return kind.begins_with("roof")


func _stone(texture: Texture2D, region: Rect2) -> Sprite2D:
	var piece: Sprite2D = Sprite2D.new()
	piece.texture = texture
	piece.region_enabled = true
	piece.region_rect = region
	piece.centered = false
	add_child(piece)
	return piece


## The feet of every cherry tree, in cell order (petals fall round them).
func cherry_feet() -> Array[Vector2]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in by_cell:
		if SceneryAtlas.is_cherry(str(by_cell[cell].get_meta(&"kind", ""))):
			cells.append(cell)
	cells.sort()
	var out: Array[Vector2] = []
	for cell: Vector2i in cells:
		out.append(foot_of(cell))
	return out


## The cells of the trees that hide something standing at `point`: only trees just below it and
## to either side can.
func hiding(point: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var at: Vector2i = Vector2i((point / float(GreyboxTiles.TILE_SIZE)).floor())
	for dy: int in range(0, 4):
		for dx: int in range(-2, 3):
			var cell: Vector2i = at + Vector2i(dx, dy)
			if by_cell.has(cell) and hides(foot_of(cell), point):
				out.append(cell)
	return out


## Fades the crowns that hide any of `points` (where the hero and others stand), and brings the
## rest back, a step of `delta` seconds at a time.
func fade_for(points: Array[Vector2], delta: float) -> void:
	var wanted: Dictionary[Vector2i, bool] = {}
	for point: Vector2 in points:
		for cell: Vector2i in hiding(point):
			wanted[cell] = true
			_faded[cell] = true
	for cell: Vector2i in _faded.keys():
		var tree: Sprite2D = by_cell[cell]
		var target: float = FADED if wanted.has(cell) else 1.0
		tree.self_modulate.a = move_toward(tree.self_modulate.a, target, FADE_SPEED * delta)
		if target == 1.0 and tree.self_modulate.a >= 1.0:
			_faded.erase(cell)


## How solid the tree in `cell` is drawn, 0 to 1 (for tests).
func opacity_of(cell: Vector2i) -> float:
	return by_cell[cell].self_modulate.a if by_cell.has(cell) else 1.0
