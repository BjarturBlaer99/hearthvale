class_name LandMap
extends RefCounted
## What the hero's land is before he does anything to it (the Homestead, phase 4;
## docs/TECH_DESIGN.md §30), pure: its size, the cells nothing crosses (the woods, the old
## trees, the pond, the farmhouse), the road (the path tiles and the ways out), the field, and
## where the overgrowth stood in a new game. It never changes: what he has cleared, set down and
## built is Homestead's, and GameState lays one over the other to say what a cell is now
## (Pasture). LandSurvey reads one from the land's scene, once.

var size: Vector2i = Vector2i.ZERO
var field: Rect2i = Rect2i()
var _solid: Dictionary[Vector2i, bool] = {}
var _road: Dictionary[Vector2i, bool] = {}
var _debris: Dictionary[Vector2i, bool] = {}


## A map of `map_size` cells whose `solid`, `road` and `debris` cells are the ones listed, and
## whose field is `field_rect`.
func _init(map_size: Vector2i = Vector2i.ZERO, solid: Array[Vector2i] = [], road: Array[Vector2i] = [],
		debris: Array[Vector2i] = [], field_rect: Rect2i = Rect2i()) -> void:
	size = map_size
	field = field_rect
	for cell: Vector2i in solid:
		_solid[cell] = true
	for cell: Vector2i in road:
		_road[cell] = true
	for cell: Vector2i in debris:
		_debris[cell] = true


func in_bounds(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)


func is_solid(cell: Vector2i) -> bool:
	return _solid.has(cell)


func is_road(cell: Vector2i) -> bool:
	return _road.has(cell)


func is_field(cell: Vector2i) -> bool:
	return field.has_point(cell)


## Whether the overgrowth stood in `cell` in a new game (what is cleared since is Homestead's).
func had_debris(cell: Vector2i) -> bool:
	return _debris.has(cell)


func debris_count() -> int:
	return _debris.size()
