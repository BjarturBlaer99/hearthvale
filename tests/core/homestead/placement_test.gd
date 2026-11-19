extends GdUnitTestSuite
## Placement (the Homestead, phase 2), pure: what a placeable is, and whether one fits a cell.
## Every refusal of the plan's table, with its words, in the table's order; two things to a
## cell at most, one lying and one standing; only on the hero's land.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const FENCE: Dictionary = {"id": "fence", "name": "Fence", "type": "placeable", "icon": "fence", "stackable": true, "max_stack": 99,
	"stats": {"layer": "standing", "joins": true}}
const GATE: Dictionary = {"id": "gate", "name": "Gate", "type": "placeable", "icon": "gate", "stackable": true, "max_stack": 20,
	"stats": {"layer": "standing", "joins": true, "blocks": false}}
const PATH: Dictionary = {"id": "dirt_path", "name": "Dirt Path", "type": "placeable", "icon": "dirt_path", "stackable": true, "max_stack": 99,
	"stats": {"layer": "lying"}}
const STONE: Dictionary = {"id": "stone", "name": "Stone", "type": "material", "stackable": true, "max_stack": 50}


func test_the_words_are_the_plans() -> void:
	assert_str(Placement.NOT_LAND_WORDS).is_equal("You can only build on your own land.")
	assert_str(Placement.NO_GROUND_WORDS).is_equal("Nothing can stand there.")
	assert_str(Placement.ROAD_WORDS).is_equal("That is the road.")
	assert_str(Placement.DOORSTEP_WORDS).is_equal("That is a doorstep.")
	assert_str(Placement.FIELD_WORDS).is_equal("That is your field.")
	assert_str(Placement.CLEAR_FIRST_WORDS).is_equal("Clear this first.")
	assert_str(Placement.CLEAR_FIRST_WORDS).override_failure_message("the hoe's own words at such a cell").is_equal(ToolUse.CLEAR_FIRST)
	assert_str(Placement.TAKEN_WORDS).is_equal("Something is there already.")
	assert_str(Placement.SOMEONE_WORDS).is_equal("Someone is standing there.")


func test_a_placeable_lies_or_stands_as_its_data_says() -> void:
	assert_bool(Placement.is_placeable(FENCE)).is_true()
	assert_bool(Placement.is_placeable(STONE)).is_false()
	assert_bool(Placement.is_placeable({})).is_false()
	assert_that(Placement.layer_of(FENCE)).is_equal(Placement.STANDING)
	assert_that(Placement.layer_of(GATE)).is_equal(Placement.STANDING)
	assert_that(Placement.layer_of(PATH)).is_equal(Placement.LYING)
	assert_that(Placement.layer_of(STONE)).override_failure_message("stone is no placeable").is_equal(&"")
	assert_that(Placement.layer_of({"type": "placeable", "stats": {"layer": "floating"}})).override_failure_message("no such layer").is_equal(&"")
	assert_that(Placement.layer_of({"type": "placeable"})).is_equal(&"")
	# A standing thing fills its cell unless it says otherwise; a lying thing never does.
	assert_bool(Placement.blocks(FENCE)).is_true()
	assert_bool(Placement.blocks(GATE)).override_failure_message("the hero walks through a gate").is_false()
	assert_bool(Placement.blocks(PATH)).override_failure_message("a path is walked on").is_false()
	var blocking_path: Dictionary = PATH.duplicate(true)
	blocking_path["stats"]["blocks"] = true
	assert_bool(Placement.blocks(blocking_path)).override_failure_message("whatever a lying thing says").is_false()
	assert_bool(Placement.blocks(STONE)).is_false()
	# A fence and a gate run on to their neighbours; a path doesn't.
	assert_bool(Placement.joins(FENCE) and Placement.joins(GATE)).is_true()
	assert_bool(Placement.joins(PATH) or Placement.joins(STONE)).is_false()
	assert_array(Placement.LAYERS).is_equal([Placement.LYING, Placement.STANDING])


func test_on_open_ground_of_his_land_anything_fits() -> void:
	for item: Dictionary in [FENCE, GATE, PATH]:
		assert_str(Placement.why_not(item, Placement.site())).override_failure_message(str(item["id"])).is_equal("")


