extends GdUnitTestSuite
## Buildings, interiors and dungeons (P1d). A wall shows its front face where the floor lies
## south of it and its top everywhere else; a face rises over the wall behind it, but never into
## the next room. Pillars stand taller than their cells and roofs have a ridge, both sorted by
## depth so the hero walks behind them. All of it is drawn over the map: every wall, pillar and
## roof tile is where it was, and every cell blocks exactly as before.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CISTERN: String = "res://world/areas/cistern/cistern.tscn"
const SOUTH_FIELD: String = "res://world/areas/south_field/south_field.tscn"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_wall_shows_its_face_where_the_floor_lies_south_of_it() -> void:
	# A room of walls three cells thick at the top, one at the sides and bottom:
	#   rows 0-2 wall, rows 3-5 floor with walls at x 0 and 4, row 6 wall.
	var walls: Dictionary = {}
	var size: Vector2i = Vector2i(5, 7)
	for x: int in 5:
		for y: int in [0, 1, 2, 6]:
			walls[Vector2i(x, y)] = "stone"
	for y: int in [3, 4, 5]:
		walls[Vector2i(0, y)] = "stone"
		walls[Vector2i(4, y)] = "stone"
	assert_that(WallRelief.part_of(walls, size, Vector2i(2, 2))).override_failure_message("floor to the south: the face").is_equal(WallRelief.FACE)
	assert_that(WallRelief.part_of(walls, size, Vector2i(2, 1))).override_failure_message("wall to the south: the top").is_equal(WallRelief.TOP)
	assert_that(WallRelief.part_of(walls, size, Vector2i(0, 4))).override_failure_message("a side wall: its top").is_equal(WallRelief.TOP)
	assert_that(WallRelief.part_of(walls, size, Vector2i(0, 2))).override_failure_message("the corner has wall to its south").is_equal(WallRelief.TOP)
	assert_that(WallRelief.part_of(walls, size, Vector2i(2, 6))).override_failure_message("the bottom wall: nothing south of it is in the map").is_equal(WallRelief.TOP)
	assert_that(WallRelief.part_of(walls, size, Vector2i(2, 4))).override_failure_message("floor is not a wall").is_equal(&"")
	assert_bool(WallRelief.open_to(walls, size, Vector2i(0, 4), Vector2i.RIGHT)).override_failure_message("the side wall ends at the floor").is_true()
	assert_bool(WallRelief.open_to(walls, size, Vector2i(0, 4), Vector2i.LEFT)).override_failure_message("off the map is not an end").is_false()
	assert_bool(WallRelief.open_to(walls, size, Vector2i(2, 1), Vector2i.UP)).is_false()


func test_a_face_rises_over_the_wall_behind_it_but_not_into_the_next_room() -> void:
	var walls: Dictionary = {Vector2i(3, 10): "stone", Vector2i(3, 11): "stone", Vector2i(3, 5): "stone", Vector2i(3, 4): "stone", Vector2i(8, 8): "stone"}
	var one_room: Vector2i = Vector2i.ZERO
	var rooms: Vector2i = Vector2i(15, 11)
	assert_bool(WallRelief.rises(walls, one_room, Vector2i(3, 11))).override_failure_message("wall behind it, in a house").is_true()
	assert_bool(WallRelief.rises(walls, rooms, Vector2i(3, 5))).override_failure_message("wall behind it, in the same room").is_true()
	assert_bool(WallRelief.rises(walls, rooms, Vector2i(3, 11))).override_failure_message("the first row of a room: the wall behind is the next room's").is_false()
	assert_bool(WallRelief.rises(walls, rooms, Vector2i(8, 8))).override_failure_message("nothing behind it to rise over").is_false()
	assert_int(ReliefAtlas.FACE_SIZE.y - ReliefAtlas.FACE_RISE).override_failure_message("a tall face covers its cell and the rise").is_equal(GreyboxTiles.TILE_SIZE)
	assert_int(ReliefAtlas.SHORT_FACE_SIZE.y).is_equal(GreyboxTiles.TILE_SIZE)


