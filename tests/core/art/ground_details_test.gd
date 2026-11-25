extends GdUnitTestSuite
## Ground details (the warm-ground plan, step 3), pure: which cell gets which detail. The same
## cell always gets the same detail; none lands where something lies, stands or grows, on
## anything but open ground, or beside other ground; about one grass cell in four has one; and
## the rules in data are whole.

const GRASS: Vector2i = Vector2i(0, GreyboxTiles.ROW_GROUND)
const GRASS_RISE: Vector2i = Vector2i(1, GreyboxTiles.ROW_GROUND)
const PATH: Vector2i = Vector2i(0, GreyboxTiles.ROW_PATH)
const FIELD: Vector2i = Vector2i(60, 60)

var _rules: GroundDetails


func before_test() -> void:
	_rules = GroundDetails.new(DataRegistry.get_rules(DataRegistry.RULES_GROUND_DETAIL))


func test_the_rules_in_data_are_whole_and_name_only_frames_of_the_sheet() -> void:
	var rules: Dictionary = DataRegistry.get_rules(DataRegistry.RULES_GROUND_DETAIL)
	assert_bool(rules.is_empty()).override_failure_message("data/rules/ground_detail.json is read").is_false()
	assert_array(Array(GroundDetails.problems(rules))).is_empty()
	assert_bool(DataRegistry.RULE_SETS.has(DataRegistry.RULES_GROUND_DETAIL)).is_true()
	for ground: StringName in GroundDetails.GROUNDS:
		assert_array(_rules.details_of(ground)).override_failure_message("%s has details" % ground).is_not_empty()
	var broken: Dictionary = rules.duplicate(true)
	broken["grounds"]["grass"]["details"]["mushroom"] = 2
	broken["grounds"]["grass"]["chance"] = 1.5
	broken["grounds"]["water"] = {"chance": 0.5, "details": {"clover": 1}}
	broken["places"] = ["outdoor", "attic"]
	var problems: String = "\n".join(GroundDetails.problems(broken))
	for word: String in ["mushroom", "'chance'", "water", "attic"]:
		assert_str(problems).override_failure_message("a problem names %s:\n%s" % [word, problems]).contains(word)


func test_outdoors_the_quarry_and_the_dungeons_have_details_and_houses_none() -> void:
	assert_bool(_rules.shows_in(Ambience.OUTDOOR)).is_true()
	assert_bool(_rules.shows_in(Ambience.DUNGEON)).is_true()
	assert_bool(_rules.shows_in(Ambience.INTERIOR)).is_false()


func test_which_tiles_are_ground_with_details() -> void:
	assert_str(String(GroundDetails.ground_of(GRASS))).is_equal("grass")
	assert_str(String(GroundDetails.ground_of(GRASS_RISE))).is_equal("grass")
	assert_str(String(GroundDetails.ground_of(PATH))).is_equal("path")
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("dungeon_floor")))).is_equal("floor")
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("ledge", 1)))).is_equal("ledge")
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("cave_floor")))).is_equal("cave")
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("marsh")))).is_equal("marsh")
	# Never water, a wall, a door, stairs, a house's floor, solid ground under a prop, a pit,
	# rock on the heights, a boardwalk.
	for kind: String in ["water", "wall", "door", "floor", "rug", "doormat", "pit", "dungeon_wall", "marsh_solid", "cave_solid", "boardwalk", "cave_wall"]:
		assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords(kind)))).override_failure_message(kind).is_empty()
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("stairs", 1)))).is_empty()
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("solid_ground", 0)))).is_empty()
	assert_str(String(GroundDetails.ground_of(GreyboxTiles.coords("ground", 4)))).override_failure_message("rock on the heights").is_empty()


func test_the_same_cell_always_gets_the_same_detail() -> void:
	var tiles: Dictionary = _field(GRASS, 40)
	var first: Dictionary = _rules.place(tiles, {})
	var again: Dictionary = GroundDetails.new(DataRegistry.get_rules(DataRegistry.RULES_GROUND_DETAIL)).place(tiles, {})
	assert_bool(first.is_empty()).is_false()
	assert_dict(again).is_equal(first)
	for cell: Vector2i in first:
		assert_str(String(_rules.detail_at(cell, tiles, {}))).is_equal(String(first[cell]))
		assert_bool(_rules.is_mirrored(cell, first[cell])).is_equal(_rules.is_mirrored(cell, first[cell]))
	# The roll depends on the cell alone, not on what else is in the map.
	var small: Dictionary = _field(GRASS, 10)
	for cell: Vector2i in _rules.place(small, {}):
		assert_str(String(first.get(cell, &""))).is_equal(String(_rules.place(small, {})[cell]))