func test_every_refusal_says_its_words() -> void:
	# [what is in the way, the words], for a standing thing and for a lying one alike.
	var rows: Array = [
		[{"land": false}, Placement.NOT_LAND_WORDS],
		[{"ground": false}, Placement.NO_GROUND_WORDS],
		[{"road": true}, Placement.ROAD_WORDS],
		[{"doorstep": true}, Placement.DOORSTEP_WORDS],
		[{"field": true}, Placement.FIELD_WORDS],
		[{"debris": true}, Placement.CLEAR_FIRST_WORDS],
	]
	for row: Array in rows:
		for item: Dictionary in [FENCE, GATE, PATH]:
			var at: Dictionary = Placement.site()
			at.merge(row[0], true)
			assert_str(Placement.why_not(item, at)).override_failure_message("%s at %s" % [item["id"], row[0]]).is_equal(row[1])
	# Where a thing of its kind is already: a standing thing where one stands, a lying thing
	# where one lies.
	assert_str(Placement.why_not(FENCE, Placement.site(true, true, false, false, false, false, &"", &"gate"))).is_equal(Placement.TAKEN_WORDS)
	assert_str(Placement.why_not(PATH, Placement.site(true, true, false, false, false, false, &"stone_path", &""))).is_equal(Placement.TAKEN_WORDS)
	# A standing thing, on the cell someone is in.
	var with_hero: Dictionary = Placement.site()
	with_hero["someone"] = true
	assert_str(Placement.why_not(FENCE, with_hero)).is_equal(Placement.SOMEONE_WORDS)
	assert_str(Placement.why_not(GATE, with_hero)).override_failure_message("a gate stands too").is_equal(Placement.SOMEONE_WORDS)
	assert_str(Placement.why_not(PATH, with_hero)).override_failure_message("a path may be laid under his feet").is_equal("")
	# What is no placeable is never set down.
	assert_str(Placement.why_not(STONE, Placement.site())).is_equal(Placement.NOT_PLACEABLE_WORDS)
	assert_str(Placement.why_not({}, Placement.site())).is_equal(Placement.NOT_PLACEABLE_WORDS)


func test_two_things_to_a_cell_one_lying_and_one_standing() -> void:
	var paved: Dictionary = Placement.site(true, true, false, false, false, false, &"stone_path", &"")
	assert_str(Placement.why_not(FENCE, paved)).override_failure_message("a fence on a paved cell").is_equal("")
	assert_str(Placement.why_not(PATH, paved)).override_failure_message("a second path").is_equal(Placement.TAKEN_WORDS)
	var fenced: Dictionary = Placement.site(true, true, false, false, false, false, &"", &"fence")
	assert_str(Placement.why_not(PATH, fenced)).override_failure_message("a path under a fence").is_equal("")
	assert_str(Placement.why_not(GATE, fenced)).override_failure_message("a second standing thing").is_equal(Placement.TAKEN_WORDS)
	var both: Dictionary = Placement.site(true, true, false, false, false, false, &"stone_path", &"fence")
	for item: Dictionary in [FENCE, GATE, PATH]:
		assert_str(Placement.why_not(item, both)).override_failure_message("a third thing: %s" % item["id"]).is_equal(Placement.TAKEN_WORDS)


func test_what_lies_to_be_picked_up_is_not_shut_in() -> void:
	var with_stone: Dictionary = Placement.site()
	with_stone["left"] = true
	assert_str(Placement.why_not(FENCE, with_stone)).is_equal(Placement.TAKEN_WORDS)
	assert_str(Placement.why_not(PATH, with_stone)).override_failure_message("a path may be laid under it").is_equal("")


