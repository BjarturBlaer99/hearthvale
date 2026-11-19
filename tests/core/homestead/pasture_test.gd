extends GdUnitTestSuite
## Pastures (the Homestead, phase 4; the plan's D25), pure: the ground reached from a door
## without crossing anything that stands; a gap in the fence, or ground that runs on to the road
## or off the map, is no pasture; what lies on the grass (a floor, a path) and the field are
## walked over and not grazed.

## A little map: "." grass, "#" a fence (or anything standing), "_" a floor, "=" the road.
func _map(rows: Array) -> Callable:
	return func(cell: Vector2i) -> StringName:
		match str(rows[cell.y])[cell.x]:
			"#":
				return Pasture.WALL
			"_":
				return Pasture.BARE
			"=":
				return Pasture.OPEN
		return Pasture.GRASS


const PEN: Array = [
	"########",
	"#......#",
	"#......#",
	"#..__..#",
	"########",
]


func test_a_fenced_pen_is_a_pasture_and_a_floor_is_not_grass() -> void:
	var reached: Dictionary = Pasture.reach(Vector2i(1, 1), Vector2i(8, 5), _map(PEN))
	assert_bool(reached["fenced"]).is_true()
	assert_int((reached["cells"] as Array).size()).is_equal(18)
	assert_int(int(reached["grass"])).override_failure_message("two cells of floor are walked, not grazed").is_equal(16)
	assert_bool(Pasture.is_pasture(reached)).is_true()
	assert_int(Pasture.feeds(16, 4)).is_equal(4)
	assert_int(Pasture.feeds(16, 6)).is_equal(2)


func test_a_gap_in_the_fence_is_no_pasture() -> void:
	# The gap opens on the edge of the map.
	var gap: Array = PEN.duplicate()
	gap[4] = "####.###"
	var reached: Dictionary = Pasture.reach(Vector2i(1, 1), Vector2i(8, 5), _map(gap))
	assert_bool(reached["fenced"]).is_false()
	assert_bool(Pasture.is_pasture(reached)).is_false()
	# The gap opens on the road.
	var road: Array = ["####=###", "#......#", "#......#", "#......#", "########"]
	reached = Pasture.reach(Vector2i(2, 2), Vector2i(8, 5), _map(road))
	assert_bool(Pasture.is_pasture(reached)).override_failure_message("ground that runs on to the road").is_false()
	# A gap that leads only into another closed pen is still fenced: the two are one pasture.
	var two: Array = ["##########", "#...#....#", "#.......##", "##########"]
	reached = Pasture.reach(Vector2i(1, 1), Vector2i(10, 4), _map(two))
	assert_bool(reached["fenced"]).is_true()
	assert_int(int(reached["grass"])).is_equal(14)


func test_a_pen_of_floor_only_is_no_pasture_and_a_wall_reaches_nothing() -> void:
	var paved: Array = ["####", "#__#", "####"]
	var reached: Dictionary = Pasture.reach(Vector2i(1, 1), Vector2i(4, 3), _map(paved))
	assert_bool(reached["fenced"]).is_true()
	assert_int(int(reached["grass"])).is_equal(0)
	assert_bool(Pasture.is_pasture(reached)).is_false()
	reached = Pasture.reach(Vector2i(0, 0), Vector2i(4, 3), _map(paved))
	assert_array(reached["cells"]).is_empty()
	assert_bool(Pasture.is_pasture(reached)).is_false()