func test_the_keeps_walls_have_relief_and_block_exactly_as_before() -> void:
	var keep: AreaController = _load(KEEP)
	assert_object(keep.relief).is_not_null()
	assert_int(keep.relief.get_index()).override_failure_message("drawn just above the Height layer").is_equal(keep.height_layer.get_index() + 1)
	var wall_tile: Vector2i = GreyboxTiles.coords("dungeon_wall")
	var faces: int = 0
	var tops: int = 0
	for cell: Vector2i in keep.relief.materials:
		assert_str(keep.relief.materials[cell]).is_equal("stone")
		assert_that(keep.height_layer.get_cell_atlas_coords(cell)).override_failure_message("the wall tile at %s is still there" % cell).is_equal(wall_tile)
		assert_bool(keep.grid.is_solid(cell)).override_failure_message("and still blocks").is_true()
		var part: StringName = keep.relief.part(cell)
		if part == WallRelief.FACE:
			faces += 1
			var south: Vector2i = cell + Vector2i.DOWN
			assert_bool(keep.relief.materials.has(south)).override_failure_message("a face at %s looks onto something that isn't wall" % cell).is_false()
			if cell.y % keep.room_size.y == 0:
				assert_bool(WallRelief.rises(keep.relief.materials, keep.room_size, cell)).override_failure_message("a room's north wall keeps to its own room").is_false()
		else:
			tops += 1
	assert_int(keep.relief.materials.size()).is_equal(keep.height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, wall_tile).size())
	assert_int(faces).override_failure_message("every room has a north wall to look at").is_greater(100)
	assert_int(tops).is_greater(faces)


func test_houses_and_ruins_have_walls_of_their_own_stuff() -> void:
	var house: AreaController = _load(ELDER_HOUSE)
	for cell: Vector2i in house.relief.materials:
		assert_str(house.relief.materials[cell]).is_equal("timber")
	assert_that(house.relief.part(Vector2i(2, 1))).override_failure_message("the north wall's lower row faces the room").is_equal(WallRelief.FACE)
	assert_bool(WallRelief.rises(house.relief.materials, house.room_size, Vector2i(2, 1))).override_failure_message("and stands a third taller than a cell").is_true()
	assert_that(house.relief.part(Vector2i(2, 0))).is_equal(WallRelief.TOP)
	assert_that(house.relief.part(Vector2i(0, 4))).override_failure_message("a side wall shows its top").is_equal(WallRelief.TOP)
	assert_that(house.relief.part(Vector2i(5, 1))).override_failure_message("the hearth is not wall").is_equal(&"")
	var field: AreaController = _load(SOUTH_FIELD)
	assert_object(field.relief).override_failure_message("the ruin in the South Field").is_not_null()
	for cell: Vector2i in field.relief.materials:
		assert_str(field.relief.materials[cell]).is_equal("ruin")
	assert_object(_load(VILLAGE).relief).override_failure_message("Hearthvale's houses are fronts already").is_null()
	for kind: String in ReliefAtlas.MATERIALS:
		assert_bool(GreyboxTiles.is_known_kind(kind)).is_true()
		assert_bool(ReliefAtlas.MATERIAL_ORDER.has(ReliefAtlas.MATERIALS[kind])).is_true()


func test_pillars_stand_taller_than_their_cells_and_still_block_them() -> void:
	for path: String in [KEEP, CISTERN]:
		var area: AreaController = _load(path)
		var tiles: Array[Vector2i] = area.height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("pillar"))
		assert_int(tiles.size()).override_failure_message("%s has pillars" % path).is_greater(0)
		assert_int(area.scenery.pillars.size()).override_failure_message("one standing pillar a tile").is_equal(tiles.size())
		for cell: Vector2i in tiles:
			var pillar: Sprite2D = area.scenery.pillars[cell]
			assert_bool(area.grid.is_solid(cell)).override_failure_message("the pillar at %s blocks" % cell).is_true()
			assert_that(pillar.position).is_equal(Scenery.foot_of(cell))
			assert_that(pillar.region_rect).is_equal(ReliefAtlas.pillar())
			assert_float(pillar.position.y + pillar.offset.y).override_failure_message("its top is above its cell").is_less(float(cell.y * GreyboxTiles.TILE_SIZE))
			assert_object(pillar.material).override_failure_message("stone doesn't sway").is_null()
			assert_bool(area.scenery.by_cell.has(cell)).override_failure_message("and doesn't fade like a tree").is_false()
	assert_int(_load(VILLAGE).scenery.pillars.size()).is_equal(0)