func test_the_first_refusal_in_the_tables_order_is_the_one_said() -> void:
	# Everything in the way at once, then one thing less each time.
	var at: Dictionary = {"land": false, "ground": false, "road": true, "doorstep": true, "field": true, "debris": true,
		"lying": &"dirt_path", "standing": &"fence", "someone": true, "left": true}
	var order: Array = [
		["land", true, Placement.NOT_LAND_WORDS], ["ground", true, Placement.NO_GROUND_WORDS], ["road", false, Placement.ROAD_WORDS],
		["doorstep", false, Placement.DOORSTEP_WORDS], ["field", false, Placement.FIELD_WORDS], ["debris", false, Placement.CLEAR_FIRST_WORDS],
		["standing", &"", Placement.TAKEN_WORDS], ["left", false, Placement.TAKEN_WORDS], ["someone", false, Placement.SOMEONE_WORDS],
	]
	for step: Array in order:
		assert_str(Placement.why_not(FENCE, at)).override_failure_message("before %s is out of the way" % step[0]).is_equal(step[2])
		at[step[0]] = step[1]
	assert_str(Placement.why_not(FENCE, at)).override_failure_message("a path lying there is no hindrance to a fence").is_equal("")
	# Off his land nothing else is even looked at; a missing answer is a refusal, never a yes.
	assert_str(Placement.why_not(FENCE, {})).is_equal(Placement.NOT_LAND_WORDS)
	assert_str(Placement.why_not(FENCE, {"land": true})).is_equal(Placement.NO_GROUND_WORDS)


func test_the_real_placeables_are_what_the_plan_lists() -> void:
	# [id, name, lies or stands, blocks, joins, a stack]
	var rows: Array = [
		[&"dirt_path", "Dirt Path", Placement.LYING, false, false], [&"stone_path", "Stone Path", Placement.LYING, false, false],
		[&"wood_path", "Wood Path", Placement.LYING, false, false],
		[&"fence", "Fence", Placement.STANDING, true, true], [&"gate", "Gate", Placement.STANDING, false, true],
		[&"wooden_flooring", "Wooden Flooring", Placement.LYING, false, false], [&"stone_flooring", "Stone Flooring", Placement.LYING, false, false],
		[&"hedge", "Hedge", Placement.STANDING, true, false], [&"lamp_post", "Lamp Post", Placement.STANDING, true, false],
		[&"bench", "Bench", Placement.STANDING, true, false], [&"flower_bed_red", "Red Flower Bed", Placement.LYING, false, false],
		[&"flower_bed_yellow", "Yellow Flower Bed", Placement.LYING, false, false], [&"flower_bed_blue", "Blue Flower Bed", Placement.LYING, false, false],
		[&"oak_sapling", "Oak Sapling", Placement.STANDING, true, false], [&"cherry_sapling", "Cherry Sapling", Placement.STANDING, true, false],
	]
	for row: Array in rows:
		var item: Dictionary = DataRegistry.get_item(row[0])
		assert_bool(item.is_empty()).override_failure_message("%s is data" % row[0]).is_false()
		assert_str(str(item["name"])).is_equal(row[1])
		assert_that(Placement.layer_of(item)).override_failure_message(String(row[0])).is_equal(row[2])
		assert_bool(Placement.blocks(item)).override_failure_message("%s blocks" % row[0]).is_equal(row[3])
		assert_bool(Placement.joins(item)).override_failure_message("%s joins" % row[0]).is_equal(row[4])
		assert_bool(Inventory.capacity(item) > 1).override_failure_message("%s stacks" % row[0]).is_true()
		assert_bool(PlacedArt.has(Placement.frame_of(item))).override_failure_message("%s has its picture" % row[0]).is_true()
		assert_that(ItemIcons.name_for(row[0])).override_failure_message("and the same picture on the bar").is_equal(Placement.frame_of(item))
		# It is set down in build mode, never used from the hand, eaten or given.
		assert_bool(Inventory.is_equippable(item)).override_failure_message("%s is never on the item bar" % row[0]).is_false()
		assert_bool(Food.is_food(item)).is_false()
		assert_bool(GameState.friendship().is_giftable(item)).is_false()
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_a_placeable_that_cant_be_used_is_reported() -> void:
	var trees: Array = ["oak", "cherry"]
	assert_array(Array(Placement.problems(FENCE, trees))).is_empty()
	assert_array(Array(Placement.problems(GATE, trees))).is_empty()
	assert_array(Array(Placement.problems(PATH, trees))).is_empty()
	assert_array(Array(Placement.problems({"id": "x", "type": "placeable", "icon": "x", "stackable": true}, trees))).contains_exactly(
		["a placeable's stats need 'layer': 'lying' or 'standing'."])
	assert_array(Array(Placement.problems({"id": "x", "type": "placeable", "stats": {"layer": "standing"}}, trees))).contains_exactly([
		"a placeable must stack (it is counted on the build bar).",
		"a placeable needs an 'icon': it is its picture on the ground too.",
	])
	var lying: Dictionary = {"id": "x", "type": "placeable", "icon": "x", "stackable": true, "stats": {"layer": "lying", "blocks": true, "joins": true}}
	assert_array(Array(Placement.problems(lying, trees))).contains_exactly([
		"'blocks' is for a standing thing: a lying one never blocks, joins, shines or grows.",
		"'joins' is for a standing thing: a lying one never blocks, joins, shines or grows.",
	])
	var odd: Dictionary = {"id": "x", "type": "placeable", "icon": "x", "stackable": true, "stats": {"layer": "standing", "blocks": "no", "joins": 1}}
	assert_array(Array(Placement.problems(odd, trees))).contains_exactly(["'blocks' must be true or false.", "'joins' must be true or false."])
	# The registry reports them, with the file and the item.
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_placeables"))
	assert_str(errors).contains("item 'floating_rug': a placeable's stats need 'layer': 'lying' or 'standing'.")
	assert_str(errors).contains("item 'loose_post': a placeable must stack (it is counted on the build bar).")
	assert_str(errors).contains("item 'glow_mat': 'light' is for a standing thing: a lying one never blocks, joins, shines or grows.")
	assert_str(errors).contains("item 'dark_lamp': 'light' needs a 'radius' above 0.")
	assert_str(errors).contains("item 'quick_sprig': 'grows' needs 'mornings', a whole number of 3 or more (a picture a stage).")
	assert_str(errors).contains("item 'quick_sprig': 'grows' names an unknown tree 'beanstalk'.")


