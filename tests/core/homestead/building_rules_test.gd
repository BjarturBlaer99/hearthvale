extends GdUnitTestSuite
## The buildings' rules (Buildings, the Homestead, phase 3), pure: a building's cells, its door
## and doorstep, the cell the ghost holds it by, whether it fits (each cell and the doorstep,
## the first reason found), how it looks, and what pulling it down gives back.

const COOP: Dictionary = {
	"id": "coop", "name": "Coop", "size": [4, 3], "door": [2, 2], "room": "coop", "animals": 4,
	"big": {"name": "Big Coop", "animals": 8, "look": [[0, 0, 4, 2, "roof"], [0, 2, 4, 1, "wall"], [2, 2, 1, 1, "door"]]},
	"look": [[0, 0, 4, 2, "roof_thatch"], [0, 2, 4, 1, "wall"], [2, 2, 1, 1, "door"], [3, 0, 1, 1, "chimney"]],
}
const WELL: Dictionary = {"id": "well", "name": "Well", "size": [2, 2], "fills_can": true, "shadow": false, "look": [[0, 0, 2, 2, "well"]]}
const SILO: Dictionary = {"id": "silo", "name": "Silo", "size": [2, 2], "holds": {"item": "hay", "count": 60}, "look": [[0, 0, 2, 2, "silo"]]}
const KIT: Dictionary = {"id": "coop_kit", "name": "Coop Kit", "type": "kit", "icon": "kit", "stats": {"building": "coop"}}


func test_a_kit_names_the_building_it_sets_down() -> void:
	assert_bool(Buildings.is_kit(KIT)).is_true()
	assert_that(Buildings.building_of_kit(KIT)).is_equal(&"coop")
	assert_bool(Buildings.is_kit({"id": "fence", "type": "placeable"})).is_false()
	assert_that(Buildings.building_of_kit({"id": "fence", "type": "placeable"})).is_equal(&"")
	assert_that(Buildings.kit_for(&"coop", [{"id": "fence", "type": "placeable"}, KIT])).is_equal(&"coop_kit")
	assert_that(Buildings.kit_for(&"barn", [KIT])).is_equal(&"")


func test_a_buildings_cells_door_and_doorstep() -> void:
	assert_that(Buildings.size_of(COOP)).is_equal(Vector2i(4, 3))
	assert_that(Buildings.door_of(COOP)).is_equal(Vector2i(2, 2))
	assert_bool(Buildings.has_door(COOP)).is_true()
	assert_that(Buildings.room_of(COOP)).is_equal(&"coop")
	var at: Vector2i = Vector2i(10, 5)
	assert_array(Buildings.cells_of(COOP, at)).has_size(12)
	assert_that(Buildings.cells_of(COOP, at)[0]).is_equal(Vector2i(10, 5))
	assert_that(Buildings.cells_of(COOP, at)[11]).is_equal(Vector2i(13, 7))
	assert_that(Buildings.door_cell(COOP, at)).is_equal(Vector2i(12, 7))
	assert_that(Buildings.doorstep_of(COOP, at)).override_failure_message("the cell below the door").is_equal(Vector2i(12, 8))
	assert_bool(Buildings.covers(COOP, at, Vector2i(13, 7))).is_true()
	assert_bool(Buildings.covers(COOP, at, Vector2i(12, 8))).override_failure_message("the doorstep is no cell of it").is_false()
	assert_array(Buildings.cells_and_doorstep(COOP, at)).has_size(13)
	assert_that(Buildings.cells_and_doorstep(COOP, at)[12]).is_equal(Vector2i(12, 8))
	# One without a door has no room and no doorstep.
	assert_bool(Buildings.has_door(WELL)).is_false()
	assert_that(Buildings.door_of(WELL)).is_equal(Buildings.NO_CELL)
	assert_that(Buildings.doorstep_of(WELL, at)).is_equal(Buildings.NO_CELL)
	assert_that(Buildings.room_of(WELL)).is_equal(&"")
	assert_array(Buildings.cells_and_doorstep(WELL, at)).has_size(4)


