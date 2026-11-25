extends GdUnitTestSuite
## Soft edges (HeightShading.find_ground_edges): grass frays over a path only where the two meet
## on the same level, water gets a bank against everything that isn't water, and the areas ask
## for them. Since the farm-look plan's phase A they are pictures of the edge sheet: one for all
## of a cell's sides (sides_of), and one for a corner the other ground touches only diagonally
## (find_corners).

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const TILES: TileSet = preload("res://world/tiles/greybox_tiles.tres")
const VILLAGE: String = "res://world/areas/village/village.tscn"

var _layer: TileMapLayer
var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_layer = auto_free(TileMapLayer.new())
	_layer.tile_set = TILES
	add_child(_layer)


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_grass_frays_over_a_path_on_the_same_level() -> void:
	# A path running east-west through grass, with a tree (on solid ground) below its middle.
	_fill(Vector2i(3, 3), "ground", 0)
	for x: int in 3:
		_put(Vector2i(x, 1), "path", 0)
	_put(Vector2i(1, 2), "solid_ground", 0)
	var edges: Array = _edges()
	for x: int in 3:
		assert_bool(edges.has([Vector2i(x, 1), Vector2i.UP, HeightShading.FRINGE])).override_failure_message("grass above the path at x=%d" % x).is_true()
		assert_bool(edges.has([Vector2i(x, 1), Vector2i.DOWN, HeightShading.FRINGE])).override_failure_message("grass (or a tree's grass) below the path at x=%d" % x).is_true()
	assert_int(edges.size()).override_failure_message("none along the path, none at the map's edge").is_equal(6)


func test_no_fringe_where_the_path_meets_a_cliff_stairs_or_a_wall() -> void:
	_fill(Vector2i(3, 3), "path", 0)
	_put(Vector2i(1, 0), "ground", 1)
	_put(Vector2i(0, 1), "stairs", 0)
	_put(Vector2i(2, 1), "wall", 0)
	_put(Vector2i(1, 2), "ground", 0)
	var edges: Array = _edges()
	# The grass at the bottom is on the path's level: it frays over the three path cells round it.
	# The higher grass at the top, the stairs and the wall leave the path's edge clean.
	assert_array(edges).override_failure_message("only the grass on the path's own level frays over it").contains_exactly_in_any_order([
		[Vector2i(1, 1), Vector2i.DOWN, HeightShading.FRINGE],
		[Vector2i(0, 2), Vector2i.RIGHT, HeightShading.FRINGE],
		[Vector2i(2, 2), Vector2i.LEFT, HeightShading.FRINGE],
	])


func test_water_has_a_bank_on_every_side_that_is_not_water() -> void:
	# A stream that runs in from the map's west edge and ends against a path.
	_fill(Vector2i(3, 3), "ground", 0)
	_put(Vector2i(0, 1), "water", 0)
	_put(Vector2i(1, 1), "water", 0)
	_put(Vector2i(2, 1), "path", 0)
	var edges: Array = _edges()
	var banks: Array = edges.filter(func(edge: Array) -> bool: return edge[2] == HeightShading.BANK)
	assert_array(banks).override_failure_message("no bank between water and water, nor at the map's edge").contains_exactly_in_any_order([
		[Vector2i(0, 1), Vector2i.UP, HeightShading.BANK], [Vector2i(0, 1), Vector2i.DOWN, HeightShading.BANK],
		[Vector2i(1, 1), Vector2i.UP, HeightShading.BANK], [Vector2i(1, 1), Vector2i.DOWN, HeightShading.BANK],
		[Vector2i(1, 1), Vector2i.RIGHT, HeightShading.BANK],
	])
	assert_bool(edges.has([Vector2i(2, 1), Vector2i.LEFT, HeightShading.FRINGE])).override_failure_message("water doesn't fray over a path").is_false()


func test_areas_show_the_soft_edges_of_their_paths_and_water() -> void:
	var area: AreaController = Steps.load_area(VILLAGE)
	_area = area
	var edges: Array = (area.get_node(^"HeightShading") as HeightShading).ground_edges()
	var fringes: int = edges.filter(func(edge: Array) -> bool: return edge[2] == HeightShading.FRINGE).size()
	var banks: int = edges.filter(func(edge: Array) -> bool: return edge[2] == HeightShading.BANK).size()
	assert_int(fringes).override_failure_message("the village's paths have grassy edges").is_greater(40)
	assert_int(banks).override_failure_message("the pond has a bank").is_greater(8)
	var water: Vector2i = GreyboxTiles.coords("water")
	for edge: Array in edges:
		var tile: Vector2i = area.height_layer.get_cell_atlas_coords(edge[0])
		if edge[2] == HeightShading.BANK:
			assert_that(tile).is_equal(water)
		else:
			assert_int(tile.y).is_equal(GreyboxTiles.ROW_PATH)