# --- Step 2b: what covers its cell, what gives light, what grows -----------------

const FLOOR: Dictionary = {"id": "stone_flooring", "name": "Stone Flooring", "type": "placeable", "icon": "stone_flooring", "stackable": true,
	"max_stack": 99, "stats": {"layer": "lying", "fills": true}}
const BED: Dictionary = {"id": "flower_bed_red", "name": "Red Flower Bed", "type": "placeable", "icon": "flower_bed_red", "stackable": true,
	"max_stack": 30, "stats": {"layer": "lying"}}
const LAMP: Dictionary = {"id": "lamp_post", "name": "Lamp Post", "type": "placeable", "icon": "lamp_post", "stackable": true, "max_stack": 10,
	"stats": {"layer": "standing", "light": {"at": [8, 3], "radius": 22, "strength": 0.3}}}
const OAK: Dictionary = {"id": "oak_sapling", "name": "Oak Sapling", "type": "placeable", "icon": "oak_sapling", "stackable": true, "max_stack": 10,
	"stats": {"layer": "standing", "grows": {"mornings": 4, "tree": "oak"}}}
const CHERRY: Dictionary = {"id": "cherry_sapling", "name": "Cherry Sapling", "type": "placeable", "icon": "cherry_sapling", "stackable": true,
	"max_stack": 10, "stats": {"layer": "standing", "grows": {"mornings": 6, "tree": "cherry"}}}


func test_a_path_or_a_floor_covers_its_cell_and_a_flower_bed_does_not() -> void:
	assert_bool(Placement.fills(FLOOR)).is_true()
	assert_bool(Placement.fills(BED)).is_false()
	assert_bool(Placement.fills(PATH)).override_failure_message("the test's own path says nothing of it").is_false()
	assert_bool(Placement.fills(FENCE)).override_failure_message("a standing thing never does").is_false()
	var standing_fill: Dictionary = FENCE.duplicate(true)
	standing_fill["stats"]["fills"] = true
	assert_bool(Placement.fills(standing_fill)).is_false()
	assert_array(Array(Placement.problems(standing_fill, []))).contains_exactly(["'fills' is for a lying thing: a path or a floor that covers its cell."])
	var odd: Dictionary = FLOOR.duplicate(true)
	odd["stats"]["fills"] = "yes"
	assert_array(Array(Placement.problems(odd, []))).contains_exactly(["'fills' must be true or false."])
	assert_array(Array(Placement.problems(FLOOR, []))).is_empty()
	assert_array(Array(Placement.problems(BED, []))).is_empty()
	# Both lie: either fits under a fence, and neither on the other.
	assert_that(Placement.layer_of(FLOOR)).is_equal(Placement.LYING)
	assert_that(Placement.layer_of(BED)).is_equal(Placement.LYING)
	assert_str(Placement.why_not(BED, Placement.site(true, true, false, false, false, false, &"stone_flooring", &""))).is_equal(Placement.TAKEN_WORDS)


