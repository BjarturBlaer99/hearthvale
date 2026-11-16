extends GdUnitTestSuite
## A reward too big for the pack (the fix round of 2026-11-16): what fits goes in, and the rest
## is laid at the hero's feet with a line at the top of the screen. It lies there until he picks
## it up, through leaving the area and through a save, and is picked up whole when there is
## room. Uses the slime bounty (40 coins and 10 arrows; a quiver holds 30) and a slot of its own.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const TEST_SLOT: int = 965
const QUIVER: int = 30
const SPOT: Vector2i = Vector2i(20, 22)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(600.0)
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_given_what_fits_nothing_is_owed() -> void:
	var owed: Array[bool] = []
	var listen: Callable = func() -> void: owed.append(true)
	EventBus.items_owed.connect(listen)
	assert_int(GameState.give_item(&"arrow", 10)).is_equal(10)
	EventBus.items_owed.disconnect(listen)
	assert_int(GameState.item_count(&"arrow")).is_equal(10)
	assert_array(owed).is_empty()
	assert_array(LeftItems.owed(GameState.flags)).is_empty()


func test_given_more_than_fits_the_rest_is_owed_and_none_is_lost() -> void:
	GameState.add_item(&"arrow", QUIVER - 4)
	var owed: Array[bool] = []
	var listen: Callable = func() -> void: owed.append(true)
	EventBus.items_owed.connect(listen)
	assert_int(GameState.give_item(&"arrow", 10)).override_failure_message("four went in").is_equal(4)
	EventBus.items_owed.disconnect(listen)
	assert_int(GameState.item_count(&"arrow")).is_equal(QUIVER)
	assert_array(owed).is_equal([true])
	assert_int(int(LeftItems.owed(GameState.flags)[0]["count"])).is_equal(6)
	# A second gift that doesn't fit is owed on top of the first.
	GameState.give_item(&"arrow", 3)
	assert_int(int(LeftItems.owed(GameState.flags)[0]["count"])).is_equal(9)


func test_the_give_item_effect_is_what_gives_so_a_present_is_kept_too() -> void:
	GameState.add_item(&"bomb", 10)
	assert_bool(EffectApplier.new(GameState).apply({"type": "give_item", "item": "bomb", "count": 3})).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(10)
	assert_int(int(LeftItems.owed(GameState.flags)[0]["count"])).is_equal(3)


func test_a_reward_that_doesnt_fit_is_laid_at_his_feet_and_he_is_told() -> void:
	var village: AreaController = _village_with_a_full_quiver(4)
	_finish_the_bounty()
	assert_int(GameState.item_count(&"coin")).override_failure_message("the coins fit").is_equal(40)
	assert_int(GameState.item_count(&"arrow")).override_failure_message("four of the ten arrows fit").is_equal(QUIVER)
	var left: LeftItem = _left(village)
	assert_object(left).override_failure_message("the other six lie at his feet").is_not_null()
	assert_that(left.cell()).is_equal(SPOT)
	assert_that(left.item_id).is_equal(&"arrow")
	assert_int(left.count).is_equal(6)
	assert_bool(left.covers(SPOT)).is_true()
	assert_array(Array(village.hud.notice_lines())).contains([LeftItems.words("Arrows", 6)])
	assert_array(LeftItems.owed(GameState.flags)).override_failure_message("laid down, no longer owed").is_empty()


func test_what_lies_there_is_still_there_after_the_area_is_left_and_after_a_save() -> void:
	_village_with_a_full_quiver(4)
	_finish_the_bounty()
	# Another area: nothing of it there.
	GameState.go_to(&"south_field", &"north_road")
	var field: AreaController = _load(FIELD)
	assert_object(_left(field)).is_null()
	# Saved, the game started over, and loaded: back in the village it lies where it was.
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	GameState.update_player(&"village", SPOT + Vector2i(2, 0))
	var village: AreaController = _load(VILLAGE)
	var left: LeftItem = _left(village)
	assert_object(left).is_not_null()
	assert_that(left.cell()).is_equal(SPOT)
	assert_int(left.count).is_equal(6)
	assert_array(Array(village.hud.notice_lines())).override_failure_message("told once, as it was laid down").not_contains([LeftItems.words("Arrows", 6)])


