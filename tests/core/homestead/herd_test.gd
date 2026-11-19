extends GdUnitTestSuite
## The herd's rules (the Homestead, phase 4; the plan's D25 to D28), pure: each row of the
## morning's table (fed and petted, a whole morning; fed only, half; unfed, none and unhappy); a
## product that waits stops the next; pasture before hay before hunger, a pasture shared by two
## doors; a building full, and a bigger one holding eight; why an animal can't be bought; what
## Homestead keeps of the herd, through a save.

const HEN: Dictionary = {"id": "chicken", "name": "Chicken", "lives_in": "coop", "gives": "egg", "every": 1, "grazes": 4, "sound": "cluck"}
const SHEEP: Dictionary = {"id": "sheep", "name": "Sheep", "lives_in": "barn", "gives": "wool", "every": 3, "grazes": 6, "sound": "bleat"}
const COW: Dictionary = {"id": "cow", "name": "Cow", "lives_in": "barn", "gives": "milk", "every": 2, "grazes": 8, "sound": "low"}
const KINDS: Dictionary = {"chicken": HEN, "sheep": SHEEP, "cow": COW}
const COOP: Dictionary = {"id": "coop", "name": "Coop", "size": [4, 3], "animals": 4, "big": {"name": "Big Coop", "animals": 8}}
const BARN: Dictionary = {"id": "barn", "name": "Barn", "size": [6, 4], "animals": 4, "big": {"name": "Big Barn", "animals": 8}}


## Mornings until `kind` has a product ready, fed every morning, petted every day or never.
func _mornings_to_product(kind: Dictionary, petted: bool) -> int:
	var animal: Dictionary = Herd.new_animal(StringName(str(kind["id"])))
	for morning: int in range(1, 20):
		animal["petted"] = petted
		if Herd.morning(animal, kind, true):
			return morning
	return -1


func test_fed_and_petted_it_gives_at_full_pace_fed_only_at_half() -> void:
	# A hen lays each morning, a cow milks every second, a sheep is shorn every third (D27).
	assert_int(_mornings_to_product(HEN, true)).is_equal(1)
	assert_int(_mornings_to_product(COW, true)).is_equal(2)
	assert_int(_mornings_to_product(SHEEP, true)).is_equal(3)
	# Fed and not petted: half a morning nearer each morning.
	assert_int(_mornings_to_product(HEN, false)).is_equal(2)
	assert_int(_mornings_to_product(COW, false)).is_equal(4)
	assert_int(_mornings_to_product(SHEEP, false)).is_equal(6)


func test_each_row_of_the_mornings_table() -> void:
	# Fed, and petted yesterday: a full morning nearer.
	var cow: Dictionary = Herd.new_animal(&"cow")
	cow["petted"] = true
	assert_bool(Herd.morning(cow, COW, true)).is_false()
	assert_int(int(cow["progress"])).is_equal(Herd.FULL_STEP)
	assert_bool(cow["petted"]).override_failure_message("today he hasn't petted it yet").is_false()
	assert_bool(cow["hungry"]).is_false()
	# Fed, not petted: half a morning nearer.
	assert_bool(Herd.morning(cow, COW, true)).is_false()
	assert_int(int(cow["progress"])).is_equal(Herd.FULL_STEP + Herd.HALF_STEP)
	# Not fed: no nearer, and it looks unhappy until it is fed, even petted.
	cow["petted"] = true
	assert_bool(Herd.morning(cow, COW, false)).is_false()
	assert_int(int(cow["progress"])).is_equal(Herd.FULL_STEP + Herd.HALF_STEP)
	assert_bool(cow["hungry"]).is_true()
	assert_bool(cow["ready"]).is_false()
	# Fed again: no longer unhappy, and half a morning brings the pail.
	assert_bool(Herd.morning(cow, COW, true)).is_true()
	assert_bool(cow["hungry"]).is_false()
	assert_bool(cow["ready"]).is_true()
	assert_int(int(cow["progress"])).is_equal(0)


func test_a_product_that_waits_stops_the_next() -> void:
	var hen: Dictionary = Herd.new_animal(&"chicken")
	hen["petted"] = true
	assert_bool(Herd.morning(hen, HEN, true)).is_true()
	# The egg isn't taken: morning after morning, fed and petted, no second egg comes on.
	for i: int in 3:
		hen["petted"] = true
		assert_bool(Herd.morning(hen, HEN, true)).override_failure_message("a waiting egg stops the next").is_false()
		assert_bool(hen["ready"]).is_true()
		assert_int(int(hen["progress"])).is_equal(0)
	# Taken, the next comes the next morning.
	hen["ready"] = false
	hen["petted"] = true
	assert_bool(Herd.morning(hen, HEN, true)).is_true()