func test_a_lamp_post_says_where_its_light_is_and_how_far_it_reaches() -> void:
	assert_dict(Placement.light_of(LAMP)).is_equal({"at": Vector2(8, 3), "radius": 22.0, "strength": 0.3})
	assert_dict(Placement.light_of(FENCE)).override_failure_message("a fence gives none").is_empty()
	assert_dict(Placement.light_of(PATH)).is_empty()
	assert_dict(Placement.light_of({})).is_empty()
	# Without a place for it the light is in the middle of its cell; without a strength, 0.3.
	var plain: Dictionary = LAMP.duplicate(true)
	plain["stats"]["light"] = {"radius": 30}
	assert_dict(Placement.light_of(plain)).is_equal({"at": Vector2(8, 8), "radius": 30.0, "strength": 0.3})
	assert_bool(Placement.blocks(LAMP)).override_failure_message("a lamp post stands and blocks").is_true()
	assert_array(Array(Placement.problems(LAMP, []))).is_empty()
	plain["stats"]["light"] = {"radius": 30, "at": [8]}
	assert_array(Array(Placement.problems(plain, []))).contains_exactly(["'light' 'at' must be [x, y], a point in its cell."])
	plain["stats"]["light"] = "bright"
	assert_array(Array(Placement.problems(plain, []))).contains_exactly(["'light' needs a 'radius' above 0."])


func test_a_sapling_shows_three_pictures_and_is_a_tree_after_its_mornings() -> void:
	assert_int(Placement.STAGES).is_equal(3)
	assert_bool(Placement.is_sapling(OAK) and Placement.is_sapling(CHERRY)).is_true()
	assert_bool(Placement.is_sapling(FENCE) or Placement.is_sapling(LAMP) or Placement.is_sapling(PATH)).is_false()
	assert_int(Placement.mornings_of(OAK)).is_equal(4)
	assert_int(Placement.mornings_of(CHERRY)).is_equal(6)
	assert_int(Placement.mornings_of(FENCE)).is_equal(0)
	assert_str(Placement.tree_of(OAK)).is_equal("oak")
	assert_str(Placement.tree_of(CHERRY)).is_equal("cherry")
	assert_str(Placement.tree_of(FENCE)).is_equal("")
	# The oak: two mornings as a sprig, one as a young plant, one as a small tree, then a tree.
	var oak_stages: Array = []
	var oak_grown: Array = []
	for age: int in 7:
		oak_stages.append(Placement.stage_of(OAK, age))
		oak_grown.append(Placement.is_grown(OAK, age))
	assert_array(oak_stages).is_equal([0, 0, 1, 2, 2, 2, 2])
	assert_array(oak_grown).is_equal([false, false, false, false, true, true, true])
	# The cherry: two mornings a stage.
	var cherry_stages: Array = []
	for age: int in 8:
		cherry_stages.append(Placement.stage_of(CHERRY, age))
	assert_array(cherry_stages).is_equal([0, 0, 1, 1, 2, 2, 2, 2])
	assert_bool(Placement.is_grown(CHERRY, 5)).is_false()
	assert_bool(Placement.is_grown(CHERRY, 6)).is_true()
	# Its pictures: its icon's, then "_1" and "_2".
	assert_that(Placement.frame_of(OAK)).is_equal(&"oak_sapling")
	assert_that(Placement.frame_of(OAK, 1)).is_equal(&"oak_sapling")
	assert_that(Placement.frame_of(OAK, 2)).is_equal(&"oak_sapling_1")
	assert_that(Placement.frame_of(OAK, 3)).is_equal(&"oak_sapling_2")
	assert_that(Placement.frame_of(CHERRY, 4)).is_equal(&"cherry_sapling_2")
	assert_that(Placement.frame_of(OAK, -3)).override_failure_message("no age is before the first").is_equal(&"oak_sapling")
	# What doesn't grow has one picture at any age, and is never grown.
	assert_that(Placement.frame_of(FENCE, 9)).is_equal(&"fence")
	assert_int(Placement.stage_of(FENCE, 9)).is_equal(0)
	assert_bool(Placement.is_grown(FENCE, 99)).is_false()
	assert_bool(Placement.is_grown({}, 99)).is_false()
	# Every picture a sapling can show is painted.
	for sapling: Dictionary in [OAK, CHERRY]:
		for age: int in Placement.mornings_of(sapling):
			assert_bool(PlacedArt.has(Placement.frame_of(sapling, age))).override_failure_message("%s after %d mornings" % [sapling["id"], age]).is_true()
	# What grows, as a morning wants it.
	assert_dict(Placement.growing([FENCE, OAK, LAMP, CHERRY, PATH, 7, {}])).is_equal({"oak_sapling": 4, "cherry_sapling": 6})
	assert_dict(Placement.growing([])).is_empty()
	# The data's own two are the test's two.
	for pair: Array in [[&"oak_sapling", OAK], [&"cherry_sapling", CHERRY], [&"lamp_post", LAMP]]:
		var real: Dictionary = DataRegistry.get_item(pair[0])
		assert_int(Placement.mornings_of(real)).override_failure_message(String(pair[0])).is_equal(Placement.mornings_of(pair[1]))
		assert_str(Placement.tree_of(real)).is_equal(Placement.tree_of(pair[1]))
		assert_dict(Placement.light_of(real)).is_equal(Placement.light_of(pair[1]))
		assert_that(Placement.layer_of(real)).is_equal(Placement.layer_of(pair[1]))
	assert_array(Array(Placement.problems(OAK, SceneryAtlas.KINDS))).is_empty()
	assert_array(Array(Placement.problems(CHERRY, SceneryAtlas.KINDS))).is_empty()


