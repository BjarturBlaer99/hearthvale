extends GdUnitTestSuite
## The herd in GameState (the Homestead, phase 4, step 4a): Oda's three animals on her list;
## buying is refused without a building for it or with it full, and a bigger one holds eight; an
## animal bought is in its building; a pasture on the land itself (a fenced pen by the coop's
## door, a gate in the fence, a gap, a floor); a morning feeds the herd from the pasture, then
## the silo's hay, else nobody; a building with animals can't be pulled down; and the herd goes
## through a save, still version 6, while a save from phase 3 loads with none.

const TEST_SLOT: int = 940
const OLD_SAVES: String = "res://tests/fixtures/saves"
## Written by the game at the end of phase 3 (21199f6): a coop, a barn and a silo standing,
## twelve hay in the silo, a row of fences, and no animals.
const V6_PHASE_3: String = "v6_buildings_before_animals.json"
const LAND: StringName = &"homestead"
## The coop stands with its corner here, its doorstep at (16, 13), on the open land west of the
## farmhouse; the pen round its door is (13..18, 13..15), fenced on (12..19, 12..16).
const COOP_AT: Vector2i = Vector2i(14, 10)
const DOORSTEP: Vector2i = Vector2i(16, 13)
const PEN: Rect2i = Rect2i(13, 13, 6, 3)
const BARN_AT: Vector2i = Vector2i(32, 9)
const SILO_AT: Vector2i = Vector2i(10, 4)


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_odas_stall_sells_the_three_animals() -> void:
	var wares: Array[Dictionary] = Shop.wares(DataRegistry.get_shop(&"oda"), DataRegistry.entries(&"crops"))
	assert_array(wares).is_equal([
		{"item": "", "animal": "chicken", "count": 1, "price": 60},
		{"item": "", "animal": "sheep", "count": 1, "price": 180},
		{"item": "", "animal": "cow", "count": 1, "price": 240},
	])
	assert_str(str(DataRegistry.get_shop(&"oda")["name"])).is_equal("Oda's Stall")
	for row: Array in [[&"chicken", &"coop", &"egg", 1, 4], [&"sheep", &"barn", &"wool", 3, 6], [&"cow", &"barn", &"milk", 2, 8]]:
		var kind: Dictionary = DataRegistry.get_animal(row[0])
		assert_that(Herd.lives_in(kind)).is_equal(row[1])
		assert_that(Herd.gives(kind)).is_equal(row[2])
		assert_int(Herd.every(kind)).is_equal(row[3])
		assert_int(Herd.grazes(kind)).is_equal(row[4])
	# Her conversation opens the list.
	var asks: Array = (DataRegistry.get_dialogue(&"farmer_oda")["nodes"]["hello"]["options"] as Array).filter(
		func(option: Dictionary) -> bool: return option["text"] == "Have you any animals to sell?")
	assert_int(asks.size()).is_equal(1)
	assert_array(asks[0]["effects"]).is_equal([{"type": "shop", "shop": "oda", "mode": "buy"}])


func test_buying_is_refused_without_a_building_or_with_it_full_and_a_bought_one_is_in_it() -> void:
	GameState.add_item(GameState.COIN, 999)
	var hen: Dictionary = {"item": "", "animal": "chicken", "count": 1, "price": 60}
	assert_str(GameState.buy(hen)).is_equal("A chicken needs a Coop on your farm.")
	assert_int(GameState.item_count(GameState.COIN)).override_failure_message("nothing paid").is_equal(999)
	# A site is no coop yet.
	_set_down(&"coop", COOP_AT)
	assert_str(GameState.buy(hen)).is_equal("A chicken needs a Coop on your farm.")
	GameState.start_next_day()
	assert_str(GameState.buy(hen)).is_empty()
	assert_int(GameState.item_count(GameState.COIN)).is_equal(939)
	assert_array(GameState.animals_in(&"coop")).is_equal([0])
	assert_dict(GameState.homestead().animal(0)).is_equal(Herd.new_animal(&"chicken"))
	for i: int in 3:
		assert_str(GameState.buy(hen)).is_empty()
	assert_str(GameState.buy(hen)).is_equal("Your Coop has no room for another.")
	assert_int(GameState.animals_in(&"coop").size()).is_equal(4)
	# A sheep wants the barn, not the coop.
	assert_str(GameState.buy({"item": "", "animal": "sheep", "count": 1, "price": 180})).is_equal("A sheep needs a Barn on your farm.")
	# The Big Coop holds eight, from the morning after it is bought.
	assert_bool(GameState.homestead().upgrade(&"coop", GameState.day)).is_true()
	assert_str(GameState.buy(hen)).override_failure_message("not finished until the morning").is_equal("Your Coop has no room for another.")
	GameState.start_next_day()
	for i: int in 4:
		assert_str(GameState.buy(hen)).is_empty()
	assert_str(GameState.buy(hen)).is_equal("Your Big Coop has no room for another.")
	assert_int(GameState.animals_in(&"coop").size()).is_equal(8)
	# Not enough coins.
	_build(&"barn", BARN_AT)
	GameState.add_item(GameState.COIN, -GameState.item_count(GameState.COIN))
	GameState.add_item(GameState.COIN, 239)
	assert_str(GameState.buy({"item": "", "animal": "cow", "count": 1, "price": 240})).is_equal(Shop.NO_COINS)
	assert_array(GameState.animals_in(&"barn")).is_empty()
	# Sheep and cows share the barn.
	GameState.add_item(GameState.COIN, 999)
	assert_str(GameState.buy({"item": "", "animal": "cow", "count": 1, "price": 240})).is_empty()
	assert_str(GameState.buy({"item": "", "animal": "sheep", "count": 1, "price": 180})).is_empty()
	assert_array(GameState.animals_in(&"barn")).is_equal([8, 9])


