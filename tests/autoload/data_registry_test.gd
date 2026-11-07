extends GdUnitTestSuite
## DataRegistry: the shipped content is valid, and bad content is reported, not loaded.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")
const FIXTURES: String = "res://tests/fixtures"

var _registry: Node


func before_test() -> void:
	# A fresh, un-parented instance: _ready() never runs, so loading bad fixtures
	# only fills `errors` instead of stopping the run.
	_registry = auto_free(DataRegistryScript.new())


func test_project_data_loads_without_errors() -> void:
	var errors: PackedStringArray = _registry.load_all()
	assert_array(Array(errors)).override_failure_message("\n".join(errors)).is_empty()


func test_slice_content_is_registered() -> void:
	_registry.load_all()
	var expected: Dictionary = {
		&"districts": [&"greenterrace", &"spire_nine", &"st_aud"],
		&"basins": [&"old_reservoir"],
		&"nodes": [&"st_aud_pump", &"third_outlet"],
		&"interiors": [&"st_aud_ground_floor"],
		&"factions": [&"reclamation", &"summit_holds"],
		&"companions": [&"mara"],
		&"quests": [&"bitter_medicine"],
		&"dialogues": [&"greenterrace_elder"],
	}
	for collection: StringName in expected:
		assert_array(_registry.ids(collection)).is_equal(expected[collection])
	assert_str(_registry.get_item(&"fever_medicine").get("name", "")).is_equal("Fever Medicine Crate")


func test_district_levels_go_from_most_to_least_water() -> void:
	_registry.load_all()
	for district_id: StringName in _registry.ids(&"districts"):
		var previous: float = INF
		for level: Dictionary in _registry.get_district(district_id)["levels"]:
			var height: float = level["water_height"]
			var message: String = "%s/%s water_height %s does not decrease" % [district_id, level["id"], height]
			assert_bool(height < previous).override_failure_message(message).is_true()
			previous = height


func test_level_ids_keep_data_order() -> void:
	_registry.load_all()
	assert_array(Array(_registry.level_ids(&"st_aud"))).is_equal(["flooded", "waist", "drained"])


func test_missing_required_field_is_reported_and_not_loaded() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("missing_field"))
	_assert_reported(errors, "missing required field 'start_level'")
	assert_bool(_registry.has_entry(&"districts", &"no_start")).is_false()


func test_levels_that_do_not_decrease_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("rising_levels"))
	_assert_reported(errors, "does not decrease")


func test_unresolved_references_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("bad_reference"))
	_assert_reported(errors, "unknown item id 'unobtainium'")
	_assert_reported(errors, "unknown stage 'nowhere'")


func test_bad_water_numbers_and_ids_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("bad_water"))
	_assert_reported(errors, "water_volume_per_step must be a positive whole number")
	_assert_reported(errors, "outflows into itself")
	_assert_reported(errors, "start_stored 20 is more than its capacity 10")
	_assert_reported(errors, "is both a district and a basin")
	_assert_reported(errors, "targets its own district")


func test_entries_come_in_id_order() -> void:
	_registry.load_all()
	var found: Array = []
	for entry: Dictionary in _registry.entries(&"districts"):
		found.append(entry["id"])
	assert_array(found).is_equal(["greenterrace", "spire_nine", "st_aud"])


func test_missing_data_root_is_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("does_not_exist"))
	_assert_reported(errors, "data directory does not exist")


func _assert_reported(errors: PackedStringArray, fragment: String) -> void:
	var found: bool = false
	for message: String in errors:
		if message.contains(fragment):
			found = true
			break
	var message: String = "Expected an error containing \"%s\"; got:\n%s" % [fragment, "\n".join(errors)]
	assert_bool(found).override_failure_message(message).is_true()