func test_it_is_picked_up_whole_once_there_is_room_and_then_it_is_gone_for_good() -> void:
	var village: AreaController = _village_with_a_full_quiver(4)
	_finish_the_bounty()
	var left: LeftItem = _left(village)
	# Standing on it with a full quiver: it stays, and he is told why.
	assert_bool(village.interact()).is_true()
	assert_str(village.hud.message_text()).is_equal(AreaController.NO_ROOM_FOR_WORDS % "Arrows")
	assert_int(left.count).is_equal(6)
	assert_bool(left.taken()).is_false()
	# Room for five of the six is not room: it is taken whole or not at all.
	GameState.add_item(&"arrow", -5)
	assert_bool(left.take()).is_false()
	GameState.add_item(&"arrow", -1)
	assert_bool(village.interact()).is_true()
	assert_int(GameState.item_count(&"arrow")).is_equal(QUIVER)
	assert_bool(left.taken()).is_true()
	assert_bool(left.covers(SPOT)).is_false()
	assert_bool(left.take()).override_failure_message("not twice").is_false()
	assert_array(LeftItems.lying_in(GameState.flags, &"village")).is_empty()
	# And it is not there on the next visit.
	GameState.update_player(&"village", SPOT)
	village = _load(VILLAGE)
	assert_object(_left(village)).is_null()


func test_two_things_laid_in_the_same_place_add_up() -> void:
	var village: AreaController = _village_with_a_full_quiver(0)
	GameState.give_item(&"arrow", 3)
	GameState.give_item(&"arrow", 2)
	var left: LeftItem = _left(village)
	assert_int(left.count).is_equal(5)
	var count: int = 0
	for child: Node in village.interactables.get_children():
		if child is LeftItem:
			count += 1
	assert_int(count).override_failure_message("one pile, not two").is_equal(1)


func test_what_was_given_outside_an_area_is_laid_where_he_arrives() -> void:
	GameState.add_item(&"arrow", QUIVER)
	GameState.give_item(&"arrow", 7)
	assert_int(int(LeftItems.owed(GameState.flags)[0]["count"])).is_equal(7)
	GameState.update_player(&"village", SPOT)
	var village: AreaController = _load(VILLAGE)
	var left: LeftItem = _left(village)
	assert_object(left).is_not_null()
	assert_that(left.cell()).is_equal(SPOT)
	assert_int(left.count).is_equal(7)
	assert_array(LeftItems.owed(GameState.flags)).is_empty()
	assert_array(Array(village.hud.notice_lines())).contains([LeftItems.words("Arrows", 7)])


func test_what_lies_at_his_feet_does_not_come_between_him_and_who_gave_it() -> void:
	GameState.add_item(&"arrow", QUIVER)
	GameState.update_player(&"village", SPOT)
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "GuardRolf")
	var before_rolf: Vector2i = village.player.motor.cell
	GameState.give_item(&"arrow", 4)
	assert_object(village.pickup_under_player()).is_not_null()
	assert_object(village.pickup_to_take()).override_failure_message("no room, and Rolf is before him").is_null()
	assert_bool(village.interact()).is_true()
	assert_bool(village.is_talking()).override_failure_message("he talks to Rolf").is_true()
	assert_int(GameState.item_count(&"arrow")).is_equal(QUIVER)
	# With room it is picked up first, as any item underfoot is.
	GameState.add_item(&"arrow", -4)
	GameState.update_player(&"village", before_rolf)
	village = _load(VILLAGE)
	Steps.stand_before(village, "GuardRolf")
	assert_object(village.pickup_to_take()).is_not_null()
	assert_bool(village.interact()).is_true()
	assert_bool(village.is_talking()).is_false()
	assert_int(GameState.item_count(&"arrow")).is_equal(QUIVER)
	# And away from anyone, what he has no room for is still his to be told about.
	GameState.give_item(&"arrow", 2)
	village.player.face(Vector2.DOWN)
	assert_object(village.pickup_to_take()).is_not_null()
	assert_bool(village.interact()).is_true()
	assert_str(village.hud.message_text()).is_equal(AreaController.NO_ROOM_FOR_WORDS % "Arrows")


## The village with the hero on SPOT, the slime bounty waiting to be reported, and a quiver with
## room for `room` more arrows.
func _village_with_a_full_quiver(room: int) -> AreaController:
	GameState.add_item(&"arrow", QUIVER - room)
	Quests.runner.start(&"slime_bounty")
	GameState.set_flag(&"south_field_slimes_beaten", true)
	GameState.update_player(&"village", SPOT)
	return _load(VILLAGE)


func _finish_the_bounty() -> void:
	GameState.set_flag(&"reported_slimes", true)
	assert_that(Quests.runner.status(&"slime_bounty")).is_equal(QuestState.COMPLETE)


## The LeftItem in `area` that still lies there, or null.
func _left(area: AreaController) -> LeftItem:
	for child: Node in area.interactables.get_children():
		if child is LeftItem and not (child as LeftItem).taken():
			return child as LeftItem
	return null


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
