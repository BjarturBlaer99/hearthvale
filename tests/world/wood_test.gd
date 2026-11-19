extends GdUnitTestSuite
## Wood (crafting, phase 2b): fallen branches and old stumps in the North Fields, the Old Wood
## and the South Field. The sword cuts them: a branch in one blow for one wood, a stump in
## three for two. They lie off the paths and clear of the crowns, stand in their cells until
## cut, and are back the next morning, not on the next visit.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Each area: where its branches and its stumps lie.
const WOOD: Dictionary = {
	&"north_fields": {&"branch": [Vector2i(23, 15), Vector2i(36, 3), Vector2i(14, 25), Vector2i(17, 7)], &"stump": [Vector2i(3, 17), Vector2i(31, 24)]},
	&"old_wood": {&"branch": [Vector2i(22, 7), Vector2i(15, 7), Vector2i(26, 9)], &"stump": [Vector2i(30, 5)]},
	&"south_field": {&"branch": [Vector2i(24, 10), Vector2i(7, 3), Vector2i(17, 19)], &"stump": [Vector2i(3, 21), Vector2i(36, 17)]},
}

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.add_item(&"wooden_sword")
	GameState.set_time(GameState.day_clock().in_day("12:00"))
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_branch_and_a_stump_are_data_and_wood_is_a_material() -> void:
	var branch: Dictionary = DataRegistry.get_breakable(&"branch")
	var stump: Dictionary = DataRegistry.get_breakable(&"stump")
	for kind: Dictionary in [branch, stump]:
		assert_array(kind["breaks_on"]).override_failure_message("the sword cuts it: no axe").contains(["sword"])
		assert_str(str(kind["returns"])).is_equal("daily")
		assert_bool(Breakable.FRAMES.has(StringName(str(kind["frames"]["whole"])))).is_true()
		for roll: float in [0.0, 0.5, 0.999]:
			assert_str(str(DropTable.roll(kind["drops"], roll).get("item", ""))).override_failure_message("it always gives wood").is_equal("wood")
	assert_int(int(branch.get("hits", 1))).is_equal(1)
	assert_int(int(stump["hits"])).is_equal(3)
	assert_int(int(DropTable.roll(branch["drops"], 0.5)["count"])).is_equal(1)
	assert_int(int(DropTable.roll(stump["drops"], 0.5)["count"])).is_equal(2)
	var wood: Dictionary = DataRegistry.get_item(&"wood")
	assert_str(str(wood["type"])).is_equal("material")
	assert_int(int(wood["max_stack"])).is_equal(50)
	assert_that(ItemIcons.name_for(&"wood")).is_equal(&"wood")
	GameState.add_item(&"wood")
	assert_bool(GameState.eat(&"wood")).override_failure_message("not to be eaten").is_false()
	# Grass and pots are as they were: one blow, and back on every visit.
	for old: StringName in [&"grass", &"pot"]:
		assert_bool(DataRegistry.get_breakable(old).has("returns") or DataRegistry.get_breakable(old).has("hits")).override_failure_message(String(old)).is_false()
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_ten_branches_and_five_stumps_lie_off_the_paths_and_clear_of_the_crowns() -> void:
	var counts: Dictionary = {&"branch": 0, &"stump": 0}
	for area_id: StringName in WOOD:
		var area: AreaController = _load(area_id)
		var found: Dictionary = {&"branch": [], &"stump": []}
		for child: Node in area.interactables.get_children():
			if child is Breakable and found.has((child as Breakable).breakable_id):
				(found[(child as Breakable).breakable_id] as Array).append((child as Breakable).cell())
		for kind: StringName in found:
			var cells: Array = found[kind]
			cells.sort()
			var want: Array = (WOOD[area_id][kind] as Array).duplicate()
			want.sort()
			assert_array(cells).override_failure_message("%s: its %ss" % [area_id, kind]).is_equal(want)
			counts[kind] += cells.size()
			for cell: Vector2i in cells:
				var where: String = "%s %s at %s" % [area_id, kind, cell]
				assert_int((area.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(cell).y).override_failure_message(where + " lies on grass, not a path").is_equal(GreyboxTiles.ROW_GROUND)
				assert_bool(area.grid.is_solid(cell)).override_failure_message(where + " lies on open ground").is_false()
				assert_bool(area.terrain.is_occupied(cell)).override_failure_message(where + " stands in its cell").is_true()
				assert_array(area.scenery.hiding(Vector2(cell * 16) + Vector2(8, 8))).override_failure_message(where + " is clear of the trees").is_empty()
				assert_object(area.exit_at(cell)).override_failure_message(where + " is on no way out").is_null()
				# He can come at it from every side.
				for side: Vector2i in SIDES:
					assert_bool(area.grid.is_solid(cell + side) or area.terrain.is_occupied(cell + side)).override_failure_message(where + ": open on its %s side" % side).is_false()
	assert_dict(counts).is_equal({&"branch": 10, &"stump": 5})


func test_the_sword_cuts_a_branch_in_one_blow_and_a_stump_in_three() -> void:
	var fields: AreaController = _load(&"north_fields")
	var branch: Breakable = _wood_at(fields, Vector2i(23, 15))
	_swing_at(fields, branch)
	assert_bool(branch.broken).is_true()
	assert_bool(fields.terrain.is_occupied(branch.cell())).override_failure_message("its cell is free").is_false()
	assert_object(branch.dropped).is_not_null()
	assert_that((branch.dropped as ItemDrop).item_id).is_equal(&"wood")
	assert_int((branch.dropped as ItemDrop).count).is_equal(1)
	assert_array(_heard).contains([&"cut"])
	var stump: Breakable = _wood_at(fields, Vector2i(3, 17))
	assert_int(stump.hits_left).is_equal(3)
	for blow: int in 2:
		_heard.clear()
		_swing_at(fields, stump)
		assert_array(_heard).override_failure_message("blow %d is heard, though it fells nothing" % (blow + 1)).contains([&"cut"])
		assert_bool(stump.broken).override_failure_message("blow %d doesn't fell it" % (blow + 1)).is_false()
		assert_int(stump.hits_left).is_equal(2 - blow)
		assert_object(stump.dropped).is_null()
		assert_bool(fields.terrain.is_occupied(stump.cell())).is_true()
	_swing_at(fields, stump)
	assert_bool(stump.broken).is_true()
	assert_int((stump.dropped as ItemDrop).count).is_equal(2)
	# Walked onto, the wood is his.
	for cut: Breakable in [branch, stump]:
		fields.player.motor.place(cut.cell())
		fields.player.sync_from_motor()
		fields.collect_pickups()
	assert_int(GameState.item_count(&"wood")).is_equal(3)
	assert_bool(GameState.has_found(&"wood")).is_true()
	assert_float(GameState.energy).override_failure_message("four swings of the sword, no more").is_equal(98.0)


func test_cut_wood_is_gone_for_the_day_and_back_the_next_morning() -> void:
	var fields: AreaController = _load(&"north_fields")
	var branch: Breakable = _wood_at(fields, Vector2i(23, 15))
	_swing_at(fields, branch)
	assert_that(GameState.get_flag(&"cut/north_fields/23,15", 0)).is_equal(1)
	# Leaving and coming back the same day: still cut, nothing in the way, nothing to cut.
	fields = _load(&"north_fields")
	branch = _wood_at(fields, Vector2i(23, 15))
	assert_bool(branch.broken).override_failure_message("not back on the next visit").is_true()
	assert_bool(fields.terrain.is_occupied(Vector2i(23, 15))).is_false()
	assert_bool(branch.hurt_box.enabled).is_false()
	assert_bool(_wood_at(fields, Vector2i(36, 3)).broken).override_failure_message("the others are whole").is_false()
	# Tall grass in the same field is back at once, as it always was.
	var grass: Breakable = null
	for child: Node in fields.interactables.get_children():
		if child is Breakable and (child as Breakable).breakable_id == &"grass":
			grass = child
			break
	grass.smash()
	var grass_cell: Vector2i = grass.cell()
	fields = _load(&"north_fields")
	for child: Node in fields.interactables.get_children():
		if child is Breakable and (child as Breakable).cell() == grass_cell:
			assert_bool((child as Breakable).broken).override_failure_message("grass is back on every visit").is_false()
	# The next morning the branch lies there again.
	GameState.start_next_day()
	fields = _load(&"north_fields")
	branch = _wood_at(fields, Vector2i(23, 15))
	assert_bool(branch.broken).is_false()
	assert_bool(fields.terrain.is_occupied(Vector2i(23, 15))).is_true()
	assert_bool(branch.hurt_box.enabled).is_true()
	# The same cell in another area is another branch's.
	assert_that(branch.cut_flag()).is_equal(&"cut/north_fields/23,15")
	var other: Breakable = Breakable.new()
	other.breakable_id = &"branch"
	other.area_id = &"old_wood"
	other.position = Vector2(23, 15) * 16.0
	assert_that(other.cut_flag()).is_equal(&"cut/old_wood/23,15")
	other.free()


func test_breakables_that_cant_be_used_say_why() -> void:
	var registry: Node = auto_free((load("res://autoload/data_registry.gd") as GDScript).new())
	var errors: String = "; ".join(registry.load_all("res://tests/fixtures/bad_wood"))
	assert_str(errors).contains("breakable 'log' 'hits' must be a whole number of 1 or more.")
	assert_str(errors).contains("breakable 'log' 'returns' must be 'daily' or 'never' (left out, it is back on every visit).")


# --- Helpers -------------------------------------------------------------------------------

func _load(area_id: StringName) -> AreaController:
	_area = Steps.load_area(WorldPaths.scene_for(area_id), _area)
	return _area


func _wood_at(area: AreaController, cell: Vector2i) -> Breakable:
	for child: Node in area.interactables.get_children():
		if child is Breakable and (child as Breakable).cell() == cell:
			return child
	fail("nothing to cut at %s" % cell)
	return null


## Stands the hero below `what`, facing it, swings the sword once and lets the blow land.
func _swing_at(area: AreaController, what: Breakable) -> void:
	area.player.motor.place(what.cell() + Vector2i.DOWN)
	area.player.face(Vector2.UP)
	area.player.sync_from_motor()
	assert_bool(area.player.swing()).is_true()
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()


func _on_sound(id: StringName) -> void:
	_heard.append(id)