func test_the_pictures_of_a_thing_are_put_together_from_its_frames() -> void:
	# A lamp post: its own picture, and the burning one while it is lit.
	assert_array(PlacedArt.pieces(LAMP)).is_equal([[&"lamp_post", false]])
	assert_array(PlacedArt.pieces(LAMP, 0, 0, true)).is_equal([[&"lamp_post_lit", false]])
	# A fence has no burning picture: lit or not, it is a fence.
	assert_array(PlacedArt.pieces(FENCE, 0, 0, true)).is_equal([[&"fence", false]])
	# A fence alone is its post; a neighbour to the west is the east rail mirrored, drawn first.
	assert_array(PlacedArt.pieces(FENCE)).is_equal([[&"fence", false]])
	assert_array(PlacedArt.pieces(FENCE, 0, PlacedArt.WEST)).is_equal([[&"fence_e", true], [&"fence", false]])
	assert_array(PlacedArt.pieces(FENCE, 0, PlacedArt.EAST)).is_equal([[&"fence_e", false], [&"fence", false]])
	assert_array(PlacedArt.pieces(FENCE, 0, PlacedArt.NORTH)).is_equal([[&"fence_n", false], [&"fence", false]])
	assert_array(PlacedArt.pieces(FENCE, 0, PlacedArt.SOUTH)).override_failure_message("the south rail over the post").is_equal([[&"fence", false], [&"fence_s", false]])
	# A gate stands across a fence that runs east and west, and along one that runs north and south.
	assert_array(PlacedArt.pieces(GATE, 0, PlacedArt.EAST | PlacedArt.WEST)).is_equal([[&"gate", false]])
	assert_array(PlacedArt.pieces(GATE, 0, PlacedArt.NORTH | PlacedArt.SOUTH)).is_equal([[&"gate_v", false]])
	assert_array(PlacedArt.pieces(GATE, 0, PlacedArt.NORTH | PlacedArt.EAST)).override_failure_message("in a corner it stands across").is_equal([[&"gate", false]])
	# A sapling's picture is its stage's.
	assert_array(PlacedArt.pieces(OAK, 3)).is_equal([[&"oak_sapling_2", false]])
	assert_int(PlacedArt.NORTH | PlacedArt.EAST | PlacedArt.SOUTH | PlacedArt.WEST).override_failure_message("four bits, one a way").is_equal(15)
	assert_array(PlacedArt.WAYS).is_equal([[Vector2i.UP, 1], [Vector2i.RIGHT, 2], [Vector2i.DOWN, 4], [Vector2i.LEFT, 8]])
	assert_bool(PlacedArt.has(&"hand") and not PlacedArt.has(&"sword")).is_true()