func test_the_ghost_holds_it_by_its_door_or_the_middle_of_its_bottom_row() -> void:
	assert_that(Buildings.anchor_of(COOP)).is_equal(Vector2i(2, 2))
	assert_that(Buildings.origin_at(COOP, Vector2i(12, 7))).is_equal(Vector2i(10, 5))
	assert_that(Buildings.anchor_of(WELL)).is_equal(Vector2i(1, 1))
	assert_that(Buildings.origin_at(WELL, Vector2i(5, 5))).is_equal(Vector2i(4, 4))
	assert_that(Buildings.anchor_of({"size": [6, 4]})).is_equal(Vector2i(3, 3))


func test_a_site_fills_every_cell_and_a_building_all_but_its_door() -> void:
	var at: Vector2i = Vector2i(10, 5)
	assert_array(Buildings.filled_cells(COOP, at, false)).has_size(12)
	var standing: Array[Vector2i] = Buildings.filled_cells(COOP, at, true)
	assert_array(standing).has_size(11)
	assert_bool(standing.has(Vector2i(12, 7))).override_failure_message("the door is walked into").is_false()
	assert_array(Buildings.filled_cells(WELL, at, true)).override_failure_message("a well has no door: all of it is in the way").has_size(4)


func test_it_fits_where_every_cell_and_its_doorstep_do_and_says_the_first_reason_found() -> void:
	var at: Vector2i = Vector2i(10, 5)
	var open: Callable = func(_cell: Vector2i) -> Dictionary: return Placement.site()
	assert_str(Buildings.why_not_at(COOP, at, open)).is_empty()
	# A thing standing in one cell, the hero in another: the first in row order is said.
	var busy: Callable = func(cell: Vector2i) -> Dictionary:
		if cell == Vector2i(13, 6):
			return Placement.site(true, true, false, false, false, false, &"", &"fence")
		if cell == Vector2i(11, 7):
			return Placement.site(true, true, false, false, false, false, &"", &"", true)
		return Placement.site()
	assert_str(Buildings.why_not_at(COOP, at, busy)).is_equal(Placement.TAKEN_WORDS)
	# The doorstep is asked too: on the road it is refused.
	var road_below: Callable = func(cell: Vector2i) -> Dictionary: return Placement.site(true, true, cell == Vector2i(12, 8))
	assert_str(Buildings.why_not_at(COOP, at, road_below)).is_equal(Placement.ROAD_WORDS)
	# ...but a well has no doorstep to ask about.
	var road_below_well: Callable = func(cell: Vector2i) -> Dictionary: return Placement.site(true, true, cell == Vector2i(11, 7))
	assert_str(Buildings.why_not_at(WELL, at, road_below_well)).is_empty()
	# A path under it is no hindrance (a building stands over what lies), tall grass is.
	var path: Callable = func(_cell: Vector2i) -> Dictionary: return Placement.site(true, true, false, false, false, false, &"dirt_path")
	assert_str(Buildings.why_not_at(WELL, at, path)).is_empty()
	var grass: Callable = func(cell: Vector2i) -> Dictionary: return Placement.site(true, true, false, false, false, cell == Vector2i(11, 6))
	assert_str(Buildings.why_not_at(WELL, at, grass)).is_equal(Placement.CLEAR_FIRST_WORDS)
	# Off his land, every cell says so.
	var away: Callable = func(_cell: Vector2i) -> Dictionary: return Placement.site(false)
	assert_str(Buildings.why_not_at(WELL, at, away)).is_equal(Placement.NOT_LAND_WORDS)
	# A doorstep of another building under it, a field, the edge of the map.
	for case: Array in [[Placement.site(true, true, false, true), Placement.DOORSTEP_WORDS],
			[Placement.site(true, true, false, false, true), Placement.FIELD_WORDS],
			[Placement.site(true, false), Placement.NO_GROUND_WORDS]]:
		var one: Dictionary = case[0]
		var only_one: Callable = func(cell: Vector2i) -> Dictionary: return one if cell == Vector2i(10, 5) else Placement.site()
		assert_str(Buildings.why_not_at(COOP, at, only_one)).is_equal(case[1])