func test_about_one_grass_cell_in_four_has_a_detail_and_every_kind_is_seen() -> void:
	var tiles: Dictionary = _field(GRASS, 120)
	var placed: Dictionary = _rules.place(tiles, {})
	var open: int = 0
	for cell: Vector2i in tiles:
		open += 1 if GroundDetails.is_clear(cell, tiles, {}) else 0
	var share: float = placed.size() / float(open)
	assert_float(share).override_failure_message("share %.3f" % share).is_between(0.2, 0.32)
	var seen: Dictionary = {}
	for cell: Vector2i in placed:
		seen[placed[cell]] = true
	for detail: StringName in _rules.details_of(GroundDetails.GRASS):
		assert_bool(seen.has(detail)).override_failure_message("%s is seen" % detail).is_true()
	# Half or so are mirrored; pebbles never, being lit from one side.
	var mirrored: int = 0
	for cell: Vector2i in placed:
		mirrored += 1 if _rules.is_mirrored(cell, placed[cell]) else 0
		if placed[cell] == &"pebbles":
			assert_bool(_rules.is_mirrored(cell, placed[cell])).is_false()
	assert_float(mirrored / float(placed.size())).is_between(0.3, 0.6)


func test_drifts_gather_the_sunlit_and_shaded_patches_in_squares() -> void:
	var tiles: Dictionary = _field(GRASS, 120)
	var placed: Dictionary = _rules.place(tiles, {})
	# A square of four by four cells holds patches of one kind only, and no other detail.
	var squares: Dictionary = {}
	for cell: Vector2i in placed:
		var detail: StringName = placed[cell]
		var square: Vector2i = Vector2i(floori(cell.x / 4.0), floori(cell.y / 4.0))
		if not squares.has(square):
			squares[square] = {}
		(squares[square] as Dictionary)[detail] = true
	var drifts: int = 0
	for square: Vector2i in squares:
		var kinds: Dictionary = squares[square]
		if kinds.has(&"sunlit") or kinds.has(&"shaded"):
			drifts += 1
			assert_int(kinds.size()).override_failure_message("square %s: one kind of patch" % square).is_equal(1)
	assert_int(drifts).is_greater(20)


func test_nothing_lands_where_something_is_held_or_just_above_it() -> void:
	var tiles: Dictionary = _field(GRASS, 40)
	var free: Dictionary = _rules.place(tiles, {})
	var cell: Vector2i = free.keys()[0]
	assert_str(String(_rules.detail_at(cell, tiles, {cell: true}))).override_failure_message("held: decor, a marker, an interactable, the plot, a placed thing, a building").is_empty()
	# Above a held cell: what stands there may rise over it.
	assert_str(String(_rules.detail_at(cell, tiles, {cell + Vector2i.DOWN: true}))).override_failure_message("above a held cell").is_empty()
	# Beside, below or on a diagonal from one, it is still there.
	for side: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i(1, 1)]:
		assert_str(String(_rules.detail_at(cell, tiles, {cell + side: true}))).override_failure_message("held at %s" % side).is_equal(String(free[cell]))
	# Everything held in a whole field: no detail on any held cell or beside one.
	var held: Dictionary = {}
	for x: int in range(0, 40, 3):
		for y: int in range(0, 40, 5):
			held[Vector2i(x, y)] = true
	var placed: Dictionary = _rules.place(tiles, held)
	assert_bool(placed.is_empty()).is_false()
	for at: Vector2i in placed:
		assert_bool(held.has(at)).is_false()
		assert_bool(held.has(at + Vector2i.DOWN)).override_failure_message("%s is above a held cell" % at).is_false()