func test_a_cells_sides_are_gathered_into_one_picture() -> void:
	# A lane one cell wide running north to south, ending in grass.
	_fill(Vector2i(3, 3), "ground", 0)
	_put(Vector2i(1, 0), "path", 0)
	_put(Vector2i(1, 1), "path", 0)
	var sides: Dictionary = HeightShading.sides_of(_edges())
	var west_and_east: int = int(EdgeAtlas.SIDES[Vector2i.LEFT]) | int(EdgeAtlas.SIDES[Vector2i.RIGHT])
	assert_int(sides[HeightShading.FRINGE][Vector2i(1, 0)]).override_failure_message("grass west and east; the map's edge is no side").is_equal(west_and_east)
	assert_int(sides[HeightShading.FRINGE][Vector2i(1, 1)]).override_failure_message("and south, where the lane ends").is_equal(west_and_east | int(EdgeAtlas.SIDES[Vector2i.DOWN]))
	assert_int((sides[HeightShading.FRINGE] as Dictionary).size()).is_equal(2)
	assert_bool((sides[HeightShading.BANK] as Dictionary).is_empty()).is_true()
	assert_that(EdgeAtlas.fringe(west_and_east, 0)).override_failure_message("the lane's own picture").is_equal(Rect2((west_and_east - 1) * 16, 0, 16, 16))


func test_grass_that_touches_a_path_only_at_a_corner_gets_a_corner_piece() -> void:
	# Paths all round a block of grass in the north-west.
	_fill(Vector2i(3, 3), "path", 0)
	_put(Vector2i(0, 0), "ground", 0)
	var grid: HeightGrid = HeightGridBuilder.from_layer(_layer)
	var corners: Array = HeightShading.find_corners(grid, _layer, HeightShading.sides_of(_edges()))
	var north_west: int = EdgeAtlas.CORNERS.find(Vector2i(-1, -1))
	assert_array(corners).override_failure_message("only the cell that meets the grass diagonally; its neighbours have sides").is_equal([[Vector2i(1, 1), north_west, HeightShading.FRINGE]])
	# Higher grass is a cliff, not a fringe: no corner either.
	_put(Vector2i(0, 0), "ground", 1)
	grid = HeightGridBuilder.from_layer(_layer)
	assert_array(HeightShading.find_corners(grid, _layer, HeightShading.sides_of(_edges()))).is_empty()


func test_land_that_touches_water_only_at_a_corner_gets_a_corner_of_bank() -> void:
	_fill(Vector2i(3, 3), "water", 0)
	_put(Vector2i(2, 2), "ground", 0)
	var grid: HeightGrid = HeightGridBuilder.from_layer(_layer)
	var sides: Dictionary = HeightShading.sides_of(_edges())
	assert_int(sides[HeightShading.BANK][Vector2i(1, 2)]).is_equal(int(EdgeAtlas.SIDES[Vector2i.RIGHT]))
	assert_int(sides[HeightShading.BANK][Vector2i(2, 1)]).is_equal(int(EdgeAtlas.SIDES[Vector2i.DOWN]))
	var south_east: int = EdgeAtlas.CORNERS.find(Vector2i(1, 1))
	assert_array(HeightShading.find_corners(grid, _layer, sides)).is_equal([[Vector2i(1, 1), south_east, HeightShading.BANK]])


func test_an_areas_corners_lie_on_its_paths_and_water_and_never_beside_an_edge() -> void:
	var area: AreaController = Steps.load_area(VILLAGE)
	_area = area
	var shading: HeightShading = area.get_node(^"HeightShading")
	var sides: Dictionary = HeightShading.sides_of(shading.ground_edges())
	var corners: Array = shading.ground_corners()
	assert_int(corners.size()).override_failure_message("the village's lanes have corners").is_greater(4)
	var water: Vector2i = GreyboxTiles.coords("water")
	for corner: Array in corners:
		var tile: Vector2i = area.height_layer.get_cell_atlas_coords(corner[0])
		var way: Vector2i = EdgeAtlas.CORNERS[corner[1]]
		if corner[2] == HeightShading.BANK:
			assert_that(tile).is_equal(water)
		else:
			assert_int(tile.y).is_equal(GreyboxTiles.ROW_PATH)
		var between: int = int(EdgeAtlas.SIDES[Vector2i(way.x, 0)]) | int(EdgeAtlas.SIDES[Vector2i(0, way.y)])
		var edged: int = int((sides[corner[2]] as Dictionary).get(corner[0], 0))
		assert_int(edged & between).override_failure_message("%s: no side beside the corner has an edge" % [corner]).is_equal(0)


func _edges() -> Array:
	return HeightShading.find_ground_edges(HeightGridBuilder.from_layer(_layer), _layer)


func _fill(size: Vector2i, kind: String, height: int) -> void:
	for y: int in size.y:
		for x: int in size.x:
			_put(Vector2i(x, y), kind, height)


func _put(cell: Vector2i, kind: String, height: int) -> void:
	_layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind, height))
