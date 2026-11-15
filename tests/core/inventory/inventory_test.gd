extends GdUnitTestSuite
## Inventory rules: how many of an item fit, which items go on the item button, and what each
## one uses up.

const BOW: Dictionary = {"id": "bow", "type": "weapon_ranged", "stats": {"ammo": "arrow"}}
const ARROW: Dictionary = {"id": "arrow", "type": "ammo", "stackable": true, "max_stack": 30}
const BOMB: Dictionary = {"id": "bomb", "type": "bomb", "stackable": true, "max_stack": 10}
const SWORD: Dictionary = {"id": "wooden_sword", "type": "weapon_melee"}


func test_capacity_is_the_max_stack_or_one() -> void:
	assert_int(Inventory.capacity(ARROW)).is_equal(30)
	assert_int(Inventory.capacity(SWORD)).override_failure_message("not stackable: one").is_equal(1)
	assert_int(Inventory.capacity({})).override_failure_message("no data: no limit").is_equal(Inventory.UNLIMITED)
	assert_int(Inventory.room_for(25, ARROW)).is_equal(5)
	assert_int(Inventory.room_for(30, ARROW)).is_equal(0)
	assert_int(Inventory.room_for(1, SWORD)).is_equal(0)


func test_only_what_fits_whole_fits() -> void:
	assert_bool(Inventory.fits(25, ARROW, 5)).is_true()
	assert_bool(Inventory.fits(25, ARROW, 6)).override_failure_message("five of six fit: that is not fitting").is_false()
	assert_bool(Inventory.fits(30, ARROW, 1)).is_false()
	assert_bool(Inventory.fits(30, ARROW, 0)).override_failure_message("nothing always fits").is_true()
	assert_bool(Inventory.fits(0, SWORD, 1)).is_true()
	assert_bool(Inventory.fits(1, SWORD, 1)).is_false()
	assert_bool(Inventory.fits(5000, {}, 5000)).override_failure_message("no data: no limit").is_true()


func test_only_the_bow_and_bombs_go_on_the_item_button() -> void:
	assert_bool(Inventory.is_equippable(BOW)).is_true()
	assert_bool(Inventory.is_equippable(BOMB)).is_true()
	assert_bool(Inventory.is_equippable(SWORD)).is_false()
	assert_bool(Inventory.is_equippable(ARROW)).is_false()


func test_what_each_item_uses_up() -> void:
	assert_str(Inventory.ammo_for(BOW)).is_equal("arrow")
	assert_str(Inventory.ammo_for(BOMB)).override_failure_message("bombs use themselves").is_equal("bomb")
	assert_str(Inventory.ammo_for(SWORD)).is_empty()


func test_the_equippable_items_held_in_pickup_order() -> void:
	var items: Array = [SWORD, BOW, ARROW, BOMB]
	var held: Array = [{"id": &"bomb", "count": 2}, {"id": &"wooden_sword", "count": 1}, {"id": &"bow", "count": 1}]
	var ids: Array = Inventory.equippable_held(held, items).map(func(item: Dictionary) -> String: return str(item["id"]))
	assert_array(ids).override_failure_message("bombs were picked up first").is_equal(["bomb", "bow"])
	held[0]["count"] = 0
	ids = Inventory.equippable_held(held, items).map(func(item: Dictionary) -> String: return str(item["id"]))
	assert_array(ids).override_failure_message("none left: not listed").is_equal(["bow"])


func test_a_lantern_is_carried_not_put_on_the_item_button_and_lights_the_dark() -> void:
	var lantern: Dictionary = {"id": "lantern", "type": "lantern", "stats": {"radius": 56}}
	var big: Dictionary = {"id": "great_lantern", "type": "lantern", "stats": {"radius": 80}}
	var items: Array = [BOW, ARROW, lantern, big]
	assert_bool(Inventory.is_equippable(lantern)).is_false()
	assert_float(Inventory.light_radius([], items, 20.0)).override_failure_message("no lantern: the hero's own glow").is_equal(20.0)
	assert_float(Inventory.light_radius([{"id": "bow", "count": 1}], items, 20.0)).is_equal(20.0)
	assert_float(Inventory.light_radius([{"id": "lantern", "count": 1}], items, 20.0)).is_equal(56.0)
	assert_float(Inventory.light_radius([{"id": "lantern", "count": 0}], items, 20.0)).override_failure_message("none left: none held").is_equal(20.0)
	assert_float(Inventory.light_radius([{"id": "lantern", "count": 1}, {"id": "great_lantern", "count": 1}], items, 20.0)).override_failure_message("the widest counts").is_equal(80.0)
	var held: Array[Dictionary] = Inventory.held_of_type([{"id": "arrow", "count": 5}, {"id": "lantern", "count": 1}], items, "lantern")
	assert_int(held.size()).is_equal(1)
	assert_str(str(held[0]["id"])).is_equal("lantern")