func test_its_look_is_laid_as_the_map_baker_lays_a_house() -> void:
	var tiles: Dictionary = Buildings.tiles_of(Buildings.look_of(COOP))
	assert_int(tiles.size()).is_equal(12)
	assert_str(tiles[Vector2i(0, 0)]).is_equal("roof_thatch_top_l")
	assert_str(tiles[Vector2i(1, 0)]).is_equal("roof_thatch_top")
	assert_str(tiles[Vector2i(3, 0)]).is_equal("roof_thatch_top_r")
	assert_str(tiles[Vector2i(0, 1)]).is_equal("roof_thatch_eave_l")
	assert_str(tiles[Vector2i(2, 1)]).is_equal("roof_thatch_eave")
	assert_str(tiles[Vector2i(0, 2)]).is_equal("wall")
	assert_str(tiles[Vector2i(1, 2)]).override_failure_message("a window every third cell").is_equal("wall_window")
	assert_str(tiles[Vector2i(2, 2)]).override_failure_message("the door over the wall").is_equal("door")
	assert_dict(Buildings.decor_of(Buildings.look_of(COOP))).is_equal({Vector2i(3, 0): "chimney"})
	# The upgrade's own look; a building without one keeps its own.
	assert_str(Buildings.tiles_of(Buildings.look_of(COOP, true))[Vector2i(0, 0)]).is_equal("roof_top_l")
	assert_str(Buildings.tiles_of(Buildings.look_of(WELL, true))[Vector2i(0, 0)]).is_equal("well_nw")
	assert_dict(Buildings.tiles_of(Buildings.look_of(SILO))).is_equal({Vector2i(0, 0): "silo_nw", Vector2i(1, 0): "silo_ne", Vector2i(0, 1): "silo_sw", Vector2i(1, 1): "silo_se"})
	# Every kind the baker would lay is a kind the atlas has.
	for kind: String in tiles.values():
		assert_bool(GreyboxTiles.is_known_kind(kind)).override_failure_message(kind).is_true()
	# A site: dug ground, its timber in the middle of its bottom row.
	var site: Dictionary = Buildings.site_tiles(Vector2i(4, 3))
	assert_int(site.size()).is_equal(12)
	assert_str(site[Vector2i(1, 2)]).is_equal(Buildings.SITE_TIMBER)
	assert_int(site.values().count(Buildings.SITE_TILE)).is_equal(11)


func test_what_it_does_and_holds_and_its_names() -> void:
	assert_bool(Buildings.fills_can(WELL)).is_true()
	assert_bool(Buildings.fills_can(SILO)).is_false()
	assert_dict(Buildings.holds(SILO)).is_equal({"item": &"hay", "count": 60})
	assert_dict(Buildings.holds(WELL)).is_empty()
	assert_bool(Buildings.casts_shadow(WELL)).is_false()
	assert_bool(Buildings.casts_shadow(SILO)).is_true()
	assert_str(Buildings.name_of(COOP)).is_equal("Coop")
	assert_str(Buildings.name_of(COOP, true)).is_equal("Big Coop")
	assert_str(Buildings.name_of(WELL, true)).override_failure_message("no upgrade: its own name").is_equal("Well")
	assert_int(Buildings.animals_of(COOP)).is_equal(4)
	assert_int(Buildings.animals_of(COOP, true)).is_equal(8)
	assert_int(Buildings.animals_of(WELL)).is_equal(0)
	var shed: Dictionary = {"keeps": {"furnaces": ["shed"], "chests": ["shed_a", "shed_b"]}}
	assert_array(Buildings.kept_in(shed, true)).is_equal([&"shed_a", &"shed_b"])
	assert_array(Buildings.kept_in(shed, false)).is_equal([&"shed"])
	assert_array(Buildings.kept_in(WELL, true)).is_empty()


