extends GdUnitTestSuite
## Doors (H1): walking into a house door takes the hero inside, in front of the doormat;
## walking out over the doormat brings them back out of the same door. Every exit in every
## area leads to a real entry point, and every villager and sign has a conversation.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const AREAS: Array[StringName] = [&"village", &"elder_house", &"weaver_house"]
## [house, the cell just outside its door]
const HOUSES: Array = [
	[&"elder_house", Vector2i(30, 15)],
	[&"weaver_house", Vector2i(16, 15)],
]

var _area: Node


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	GameState.clear()


func test_you_can_enter_two_houses_and_come_out_the_same_door() -> void:
	for house: Array in HOUSES:
		var house_id: StringName = house[0]
		var outside: Vector2i = house[1]
		GameState.new_game()
		GameState.update_player(&"village", outside)
		_area = Steps.load_area(VILLAGE, _area)
		var village: AreaController = _area
		assert_that(village.player.motor.cell).is_equal(outside)

		var path: String = Steps.walk_until_travel(village, Vector2.UP)
		assert_str(path).override_failure_message("walking into %s's door" % house_id).is_equal(WorldPaths.scene_for(house_id))
		assert_dict(GameState.player).is_equal({"area": String(house_id), "entry": "door"})

		_area = Steps.load_area(path, _area)
		var inside: AreaController = _area
		var doormat: AreaExit = inside.interactables.get_node(^"Doormat")
		assert_that(inside.player.motor.cell).is_equal(doormat.cell() + Vector2i.UP)
		assert_that(inside.player.facing_direction()).is_equal(Vector2i.UP)
		await get_tree().process_frame
		assert_that(str(GameState.player["area"])).is_equal(String(house_id))

		path = Steps.walk_until_travel(inside, Vector2.DOWN)
		assert_str(path).override_failure_message("walking out of %s" % house_id).is_equal(VILLAGE)
		_area = Steps.load_area(path, _area)
		var back: AreaController = _area
		assert_that(back.player.motor.cell).override_failure_message("out of %s's own door" % house_id).is_equal(outside)
		assert_that(back.player.facing_direction()).is_equal(Vector2i.DOWN)
		GameState.clear()


func test_a_house_smaller_than_the_screen_sits_in_the_middle_of_it() -> void:
	GameState.new_game()
	_area = Steps.load_area(WorldPaths.scene_for(&"elder_house"))
	var house: AreaController = _area
	var camera: Camera2D = house.player.get_node(^"Camera2D")
	var room: Vector2i = house.grid.size * GreyboxTiles.TILE_SIZE
	@warning_ignore("integer_division")
	assert_int((camera.limit_left + camera.limit_right) / 2).is_equal(room.x / 2)
	@warning_ignore("integer_division")
	assert_int((camera.limit_top + camera.limit_bottom) / 2).is_equal(room.y / 2)


func test_every_exit_leads_to_an_entry_point_and_every_talker_has_a_conversation() -> void:
	var exits: int = 0
	for area_id: StringName in AREAS:
		var scene: Node = auto_free((load(WorldPaths.scene_for(area_id)) as PackedScene).instantiate())
		var grid: HeightGrid = HeightGridBuilder.from_layer(scene.get_node(^"Height"))
		for child: Node in scene.get_node(^"Interactables").get_children():
			if child is Talkable:
				var talkable: Talkable = child
				assert_bool(DataRegistry.has_entry(&"dialogues", talkable.dialogue_id)) \
					.override_failure_message("%s/%s names dialogue '%s'" % [area_id, child.name, talkable.dialogue_id]).is_true()
				assert_bool(grid.is_solid(talkable.cell())).override_failure_message("%s/%s stands on open ground" % [area_id, child.name]).is_false()
			if not child is AreaExit:
				continue
			exits += 1
			var exit: AreaExit = child
			var where: String = "%s/%s -> %s:%s" % [area_id, exit.name, exit.target_area, exit.target_entry]
			assert_bool(grid.is_solid(exit.cell())).override_failure_message(where + " can be walked onto").is_false()
			var target_path: String = WorldPaths.scene_for(exit.target_area)
			assert_bool(ResourceLoader.exists(target_path)).override_failure_message(where + ": no such area").is_true()
			if not ResourceLoader.exists(target_path):
				continue
			var target: Node = auto_free((load(target_path) as PackedScene).instantiate())
			var marker: Node2D = target.get_node_or_null("Entries/%s" % exit.target_entry)
			assert_object(marker).override_failure_message(where + ": no such entry point").is_not_null()
			if marker == null:
				continue
			var entry_cell: Vector2i = PlayerMotor.cell_of(marker.position)
			var target_grid: HeightGrid = HeightGridBuilder.from_layer(target.get_node(^"Height"))
			assert_bool(target_grid.in_bounds(entry_cell) and not target_grid.is_solid(entry_cell)) \
				.override_failure_message(where + ": the entry point is on open ground").is_true()
			for other: Node in target.get_node(^"Interactables").get_children():
				if other is AreaExit:
					assert_bool((other as AreaExit).covers(entry_cell)).override_failure_message(where + ": arrives on another exit").is_false()
	assert_int(exits).override_failure_message("two doors in, two doormats out").is_equal(4)