func test_nothing_lands_on_other_ground_or_beside_it() -> void:
	var tiles: Dictionary = _field(GRASS, 40)
	var free: Dictionary = _rules.place(tiles, {})
	var cell: Vector2i = free.keys()[0]
	# Water, a wall, a doorway, a pit in the cell itself: never.
	for kind: String in ["water", "wall", "door", "pit"]:
		var here: Dictionary = tiles.duplicate()
		here[cell] = GreyboxTiles.coords(kind)
		assert_str(String(_rules.detail_at(cell, here, {}))).override_failure_message("on %s" % kind).is_empty()
	# Beside water, a path, a rise or the map's edge: never.
	for other: Vector2i in [GreyboxTiles.coords("water"), PATH, GRASS_RISE]:
		for side: Vector2i in GroundDetails.SIDES:
			var here: Dictionary = tiles.duplicate()
			here[cell + side] = other
			assert_str(String(_rules.detail_at(cell, here, {}))).override_failure_message("beside %s (%s)" % [other, side]).is_empty()
	# Solid grass under a prop looks like grass: beside it a detail may be.
	var twin: Dictionary = tiles.duplicate()
	twin[cell + Vector2i.LEFT] = GreyboxTiles.coords("solid_ground", 0)
	assert_str(String(_rules.detail_at(cell, twin, {}))).is_equal(String(free[cell]))
	twin[cell + Vector2i.LEFT] = GreyboxTiles.coords("solid_ground", 1)
	assert_str(String(_rules.detail_at(cell, twin, {}))).override_failure_message("beside a rise's solid twin").is_empty()
	var edge: Dictionary = tiles.duplicate()
	edge.erase(cell + Vector2i.LEFT)
	assert_str(String(_rules.detail_at(cell, edge, {}))).override_failure_message("at the map's edge").is_empty()
	# A field of path, a field of grass: none on the line where they meet.
	var meeting: Dictionary = _field(GRASS, 40)
	for at: Vector2i in meeting.keys():
		if at.x - FIELD.x >= 20:
			meeting[at] = PATH
	var placed: Dictionary = _rules.place(meeting, {})
	for at: Vector2i in placed:
		assert_bool(at.x - FIELD.x == 19 or at.x - FIELD.x == 20).override_failure_message("%s is where grass meets path" % at).is_false()
		var on_path: bool = at.x - FIELD.x >= 20
		assert_bool(_rules.details_of(GroundDetails.PATH if on_path else GroundDetails.GRASS).has(placed[at])).override_failure_message("%s: %s is a detail of its own ground" % [at, placed[at]]).is_true()


func test_each_ground_gets_only_its_own_details() -> void:
	var kinds: Dictionary = {
		GroundDetails.PATH: PATH, GroundDetails.FLOOR: GreyboxTiles.coords("dungeon_floor"),
		GroundDetails.LEDGE: GreyboxTiles.coords("ledge", 0), GroundDetails.CAVE: GreyboxTiles.coords("cave_floor"),
		GroundDetails.MARSH: GreyboxTiles.coords("marsh"),
	}
	for ground: StringName in kinds:
		var placed: Dictionary = _rules.place(_field(kinds[ground], 40), {})
		assert_bool(placed.is_empty()).override_failure_message("%s gets details" % ground).is_false()
		for cell: Vector2i in placed:
			assert_bool(_rules.details_of(ground).has(placed[cell])).override_failure_message("%s: %s" % [ground, placed[cell]]).is_true()


func test_the_density_is_one_number_in_data() -> void:
	var rules: Dictionary = DataRegistry.get_rules(DataRegistry.RULES_GROUND_DETAIL).duplicate(true)
	var tiles: Dictionary = _field(PATH, 60)
	rules["grounds"]["path"]["chance"] = 0.0
	assert_dict(GroundDetails.new(rules).place(tiles, {})).is_empty()
	rules["grounds"]["path"]["chance"] = 1.0
	var every: Dictionary = GroundDetails.new(rules).place(tiles, {})
	var open: int = 0
	for cell: Vector2i in tiles:
		open += 1 if GroundDetails.is_clear(cell, tiles, {}) else 0
	assert_int(every.size()).is_equal(open)


## A square map of `size` cells of `tile`, shifted off the origin so negative cells never come in.
func _field(tile: Vector2i, size: int) -> Dictionary:
	var out: Dictionary = {}
	for y: int in size:
		for x: int in size:
			out[FIELD + Vector2i(x, y)] = tile
	return out