func test_a_fenced_pen_by_the_door_is_a_pasture() -> void:
	_build(&"coop", COOP_AT)
	assert_bool(GameState.has_pasture(&"coop")).override_failure_message("open land runs on to the road").is_false()
	assert_bool(GameState.pasture_of(&"coop")["fenced"]).is_false()
	_fence_pen()
	var pasture: Dictionary = GameState.pasture_of(&"coop")
	assert_bool(pasture["fenced"]).is_true()
	assert_int(int(pasture["grass"])).override_failure_message("six by three, all grass").is_equal(18)
	assert_bool((pasture["cells"] as Array).has(DOORSTEP)).is_true()
	assert_bool(GameState.has_pasture(&"coop")).is_true()
	# A gate counts as fence.
	GameState.homestead().take_up(Vector2i(15, 16), Placement.STANDING)
	assert_bool(GameState.homestead().set_down(Vector2i(15, 16), Placement.STANDING, &"gate")).is_true()
	assert_bool(GameState.has_pasture(&"coop")).override_failure_message("a gate keeps them in").is_true()
	# A floor is not grass.
	GameState.homestead().set_down(Vector2i(13, 15), Placement.LYING, &"wooden_flooring")
	GameState.homestead().set_down(Vector2i(14, 15), Placement.LYING, &"stone_path")
	assert_int(int(GameState.pasture_of(&"coop")["grass"])).is_equal(16)
	# A gap in the fence is no pasture.
	GameState.homestead().take_up(Vector2i(19, 14), Placement.STANDING)
	assert_bool(GameState.pasture_of(&"coop")["fenced"]).is_false()
	assert_bool(GameState.has_pasture(&"coop")).is_false()
	# A building that doesn't stand has none: neither one never set down, nor a site.
	assert_dict(GameState.pasture_of(&"barn")).is_empty()
	_set_down(&"barn", BARN_AT)
	assert_bool(GameState.homestead().has_building(&"barn")).is_true()
	assert_dict(GameState.pasture_of(&"barn")).override_failure_message("a site has no pasture yet").is_empty()


func test_two_doors_on_one_fenced_ground_share_it() -> void:
	# A coop and a barn side by side on the land west of the farmhouse, their doors on one pen:
	# (3..15, 10..12), fenced on (2..16, 9..13) but where the two buildings stand.
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", Vector2i(4, 7))
	_build(&"barn", Vector2i(9, 6))
	var pen: Rect2i = Rect2i(3, 10, 13, 3)
	_fence(pen)
	GameState.buy_animal(&"chicken", 60)
	GameState.buy_animal(&"cow", 240)
	var shared: Array[Dictionary] = GameState.pastures()
	assert_int(shared.size()).override_failure_message("one pasture for both doors").is_equal(1)
	assert_array(shared[0]["buildings"]).contains_exactly_in_any_order(["barn", "coop"])
	assert_int(int(shared[0]["grass"])).is_equal(39)
	assert_dict(GameState.pasture_of(&"coop")).is_equal(GameState.pasture_of(&"barn"))
	# Both graze, and the hay is kept. Paved to ten cells of grass, the hen (bought first) takes
	# four, and the six left are too few for the cow, who eats a hay.
	_build(&"silo", SILO_AT)
	GameState.homestead().hay = 5
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).is_equal(5)
	for x: int in range(3, 16):
		for y: int in range(10, 13):
			if (y - 10) * 13 + (x - 3) >= 10:
				GameState.homestead().set_down(Vector2i(x, y), Placement.LYING, &"stone_path")
	assert_int(int(GameState.pastures()[0]["grass"])).is_equal(10)
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).override_failure_message("the hen grazed four, and six were too few for the cow").is_equal(4)