func test_pulling_it_down_gives_back_half_of_each_material_and_no_coins() -> void:
	var needs: Array = [{"item": "wood", "count": 30}, {"item": "stone", "count": 21}, {"item": "fibre", "count": 15},
		{"item": "coin", "count": 250}, {"item": "copper_bar", "count": 1}]
	assert_array(Buildings.refund(needs)).is_equal([{"item": "wood", "count": 15}, {"item": "stone", "count": 10}, {"item": "fibre", "count": 7}])
	# A plan and its upgrade together: what is named twice is added before it is halved.
	var both: Array = needs + [{"item": "wood", "count": 20}, {"item": "iron_bar", "count": 2}, {"item": "coin", "count": 350}]
	assert_array(Buildings.refund(both)).is_equal([{"item": "wood", "count": 25}, {"item": "stone", "count": 10}, {"item": "fibre", "count": 7}, {"item": "iron_bar", "count": 1}])
	assert_array(Buildings.refund([])).is_empty()


func test_the_games_buildings_load_clean_and_each_has_its_kit() -> void:
	for id: StringName in DataRegistry.ids(&"buildings"):
		var building: Dictionary = DataRegistry.get_building(id)
		var problems: PackedStringArray = Buildings.problems(building, func(kind: String) -> bool: return GreyboxTiles.is_known_kind(kind),
			func(room: String) -> bool: return ResourceLoader.exists(WorldPaths.scene_for(StringName(room))))
		assert_array(Array(problems)).override_failure_message("%s: %s" % [id, problems]).is_empty()
		assert_that(Buildings.kit_for(id, DataRegistry.entries(&"items"))).override_failure_message("%s has a kit" % id).is_not_equal(&"")
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_buildings_that_cant_be_used_say_why() -> void:
	var is_tile: Callable = func(kind: String) -> bool: return GreyboxTiles.is_known_kind(kind)
	var is_room: Callable = func(room: String) -> bool: return room == "coop"
	assert_array(Array(Buildings.problems(COOP, is_tile, is_room))).is_empty()
	assert_array(Array(Buildings.problems(WELL, is_tile, is_room))).is_empty()
	var cases: Array = [
		[{"size": [0, 2]}, "'size' must be [width, height], each 1 or more."],
		[{"size": "big"}, "'size' must be [width, height], each 1 or more."],
		[{"door": [2, 1]}, "'door' must be a cell of the building's bottom row."],
		[{"door": [9, 2]}, "'door' must be a cell of the building's bottom row."],
		[{"room": "kennel"}, "'room' names no room the game has: 'kennel'."],
		[{"holds": {"item": "hay"}}, "'holds' must name an 'item' and a 'count' of 1 or more."],
		[{"animals": -1}, "'animals' must be a whole number of 0 or more."],
		[{"look": []}, "'look' must list one block or more."],
		[{"look": [[0, 0, 5, 1, "wall"]]}, "a block of 'look' lies outside the building: [0, 0, 5, 1, \"wall\"]."],
		[{"look": [[0, 0, 1, 1, "marble"]]}, "'look' names an unknown tile 'marble'."],
		[{"look": [[0, 0, 1, 1]]}, "every block of 'look' is [x, y, width, height, kind]."],
		[{"look": [[0, 0, 1, 2, "well"]]}, "'well' is a 2 by 2 picture: its block must be whole pictures."],
		[{"big": {"animals": 8}}, "'big' must be an object with a 'name' (the upgrade's)."],
	]
	for case: Array in cases:
		var building: Dictionary = COOP.duplicate(true)
		building.merge(case[0], true)
		assert_array(Array(Buildings.problems(building, is_tile, is_room))).override_failure_message("%s" % [case[0]]).contains([case[1]])
	var doorless: Dictionary = COOP.duplicate(true)
	doorless.erase("door")
	assert_array(Array(Buildings.problems(doorless, is_tile, is_room))).contains(["a building with a 'room' needs a 'door' to it."])
	var roomless: Dictionary = COOP.duplicate(true)
	roomless.erase("room")
	assert_array(Array(Buildings.problems(roomless, is_tile, is_room))).contains(["a building with a door has a 'room' to go into."])
