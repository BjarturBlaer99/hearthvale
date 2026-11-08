extends GdUnitTestSuite
## CombatRules: the sword's arc reaches only in front of the hero, circles touch, knockback
## points away from the blow, and the strongest held sword is chosen from its data.

const REACH: float = CombatRules.SWORD_REACH
const ARC: float = deg_to_rad(CombatRules.SWORD_ARC_DEGREES)

const ITEMS: Array = [
	{"id": "wooden_sword", "type": "weapon_melee", "stats": {"damage": 2}},
	{"id": "iron_sword", "type": "weapon_melee", "stats": {"damage": 4, "knockback": 50, "cooldown": 0.25}},
	{"id": "bow", "type": "weapon_ranged", "stats": {"damage": 9}},
]


func test_the_sword_arc_reaches_only_in_front() -> void:
	assert_bool(_arc(Vector2(0, -16))).override_failure_message("straight ahead").is_true()
	assert_bool(_arc(Vector2(10, -14))).override_failure_message("ahead and a little aside").is_true()
	assert_bool(_arc(Vector2(0, 16))).override_failure_message("behind").is_false()
	assert_bool(_arc(Vector2(16, 0))).override_failure_message("beside").is_false()
	assert_bool(_arc(Vector2(0, -27))).override_failure_message("out of reach").is_false()


func test_circles_touch_when_closer_than_their_radii() -> void:
	assert_bool(CombatRules.circles_touch(Vector2.ZERO, 5.0, Vector2(10, 0), 6.0)).is_true()
	assert_bool(CombatRules.circles_touch(Vector2.ZERO, 5.0, Vector2(11, 0), 6.0)).is_false()


func test_knockback_points_away_from_the_blow() -> void:
	assert_that(CombatRules.push(Vector2.ZERO, Vector2(3, 4), 10.0)).is_equal(Vector2(6, 8))
	assert_that(CombatRules.push(Vector2(5, 5), Vector2(5, 5), 8.0, Vector2.LEFT)).override_failure_message("same spot: the fallback").is_equal(Vector2(-8, 0))


func test_the_strongest_held_sword_is_chosen() -> void:
	assert_dict(CombatRules.best_melee_weapon([], ITEMS)).is_empty()
	assert_str(_best([{"id": &"wooden_sword", "count": 1}])).is_equal("wooden_sword")
	assert_str(_best([{"id": &"wooden_sword", "count": 1}, {"id": &"iron_sword", "count": 1}])).is_equal("iron_sword")
	assert_str(_best([{"id": &"iron_sword", "count": 0}, {"id": &"wooden_sword", "count": 1}])).is_equal("wooden_sword")
	assert_dict(CombatRules.best_melee_weapon([{"id": &"bow", "count": 1}], ITEMS)).override_failure_message("a bow isn't a sword").is_empty()


func test_weapon_stats_fill_in_what_the_data_leaves_out() -> void:
	var stats: Dictionary = CombatRules.weapon_stats(ITEMS[0])
	assert_int(stats["damage"]).is_equal(2)
	assert_float(stats["knockback"]).is_equal(0.0)
	assert_float(stats["cooldown"]).is_equal(0.3)
	assert_float(CombatRules.weapon_stats(ITEMS[1])["cooldown"]).is_equal(0.25)


func _arc(target: Vector2) -> bool:
	return CombatRules.in_arc(Vector2.ZERO, Vector2.UP, ARC, REACH, target, 6.0)


func _best(stacks: Array) -> String:
	return str(CombatRules.best_melee_weapon(stacks, ITEMS).get("id", ""))