func test_a_morning_feeds_from_the_pasture_then_the_hay_then_nobody() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	_build(&"silo", SILO_AT)
	GameState.homestead().hay = 3
	for i: int in 4:
		GameState.buy_animal(&"chicken", 60)
	# No pasture: three eat hay, the fourth goes hungry.
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).is_equal(0)
	assert_array(GameState.homestead().animals().map(func(hen: Dictionary) -> bool: return hen["hungry"])).is_equal([false, false, false, true])
	# A pen of eighteen cells feeds four hens (four cells each) and the hay is kept.
	_fence_pen()
	GameState.homestead().hay = 3
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).override_failure_message("pasture first").is_equal(3)
	assert_array(GameState.homestead().animals().map(func(hen: Dictionary) -> bool: return hen["hungry"])).is_equal([false, false, false, false])
	# Paved over to nine cells of grass, two graze and two eat hay.
	for x: int in range(13, 19):
		GameState.homestead().set_down(Vector2i(x, 15), Placement.LYING, &"stone_path")
	for x: int in range(13, 16):
		GameState.homestead().set_down(Vector2i(x, 14), Placement.LYING, &"stone_path")
	assert_int(int(GameState.pasture_of(&"coop")["grass"])).is_equal(9)
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).is_equal(1)
	assert_array(GameState.pastures()).is_equal([{"buildings": ["coop"], "grass": 9, "cells": GameState.pasture_of(&"coop")["cells"]}])


func test_the_herd_comes_nearer_its_products_and_petting_takes_them() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	_fence_pen()
	GameState.buy_animal(&"chicken", 60)
	assert_str(GameState.pet_animal(0)).is_equal("You pet the chicken.")
	assert_bool(GameState.homestead().animal(0)["petted"]).is_true()
	GameState.start_next_day()
	assert_bool(GameState.homestead().animal(0)["ready"]).override_failure_message("fed and petted: an egg each morning").is_true()
	assert_str(GameState.pet_animal(0)).is_equal("You pet the chicken. Taken: Egg.")
	assert_int(GameState.item_count(&"egg")).is_equal(1)
	assert_bool(GameState.homestead().animal(0)["ready"]).is_false()
	# Taking the egg was petting her: another tomorrow. A second hen, never petted, lays every
	# second morning.
	GameState.buy_animal(&"chicken", 60)
	GameState.start_next_day()
	assert_bool(GameState.homestead().animal(0)["ready"]).is_true()
	assert_bool(GameState.homestead().animal(1)["ready"]).override_failure_message("fed only: half a morning").is_false()
	GameState.start_next_day()
	assert_bool(GameState.homestead().animal(1)["ready"]).is_true()
	# A full pack leaves the egg waiting, and he is told.
	GameState.add_item(&"egg", 29)
	assert_str(GameState.pet_animal(0)).is_equal("You pet the chicken. Your pack has no room for the Egg: it waits.")
	assert_int(GameState.item_count(&"egg")).is_equal(30)
	assert_bool(GameState.homestead().animal(0)["ready"]).is_true()
	assert_str(GameState.pet_animal(5)).override_failure_message("no such animal").is_empty()


func test_a_building_with_animals_cant_be_pulled_down() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	assert_str(GameState.why_not_demolish(&"coop")).is_empty()
	GameState.buy_animal(&"chicken", 60)
	assert_str(GameState.why_not_demolish(&"coop")).is_equal("The Coop still has animals in it. Only an empty building can be pulled down.")
	assert_array(GameState.demolish(LAND, &"coop")).is_empty()
	assert_bool(GameState.is_built(&"coop")).is_true()
	# Moved, the hen goes with it: she lives in the coop wherever it stands.
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(&"coop"), Vector2i(32, 10)):
		GameState.clear_debris(LAND, cell)
	assert_bool(GameState.move_building(LAND, &"coop", Vector2i(32, 10))).is_true()
	assert_array(GameState.animals_in(&"coop")).is_equal([0])


func test_the_herd_goes_through_a_save_still_version_6() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	_build(&"barn", BARN_AT)
	GameState.buy_animal(&"chicken", 60)
	GameState.buy_animal(&"cow", 240)
	GameState.pet_animal(1)
	GameState.update_player(LAND, Vector2i(30, 13))
	SaveSystem.current_slot = TEST_SLOT
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(6)
	assert_array(on_disk["homestead"]["animals"]).is_equal(JSON.parse_string('[' +
		'{"kind": "chicken", "petted": false, "progress": 0, "ready": false, "hungry": false},' +
		'{"kind": "cow", "petted": true, "progress": 0, "ready": false, "hungry": false}]'))
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_array(GameState.animals_in(&"barn")).is_equal([1])