func test_every_roof_has_a_ridge_the_hero_walks_behind() -> void:
	var village: AreaController = _load(VILLAGE)
	# Four houses six cells wide and the chapel twelve.
	assert_int(village.scenery.ridges.size()).is_equal(4 * 6 + 12)
	for cell: Vector2i in village.scenery.ridges:
		var ridge: Sprite2D = village.scenery.ridges[cell]
		var kind: String = Scenery.kind_at(village.height_layer, cell)
		assert_bool(ReliefAtlas.ridge_of(kind).size() == 2).override_failure_message("%s is the top row of a roof (%s)" % [cell, kind]).is_true()
		assert_bool(Scenery.is_roof(Scenery.kind_at(village.height_layer, cell + Vector2i.UP))).override_failure_message("with no more roof above it").is_false()
		var top_edge: float = float(cell.y * GreyboxTiles.TILE_SIZE)
		assert_float(ridge.position.y).override_failure_message("sorted just inside the building's top edge").is_between(top_edge, top_edge + 2.0)
		assert_float(ridge.position.y + ridge.offset.y + ReliefAtlas.RIDGE_SIZE.y).override_failure_message("and drawn wholly above it").is_less_equal(top_edge)
		assert_bool(village.grid.is_solid(cell)).is_true()
	# Behind the thatched cottage: the hero is sorted before the ridge, which covers their feet.
	var behind: Vector2i = Vector2i(8, 10)
	assert_bool(village.grid.is_solid(behind)).is_false()
	village.player.motor.place(behind)
	village.player.sync_from_motor()
	assert_float(village.player.position.y).override_failure_message("the hero behind the house is drawn first").is_less(village.scenery.ridges[Vector2i(8, 11)].position.y)
	assert_array(ReliefAtlas.ridge_of("roof_blue_top_l")).is_equal(["roof_blue", "l"])
	assert_array(ReliefAtlas.ridge_of("roof_thatch_top")).is_equal(["roof_thatch", "mid"])
	assert_array(ReliefAtlas.ridge_of("roof_top_r")).is_equal(["roof", "r"])
	assert_array(ReliefAtlas.ridge_of("roof_eave")).override_failure_message("only the top row has a ridge").is_empty()
	assert_array(ReliefAtlas.ridge_of("wall")).is_empty()


func test_the_relief_pictures_fit_their_atlas_without_overlapping() -> void:
	var atlas: Texture2D = load(ReliefAtlas.TEXTURE_PATH)
	assert_that(Vector2i(atlas.get_size())).is_equal(ReliefAtlas.SIZE)
	var image: Image = atlas.get_image()
	var regions: Dictionary = {"pillar": ReliefAtlas.pillar()}
	for material: String in ReliefAtlas.MATERIAL_ORDER:
		regions["%s face" % material] = ReliefAtlas.face(material)
		regions["%s short face" % material] = ReliefAtlas.short_face(material)
		regions["%s top" % material] = ReliefAtlas.top(material)
	for style: String in ReliefAtlas.ROOF_STYLES:
		for part: String in ReliefAtlas.RIDGE_PARTS:
			regions["%s ridge %s" % [style, part]] = ReliefAtlas.ridge(style, part)
	var names: Array = regions.keys()
	for i: int in names.size():
		var region: Rect2 = regions[names[i]]
		assert_bool(Rect2(Vector2.ZERO, Vector2(ReliefAtlas.SIZE)).encloses(region)).override_failure_message("'%s' is inside the atlas" % names[i]).is_true()
		var painted: int = 0
		for y: int in int(region.size.y):
			for x: int in int(region.size.x):
				if image.get_pixel(int(region.position.x) + x, int(region.position.y) + y).a > 0.0:
					painted += 1
		assert_int(painted).override_failure_message("'%s' is painted" % names[i]).is_greater(int(region.get_area() * 0.5))
		for j: int in range(i + 1, names.size()):
			assert_bool(region.intersects(regions[names[j]])).override_failure_message("'%s' and '%s' overlap" % [names[i], names[j]]).is_false()
	var face: Rect2 = ReliefAtlas.face("stone")
	var lit: Color = image.get_pixel(int(face.position.x) + 5, int(face.position.y))
	var foot: Color = image.get_pixel(int(face.position.x) + 5, int(face.end.y) - 1)
	assert_float(lit.v).override_failure_message("a face is lit along its top and dark at the floor").is_greater(foot.v + 0.2)
	var end_corner: Rect2 = ReliefAtlas.ridge("roof", "l")
	assert_float(image.get_pixel(int(end_corner.position.x), int(end_corner.position.y)).a).override_failure_message("a gable end slopes away").is_equal(0.0)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
