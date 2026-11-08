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


func test_starting_items_are_registered_in_id_order() -> void:
	_registry.load_all()
	assert_array(_registry.ids(&"items")).is_equal([&"coin", &"small_key", &"wooden_sword"])
	assert_str(_registry.get_item(&"wooden_sword").get("name", "")).is_equal("Wooden Sword")
	var found: Array = []
	for entry: Dictionary in _registry.entries(&"items"):
		found.append(entry["id"])
	assert_array(found).is_equal(["coin", "small_key", "wooden_sword"])


func test_missing_required_field_is_reported_and_not_loaded() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("missing_field"))
	_assert_reported(errors, "missing required field 'name'")
	assert_bool(_registry.has_entry(&"items", &"nameless")).is_false()


func test_duplicate_ids_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("duplicate"))
	_assert_reported(errors, "duplicate item id 'twin'")


func test_unresolved_references_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("bad_reference"))
	_assert_reported(errors, "unknown item id 'unobtainium'")
	_assert_reported(errors, "unknown stage 'nowhere'")


func test_villagers_and_signs_have_their_conversations() -> void:
	_registry.load_all()
	for id: StringName in [&"elder_bram", &"wenna_weaver", &"sign_welcome"]:
		assert_bool(_registry.has_entry(&"dialogues", id)).override_failure_message("dialogue '%s'" % id).is_true()


func test_enemies_are_registered() -> void:
	_registry.load_all()
	assert_array(Array(_registry.ids(&"enemies")).map(func(id: StringName) -> String: return String(id))).is_equal(["bat", "goblin_archer", "slime"])
	assert_str(str(_registry.get_enemy(&"slime").get("behaviour", ""))).is_equal("hopper")


func test_bad_enemies_are_reported() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("bad_enemy"))
	_assert_reported(errors, "unknown behaviour 'teleporter'")
	_assert_reported(errors, "unknown item id 'ruby'")
	_assert_reported(errors, "unknown type 'treasure'")
	_assert_reported(errors, "needs a 'weight' above 0")


func test_dialogue_speakers_must_be_a_map() -> void:
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("bad_speakers"))
	_assert_reported(errors, "'speakers' must be an object")


func test_unknown_data_folders_are_reported() -> void:
	# The old water network folder is no longer a kind of content.
	var errors: PackedStringArray = _registry.load_all(FIXTURES.path_join("old_water"))
	_assert_reported(errors, "unknown data directory")


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
