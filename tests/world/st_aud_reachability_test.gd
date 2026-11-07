extends GdUnitTestSuite
## St. Aud's greybox layout against the M2 acceptance criteria. Searches the real scene's
## Height layer from the player spawn, using the player's own movement rules
## (TerrainQuery.check_move, climbing included), at every St. Aud water level.

const SCENE: String = "res://world/districts/st_aud/st_aud.tscn"
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _scene: Node
var _query: TerrainQuery
var _spawn: Vector2i


func before() -> void:
	_scene = auto_free((load(SCENE) as PackedScene).instantiate())
	_query = TerrainQuery.new(HeightGridBuilder.from_layer(_scene.get_node("Height")))
	_spawn = PlayerMotor.cell_of((_scene.get_node("PlayerSpawn") as Node2D).position)


func test_the_grid_is_the_baked_layout() -> void:
	assert_that(_query.grid.size).is_equal(Vector2i(64, 64))
	assert_int(_query.grid.height_at(_spawn)).is_equal(5)
	assert_int(_query.grid.height_at(Vector2i(45, 23))).is_equal(4)
	assert_int(_query.grid.height_at(Vector2i(14, 38))).is_equal(2)
	assert_int(_query.grid.height_at(Vector2i(43, 47))).is_equal(0)
	assert_bool(_query.grid.is_ramp(Vector2i(8, 13))).is_true()
	assert_bool(_query.grid.is_climbable(Vector2i(55, 13))).is_true()


func test_the_spawn_is_dry_at_every_level() -> void:
	for level: Dictionary in _levels():
		var kind: TerrainQuery.CellKind = _query.cell_kind(_spawn, int(level["water_height"]))
		assert_that(kind).override_failure_message("spawn at %s" % level["id"]).is_equal(TerrainQuery.CellKind.DRY)


func test_each_place_is_usable_only_at_its_water_level() -> void:
	var expected: Dictionary = {
		"flooded": ["RooftopDoor"],
		"waist": ["ClinicHatch"],
		"drained": ["SubwayEntrance"],
	}
	for level: Dictionary in _levels():
		var water: int = int(level["water_height"])
		var on_foot: Dictionary = _on_foot(water)
		for point: PointOfInterest in _points():
			var usable: bool = _can_use(point, on_foot, water)
			var should: bool = (expected[level["id"]] as Array).has(String(point.name))
			var message: String = "%s at %s: usable=%s" % [point.name, level["id"], usable]
			assert_bool(usable).override_failure_message(message).is_equal(should)


func test_each_water_level_changes_where_you_can_walk() -> void:
	var footprints: Array = []
	for level: Dictionary in _levels():
		var cells: Array = _on_foot(int(level["water_height"])).keys()
		cells.sort()
		footprints.append(cells)
	assert_int(footprints.size()).is_equal(3)
	for i: int in footprints.size():
		for j: int in range(i + 1, footprints.size()):
			assert_bool(footprints[i] != footprints[j]).override_failure_message("levels %d and %d give the same walkable area" % [i, j]).is_true()


## Cells the player can stand on (not swim in), starting from the spawn at this water height.
func _on_foot(water_height: int) -> Dictionary:
	var seen: Dictionary = {_spawn: true}
	var queue: Array[Vector2i] = [_spawn]
	var feet: Dictionary = {}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		if _query.cell_kind(cell, water_height) != TerrainQuery.CellKind.DEEP:
			feet[cell] = true
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and _query.check_move(cell, next, water_height).is_allowed():
				seen[next] = true
				queue.append(next)
	return feet


## A place is usable when the water allows it and the player can stand on any of its cells.
func _can_use(point: PointOfInterest, on_foot: Dictionary, water_height: int) -> bool:
	if not point.is_usable_at(_query, water_height):
		return false
	for cell: Vector2i in point.cells():
		if on_foot.has(cell):
			return true
	return false


## The level-gated places only: other interactables (the pump) live alongside them.
func _points() -> Array[PointOfInterest]:
	var out: Array[PointOfInterest] = []
	for child: Node in _scene.get_node("PointsOfInterest").get_children():
		if child is PointOfInterest:
			out.append(child as PointOfInterest)
	return out


func _levels() -> Array:
	return DataRegistry.get_district(&"st_aud")["levels"]