func test_a_save_from_phase_3_loads_with_its_buildings_and_no_animals() -> void:
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(V6_PHASE_3)))
	assert_int(int(old["version"])).is_equal(6)
	assert_bool((old["homestead"] as Dictionary).has("animals")).override_failure_message("phase 3 knew no animals").is_false()
	GameState.from_dict(old)
	assert_array(GameState.homestead().building_ids()).is_equal([&"barn", &"coop", &"silo"])
	assert_bool(GameState.is_built(&"coop")).is_true()
	assert_int(GameState.homestead().hay).is_equal(12)
	assert_int(GameState.homestead().animal_count()).is_equal(0)
	assert_that(GameState.homestead().standing_at(Vector2i(15, 14))).is_equal(&"fence")
	# Saved again, nothing of phase 4 is written that isn't there.
	var again: Dictionary = GameState.to_dict()
	assert_bool((again["homestead"] as Dictionary).has("animals")).is_false()
	assert_dict(JSON.parse_string(JSON.stringify(again["homestead"]))).is_equal(old["homestead"])
	# A hen bought in that game finds the old row of fences no pasture: it runs on to the road.
	GameState.add_item(GameState.COIN, 60)
	assert_str(GameState.buy_animal(&"chicken", 60)).is_empty()
	assert_bool(GameState.has_pasture(&"coop")).is_false()


func test_the_land_is_read_from_its_scene() -> void:
	var land: LandMap = GameState.land_map()
	assert_that(land.size).is_equal(Vector2i(40, 30))
	assert_that(land.field).is_equal(Rect2i(22, 17, 12, 6))
	assert_int(land.debris_count()).override_failure_message("the overgrowth of a new game, and not the meadow's tall grass").is_equal(145)
	assert_bool(land.is_road(Vector2i(28, 12))).override_failure_message("the farmhouse's doorstep is the path's end").is_true()
	assert_bool(land.is_road(Vector2i(39, 14))).override_failure_message("the way out").is_true()
	assert_bool(land.is_road(Vector2i(28, 11))).override_failure_message("the farmhouse's door is a way out too").is_true()
	assert_bool(land.is_solid(Vector2i(28, 9))).override_failure_message("the farmhouse").is_true()
	assert_bool(land.is_solid(Vector2i(5, 22))).override_failure_message("the pond").is_true()
	assert_bool(land.is_solid(Vector2i(0, 0))).override_failure_message("the woods").is_true()
	assert_that(GameState.pasture_kind(Vector2i(25, 18))).is_equal(Pasture.BARE)
	assert_that(GameState.pasture_kind(Vector2i(20, 14))).is_equal(Pasture.OPEN)
	assert_that(GameState.pasture_kind(Vector2i(-1, 3))).is_equal(Pasture.OPEN)
	assert_that(GameState.pasture_kind(Vector2i(36, 5))).override_failure_message("weeds stand there").is_equal(Pasture.WALL)
	GameState.clear_debris(LAND, Vector2i(36, 5))
	assert_that(GameState.pasture_kind(Vector2i(36, 5))).is_equal(Pasture.GRASS)


# --- Helpers -------------------------------------------------------------------------------

func _set_down(id: StringName, at: Vector2i) -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), at):
		GameState.clear_debris(LAND, cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(LAND, at, kit)).override_failure_message("%s at %s" % [id, at]).is_true()


## Sets building `id` down with its corner at `at` and lets a morning come.
func _build(id: StringName, at: Vector2i) -> void:
	_set_down(id, at)
	GameState.start_next_day()


## Clears `pen` and the ring round it, and fences the ring but where a building stands.
func _fence(pen: Rect2i) -> void:
	var ring: Rect2i = pen.grow(1)
	for y: int in range(ring.position.y, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			var cell: Vector2i = Vector2i(x, y)
			GameState.clear_debris(LAND, cell)
			if not pen.has_point(cell) and GameState.building_covering(LAND, cell) == &"":
				GameState.homestead().set_down(cell, Placement.STANDING, &"fence")


## Clears the pen round the coop's door and fences it.
func _fence_pen() -> void:
	var ring: Rect2i = PEN.grow(1)
	for y: int in range(ring.position.y - 1, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			GameState.clear_debris(LAND, Vector2i(x, y))
	for x: int in range(ring.position.x, ring.end.x):
		for y: int in range(ring.position.y, ring.end.y):
			var cell: Vector2i = Vector2i(x, y)
			if PEN.has_point(cell) or GameState.building_covering(LAND, cell) != &"":
				continue
			GameState.homestead().set_down(cell, Placement.STANDING, &"fence")
