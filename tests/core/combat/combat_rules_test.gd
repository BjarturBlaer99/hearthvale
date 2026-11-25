extends GdUnitTestSuite
## CombatRules: the sword's arc reaches only in front of the hero, two cells straight ahead since
## the reach was lengthened (2026-11-25), and never through a wall; circles touch, knockback
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
	assert_bool(_arc(Vector2(0, -35))).override_failure_message("out of reach").is_false()


func test_the_reach_is_28_and_takes_in_the_cell_two_ahead() -> void:
	assert_float(CombatRules.SWORD_REACH).override_failure_message("the user's longer reach (2026-11-25; it was 20)").is_equal(28.0)
	assert_float(CombatRules.SWORD_ARC_DEGREES).override_failure_message("the arc's width is as it was").is_equal(120.0)
	# A target of radius 6 (a monster, a weed, a crystal) at the middle of a cell, from the middle of his.
	assert_bool(_arc(Vector2(0, -16))).override_failure_message("the next cell").is_true()
	assert_bool(_arc(Vector2(16, -16))).override_failure_message("the next cell aslant").is_true()
	assert_bool(_arc(Vector2(0, -32))).override_failure_message("two cells straight ahead: new").is_true()
	assert_bool(_arc(Vector2(16, -32))).override_failure_message("two ahead and one aside: still out").is_false()
	assert_bool(_arc(Vector2(0, -48))).override_failure_message("three cells ahead").is_false()
	assert_bool(_arc(Vector2(32, -16))).override_failure_message("two aside").is_false()


func test_a_blow_stops_at_a_wall_between() -> void:
	var walls: Dictionary = {Vector2i(0, 1): true}
	var blocks: Callable = func(cell: Vector2i) -> bool: return walls.has(cell)
	# From the middle of cell (0, 2) up to the middle of (0, 0), with the wall at (0, 1) between.
	assert_bool(CombatRules.clear_between(Vector2(8, 40), Vector2(8, 8), blocks)).override_failure_message("through the wall").is_false()
	assert_bool(CombatRules.clear_between(Vector2(24, 40), Vector2(24, 8), blocks)).override_failure_message("beside the wall").is_true()
	assert_bool(CombatRules.clear_between(Vector2(8, 24), Vector2(8, 8), func(_c: Vector2i) -> bool: return true)) \
			.override_failure_message("next to each other: no cell between, whatever the ends are").is_true()


func test_a_blow_aslant_passes_a_corner_but_not_the_seam_of_two_walls() -> void:
	# Hero in (0, 1), target in (1, 0) a little off its middle; (0, 0) is a wall the line grazes.
	var corner: Callable = func(cell: Vector2i) -> bool: return cell == Vector2i(0, 0)
	assert_bool(CombatRules.clear_between(Vector2(8, 24), Vector2(24, 6), corner)).override_failure_message("a corner grazed").is_true()
	# Hero in (0, 0), target in (1, 2), the wall row 1 whole: the line crosses from (0, 1) to (1, 1)
	# at the edge they share, near it all the way, as a graze of either alone would be.
	var row: Callable = func(cell: Vector2i) -> bool: return cell.y == 1
	assert_bool(CombatRules.clear_between(Vector2(8, 8), Vector2(24, 40), row)).override_failure_message("the seam of two walls").is_false()


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