func test_pasture_first_then_hay_then_hunger() -> void:
	# Two hens and two sheep; the coop's pasture has grass for one hen and a little over, the
	# barn has none: one hen grazes, the other hen and the first sheep eat hay, the last sheep
	# goes hungry.
	var herd: Array = [Herd.new_animal(&"chicken"), Herd.new_animal(&"sheep"), Herd.new_animal(&"chicken"), Herd.new_animal(&"sheep")]
	var fed: Dictionary = Herd.feed(herd, KINDS, [{"buildings": ["coop"], "grass": 7}], 2)
	assert_array(fed["fed"]).is_equal([true, true, true, false])
	assert_int(int(fed["grazed"])).override_failure_message("seven cells feed one hen of four").is_equal(1)
	assert_int(int(fed["hay"])).is_equal(0)
	# With grass for both hens, the hay goes to the sheep.
	fed = Herd.feed(herd, KINDS, [{"buildings": ["coop"], "grass": 8}], 2)
	assert_array(fed["fed"]).is_equal([true, true, true, true])
	assert_int(int(fed["grazed"])).is_equal(2)
	assert_int(int(fed["hay"])).is_equal(0)
	# The barn's own pasture: the sheep graze and the hay is kept.
	fed = Herd.feed(herd, KINDS, [{"buildings": ["coop"], "grass": 8}, {"buildings": ["barn"], "grass": 12}], 5)
	assert_int(int(fed["grazed"])).is_equal(4)
	assert_int(int(fed["hay"])).override_failure_message("pasture is used first").is_equal(5)
	# No pasture and no hay: nobody is fed.
	fed = Herd.feed(herd, KINDS, [], 0)
	assert_array(fed["fed"]).is_equal([false, false, false, false])


func test_two_doors_on_one_pasture_share_its_grass() -> void:
	var herd: Array = [Herd.new_animal(&"cow"), Herd.new_animal(&"chicken"), Herd.new_animal(&"chicken")]
	# Twelve cells: the cow eats eight, a hen four, and the second hen has none left.
	var fed: Dictionary = Herd.feed(herd, KINDS, [{"buildings": ["barn", "coop"], "grass": 12}], 0)
	assert_array(fed["fed"]).is_equal([true, true, false])


func test_why_an_animal_cant_be_bought() -> void:
	assert_str(Herd.why_not_buy(HEN, COOP, false, false, 0, 100, 60)).is_equal("A chicken needs a Coop on your farm.")
	assert_str(Herd.why_not_buy(HEN, {}, false, false, 0, 100, 60)).override_failure_message("no such building").is_equal("A chicken needs a coop on your farm.")
	assert_str(Herd.why_not_buy(HEN, COOP, true, false, 3, 100, 60)).is_empty()
	assert_str(Herd.why_not_buy(HEN, COOP, true, false, 4, 100, 60)).is_equal("Your Coop has no room for another.")
	# A bigger one holds eight.
	assert_str(Herd.why_not_buy(HEN, COOP, true, true, 4, 100, 60)).is_empty()
	assert_str(Herd.why_not_buy(HEN, COOP, true, true, 7, 100, 60)).is_empty()
	assert_str(Herd.why_not_buy(HEN, COOP, true, true, 8, 100, 60)).is_equal("Your Big Coop has no room for another.")
	assert_str(Herd.why_not_buy(COW, BARN, true, false, 1, 239, 240)).is_equal(Shop.NO_COINS)
	assert_str(Herd.why_not_buy(COW, BARN, true, false, 1, 240, 240)).is_empty()


func test_what_is_wrong_with_a_kind_is_said() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return {"id": id} if id in ["egg", "wool", "milk"] else {}
	var building_of: Callable = func(id: String) -> Dictionary: return {"coop": COOP, "barn": BARN, "well": {"id": "well"}}.get(id, {})
	for kind: Dictionary in [HEN, SHEEP, COW]:
		assert_array(Herd.problems(kind, item_of, building_of)).override_failure_message(str(kind["id"])).is_empty()
	var bad: Dictionary = HEN.duplicate()
	bad["lives_in"] = "well"
	bad["gives"] = "feather"
	bad["every"] = 0
	var said: PackedStringArray = Herd.problems(bad, item_of, building_of)
	assert_int(said.size()).is_equal(3)
	var missing: Dictionary = HEN.duplicate()
	missing.erase("grazes")
	assert_array(Herd.problems(missing, item_of, building_of)).is_equal(PackedStringArray(["an animal needs 'grazes'."]))


func test_homestead_keeps_the_herd_through_a_save() -> void:
	var home: Homestead = Homestead.new()
	assert_dict(home.to_dict()).override_failure_message("no animals, nothing written").is_equal({"cleared": []})
	assert_int(home.add_animal(&"chicken")).is_equal(0)
	assert_int(home.add_animal(&"cow")).is_equal(1)
	assert_int(home.add_animal(&"")).is_equal(-1)
	home.animal(1)["ready"] = true
	home.animal(1)["progress"] = 1
	home.animal(0)["petted"] = true
	home.animal(0)["hungry"] = true
	var again: Homestead = Homestead.new()
	again.load_saved(JSON.parse_string(JSON.stringify(home.to_dict())))
	assert_int(again.animal_count()).is_equal(2)
	assert_dict(again.animal(0)).is_equal({"kind": "chicken", "petted": true, "progress": 0, "ready": false, "hungry": true})
	assert_dict(again.animal(1)).is_equal({"kind": "cow", "petted": false, "progress": 1, "ready": true, "hungry": false})
	assert_dict(again.animal(2)).is_empty()
	# A kind the game no longer has is left out; so is what isn't an animal at all.
	var saved: Dictionary = home.to_dict()
	(saved["animals"] as Array).append({"kind": "goat"})
	(saved["animals"] as Array).append("hen")
	again.load_saved(saved, Callable(), Callable(), func(kind: String) -> bool: return KINDS.has(kind))
	assert_int(again.animal_count()).is_equal(2)
