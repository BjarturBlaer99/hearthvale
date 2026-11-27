extends GdUnitTestSuite
## The axe in play (icons-axe-bar plan, step A2): it lies in the farmhouse for a new game and
## an old save alike; it cuts branches, stumps and logs at the cell he faces, a better axe in
## fewer blows, and nothing else; the sword only knocks on wood and says why once a visit; a
## bomb still breaks it; the two better axes are made at the workbench as the hoe's are.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const OLD_SAVES: String = "res://tests/fixtures/saves"
const TEST_SLOT: int = 952
const FRAME: float = 1.0 / 60.0
## Where the axe lies in the farmhouse: the open floor cell west of the doorway, in the row of
## the first seeds, the hoe and the can.
const AXE_CELL: Vector2i = Vector2i(4, 7)
## The farmhouse's things that were there before the axe, and their cells: none moves.
const ROOM: Dictionary = {
	"Hearth": Vector2i(5, 1), "Doormat": Vector2i(5, 8), "Bed": Vector2i(1, 3), "Hoe": Vector2i(7, 7),
	"WateringCan": Vector2i(8, 7), "TurnipSeeds": Vector2i(6, 7), "Workbench": Vector2i(9, 3),
	"Furnace": Vector2i(6, 2), "Chest": Vector2i(2, 2), "Lamp": Vector2i(4, 2), "Rug": Vector2i(2, 4),
	"Blanket": Vector2i(1, 3),
}
## The North Fields' wood: two stumps and a branch, each open below.
const STUMP: Vector2i = Vector2i(3, 17)
const OTHER_STUMP: Vector2i = Vector2i(31, 24)
const BRANCH: Vector2i = Vector2i(23, 15)
## The homestead's wood that stands alone: a log and a stump.
const LOG: Vector2i = Vector2i(7, 4)
const FARM_STUMP: Vector2i = Vector2i(24, 2)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.add_item(&"wooden_sword")
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


# --- Where it is had ---------------------------------------------------------------------

func test_the_axe_lies_in_the_farmhouse_on_open_floor_and_nothing_moved() -> void:
	var home: AreaController = _load(HOME)
	var axe: ItemPickup = home.interactables.get_node(^"Axe")
	assert_that(axe.item_id).is_equal(&"axe")
	assert_int(axe.count).is_equal(1)
	assert_that(axe.cell()).is_equal(AXE_CELL)
	assert_bool(axe.taken()).override_failure_message("a new game finds it").is_false()
	assert_bool(home.grid.is_solid(AXE_CELL)).override_failure_message("it lies on the floor").is_false()
	assert_bool(home.terrain.is_occupied(AXE_CELL)).is_false()
	for child: Node in home.interactables.get_children():
		if child != axe and child.has_method(&"covers"):
			assert_bool(child.call(&"covers", AXE_CELL)).override_failure_message("%s shares its cell" % child.name).is_false()
	for node_name: String in ROOM:
		var node: Node2D = home.interactables.get_node(NodePath(node_name))
		assert_that(PlayerMotor.cell_of(node.position + Vector2(0.5, 0.5))).override_failure_message(node_name + " stays where it was").is_equal(ROOM[node_name])
	# Taken, it is his and gone from the floor, on every visit.
	home.player.motor.place(AXE_CELL)
	home.player.sync_from_motor()
	assert_bool(home.interact()).is_true()
	assert_int(GameState.item_count(&"axe")).is_equal(1)
	assert_bool(GameState.get_flag(&"took_axe") == true).is_true()
	assert_str(home.hud.message_text()).is_equal("You pick up the Axe.")
	home = _load(HOME)
	assert_bool((home.interactables.get_node(^"Axe") as ItemPickup).taken()).is_true()
	# It is not sold: Tilda's list is as it was.
	var shop: Dictionary = DataRegistry.get_shop(&"tilda")
	for ware: Dictionary in shop["sells"]:
		assert_array([&"axe", &"copper_axe", &"iron_axe"]).not_contains([StringName(str(ware.get("item", "")))])


func test_an_old_save_finds_the_axe_at_home() -> void:
	for file: String in ["v5_in_the_old_cottage.json", "v6_a_yard_on_the_farm.json", "v6_buildings_before_animals.json"]:
		GameState.new_game()
		_write(TEST_SLOT, JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(file))))
		assert_int(SaveSystem.load_from_slot(TEST_SLOT)).override_failure_message(file).is_equal(OK)
		assert_int(GameState.SAVE_VERSION).is_equal(6)
		assert_int(GameState.item_count(&"axe")).override_failure_message(file + ": he had none").is_equal(0)
		var home: AreaController = _load(HOME)
		var axe: ItemPickup = home.interactables.get_node(^"Axe")
		assert_bool(axe.taken()).override_failure_message(file + ": it lies at home").is_false()
		home.player.motor.place(AXE_CELL)
		home.player.sync_from_motor()
		assert_bool(home.interact()).override_failure_message(file).is_true()
		assert_int(GameState.item_count(&"axe")).override_failure_message(file + ": and is his").is_equal(1)


func test_the_axe_goes_on_the_bar_and_into_his_hand() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"axe")
	GameState.equip(&"hoe")
	var ids: Array[StringName] = []
	for entry: Dictionary in GameState.hand_entries():
		ids.append(StringName(str(entry.get("id", ""))))
	assert_array(ids).contains([&"axe"])
	assert_bool(GameState.take_in_hand(ids.find(&"axe"))).is_true()
	assert_that(GameState.equipped).is_equal(&"axe")


# --- What it cuts ------------------------------------------------------------------------

func test_the_axe_cuts_a_stump_in_three_blows_and_the_better_axes_in_two_and_one() -> void:
	var fields: AreaController = _load(FIELDS)
	var plain: Breakable = _wood_at(fields, STUMP)
	for blow: int in 3:
		assert_bool(plain.broken).override_failure_message("the plain axe: blow %d" % (blow + 1)).is_false()
		_chop_at(fields, plain, &"axe")
	assert_bool(plain.broken).is_true()
	assert_int((plain.dropped as ItemDrop).count).is_equal(2)
	assert_bool((plain.dropped as ItemDrop).visible).override_failure_message("shown at the blow").is_true()
	var copper: Breakable = _wood_at(fields, OTHER_STUMP)
	_chop_at(fields, copper, &"copper_axe")
	assert_bool(copper.broken).is_false()
	assert_int(copper.hits_left).override_failure_message("a copper blow counts for two").is_equal(1)
	_chop_at(fields, copper, &"copper_axe")
	assert_bool(copper.broken).override_failure_message("the copper axe: two blows").is_true()
	assert_int((copper.dropped as ItemDrop).count).override_failure_message("the same wood").is_equal(2)
	# The next morning, the iron axe fells one in a blow.
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	fields = _load(FIELDS)
	var iron: Breakable = _wood_at(fields, STUMP)
	assert_bool(iron.broken).is_false()
	var energy: float = GameState.energy
	_chop_at(fields, iron, &"iron_axe")
	assert_bool(iron.broken).override_failure_message("the iron axe: one blow").is_true()
	assert_int((iron.dropped as ItemDrop).count).is_equal(2)
	assert_float(GameState.energy).override_failure_message("a stroke costs half a point, paid once").is_equal_approx(energy - 0.5, 0.0001)
	assert_array(_heard).contains([&"cut"])


func test_a_stroke_costs_half_a_point_and_shows_at_the_blow() -> void:
	GameState.add_item(&"axe")
	GameState.equip(&"axe")
	var fields: AreaController = _load(FIELDS)
	var stump: Breakable = _wood_at(fields, STUMP)
	_face(fields, stump.cell())
	assert_bool(fields.use_item()).is_true()
	assert_float(GameState.energy).is_equal(99.5)
	assert_int(stump.hits_left).override_failure_message("struck at once").is_equal(2)
	assert_array(_heard).override_failure_message("heard at the blow, not before").not_contains([&"cut"])
	assert_bool(fields.use_item()).override_failure_message("one stroke at a time").is_false()
	Steps.to_the_blow(fields)
	assert_array(_heard).contains([&"cut"])
	assert_bool(stump.is_flashing()).override_failure_message("a blow that doesn't fell it shows").is_true()
	assert_bool(fields.player.held_tool().visible).override_failure_message("the axe is in his hands").is_true()
	assert_int(fields.player.held_tool().frame_index).override_failure_message("come down at the blow").is_equal(HeldTools.frame_of(&"axe", "up", ToolStroke.STRIKE))
	_finish(fields)
	assert_float(GameState.energy).override_failure_message("paid once a stroke").is_equal(99.5)
	# The last blow: it is down at once, drawn whole and its wood hidden until the blow.
	_chop_at(fields, stump, &"axe")
	_face(fields, stump.cell())
	_heard.clear()
	assert_bool(fields.use_item()).is_true()
	assert_bool(stump.broken).is_true()
	assert_bool(fields.terrain.is_occupied(stump.cell())).is_false()
	assert_bool((stump.dropped as ItemDrop).visible).override_failure_message("its wood waits for the blow").is_false()
	assert_bool(stump.looks_whole()).override_failure_message("drawn whole while the axe is up").is_true()
	Steps.to_the_blow(fields)
	assert_bool(stump.looks_whole()).is_false()
	assert_bool((stump.dropped as ItemDrop).visible).is_true()
	assert_array(_heard).contains([&"cut"])


func test_the_axe_cuts_nothing_but_wood_and_says_so() -> void:
	GameState.add_item(&"axe")
	GameState.equip(&"axe")
	var farm: AreaController = _load(FARM)
	# Open ground, weeds, a bush and a rock: no stroke, no energy, and why.
	for cell: Vector2i in [Vector2i(33, 11), Vector2i(36, 5), Vector2i(7, 17), Vector2i(3, 4)]:
		_heard.clear()
		_face(farm, cell)
		assert_bool(farm.use_item()).override_failure_message("nothing to cut at %s" % cell).is_false()
		assert_str(farm.hud.message_text()).is_equal(ToolUse.CHOP_NOTHING)
		assert_array(_heard).contains([&"nope"])
		assert_float(GameState.energy).is_equal(100.0)
		if farm.debris_at(cell) != null:
			assert_bool(farm.debris_at(cell).get(&"broken")).is_false()
	# Tall grass and a pot in the countryside: the sword's still.
	var fields: AreaController = _load(FIELDS)
	var grass: Breakable = _first(fields, &"grass")
	_face(fields, grass.cell())
	assert_bool(fields.use_item()).is_false()
	assert_bool(grass.broken).is_false()
	# A left click with the axe in hand chops what he faces, and anywhere else swings the sword.
	var stump: Breakable = _wood_at(fields, STUMP)
	_face(fields, stump.cell())
	assert_bool(fields.faces_work(DataRegistry.get_item(&"axe"))).is_true()
	assert_bool(fields.use_hand()).is_true()
	assert_int(stump.hits_left).is_equal(2)
	_finish(fields)
	_face(fields, Vector2i(8, 10))
	assert_bool(fields.faces_work(DataRegistry.get_item(&"axe"))).is_false()
	assert_bool(fields.use_hand()).override_failure_message("the click is the sword's").is_true()
	assert_float(GameState.energy).override_failure_message("a stroke and a swing").is_equal(99.0)


func test_the_axe_clears_a_log_and_a_stump_of_the_land_for_good() -> void:
	var farm: AreaController = _load(FARM)
	var log: Breakable = farm.debris_at(LOG) as Breakable
	assert_that(log.breakable_id).is_equal(&"log")
	for blow: int in 3:
		assert_bool(GameState.homestead().is_cleared(LOG)).is_false()
		_chop_at(farm, log, &"axe")
	assert_bool(log.broken).is_true()
	assert_bool(GameState.homestead().is_cleared(LOG)).override_failure_message("cleared for good").is_true()
	assert_int((log.dropped as ItemDrop).count).is_equal(3)
	var stump: Breakable = farm.debris_at(FARM_STUMP) as Breakable
	_chop_at(farm, stump, &"iron_axe")
	assert_bool(stump.broken).override_failure_message("the iron axe: one blow").is_true()
	assert_int(int(GameState.skill_points.get(Skills.FARMING, 0)) + int(GameState.skill_points.get(Skills.MINING, 0)) + int(GameState.skill_points.get(Skills.COMBAT, 0))) \
		.override_failure_message("no skill rises (Q8)").is_equal(0)
	# Never back: not on the next visit, nor the next morning.
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	farm = _load(FARM)
	for cell: Vector2i in [LOG, FARM_STUMP]:
		assert_object(farm.debris_at(cell)).override_failure_message("%s stays clear" % cell).is_null()
		assert_bool(farm.terrain.is_occupied(cell)).is_false()


# --- The sword and the bomb --------------------------------------------------------------

func test_the_sword_knocks_on_wood_and_says_why_once_a_visit() -> void:
	var fields: AreaController = _load(FIELDS)
	var stump: Breakable = _wood_at(fields, STUMP)
	_swing_at(fields, stump)
	assert_int(stump.hits_left).override_failure_message("the sword doesn't cut wood").is_equal(3)
	assert_bool(stump.broken).is_false()
	assert_array(_heard).contains([Breakable.KNOCK_SOUND])
	assert_array(_heard).not_contains([&"cut"])
	assert_str(fields.hud.message_text()).is_equal(AreaController.WANTS_AXE_WORDS)
	fields.hud.show_message("Something else.")
	_swing_at(fields, stump)
	assert_str(fields.hud.message_text()).override_failure_message("told once a visit").is_equal("Something else.")
	assert_bool(stump.broken).is_false()
	# The next visit, he is told again; and a branch is wood as well.
	fields = _load(FIELDS)
	var branch: Breakable = _wood_at(fields, BRANCH)
	_swing_at(fields, branch)
	assert_bool(branch.broken).is_false()
	assert_str(fields.hud.message_text()).is_equal(AreaController.WANTS_AXE_WORDS)
	# Grass is still the sword's, and says nothing of an axe.
	var grass: Breakable = _first(fields, &"grass")
	fields.hud.show_message("Grass.")
	_swing_at(fields, grass)
	assert_bool(grass.broken).is_true()
	assert_bool(grass.wants_axe(&"sword")).is_false()
	assert_bool(branch.wants_axe(&"sword")).is_true()
	assert_bool(branch.wants_axe(&"bomb")).override_failure_message("only the sword knocks").is_false()
	# Something that both the sword and the axe cut is no knock for the sword.
	var both: Breakable = auto_free(Breakable.new())
	both.data = {"breaks_on": ["sword", "axe"]}
	assert_bool(both.wants_axe(&"sword")).is_false()
	# On the land a log stands the sword as well.
	var farm: AreaController = _load(FARM)
	var log: Breakable = farm.debris_at(LOG) as Breakable
	_swing_at(farm, log)
	assert_int(log.hits_left).is_equal(3)
	assert_bool(GameState.homestead().is_cleared(LOG)).is_false()
	assert_str(farm.hud.message_text()).is_equal(AreaController.WANTS_AXE_WORDS)


func test_a_bomb_still_breaks_wood() -> void:
	GameState.add_item(&"bomb", 1)
	var fields: AreaController = _load(FIELDS)
	var branch: Breakable = _wood_at(fields, BRANCH)
	_bomb(fields, BRANCH + Vector2i.DOWN)
	assert_bool(branch.broken).override_failure_message("a blast cuts a branch").is_true()
	assert_that((branch.dropped as ItemDrop).item_id).is_equal(&"wood")


# --- The recipes -------------------------------------------------------------------------

func test_the_copper_and_iron_axes_are_made_as_the_hoes_are() -> void:
	var make: Callable = func() -> Array[String]:
		var ids: Array[String] = []
		for recipe: Dictionary in Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_MAKE):
			ids.append(str(recipe["id"]))
		return ids
	assert_array(make.call()).not_contains(["copper_axe", "iron_axe"])
	GameState.add_item(&"copper_bar", 2)
	assert_array(make.call()).override_failure_message("once a copper bar is found").contains(["copper_axe"])
	assert_array(make.call()).not_contains(["iron_axe"])
	GameState.add_item(&"iron_bar", 2)
	assert_array(make.call()).contains(["copper_axe", "iron_axe"])
	# Everything bar cloth and the blanket: thirteen and the two axes.
	GameState.add_item(&"copper_ore")
	GameState.add_item(&"wood")
	GameState.add_item(&"coal")
	GameState.add_item(&"crystal")
	GameState.skill_points[Skills.FARMING] = 10
	GameState.skill_points[Skills.MINING] = 25
	assert_int((make.call() as Array).size()).is_equal(15)
	# The copper axe takes the axe and two copper bars; the iron axe the copper axe and two iron bars.
	assert_str(GameState.craft(&"copper_axe")).override_failure_message("no axe yet").is_not_empty()
	GameState.add_item(&"axe")
	assert_str(GameState.craft(&"copper_axe")).is_equal("")
	assert_int(GameState.item_count(&"axe")).is_equal(0)
	assert_int(GameState.item_count(&"copper_bar")).is_equal(0)
	assert_int(GameState.item_count(&"copper_axe")).is_equal(1)
	assert_str(GameState.craft(&"iron_axe")).is_equal("")
	assert_int(GameState.item_count(&"copper_axe")).is_equal(0)
	assert_int(GameState.item_count(&"iron_bar")).is_equal(0)
	assert_int(GameState.item_count(&"iron_axe")).is_equal(1)
	# Laid out as the hoe's recipes are.
	for pair: Array in [[&"copper_axe", &"copper_hoe", "axe"], [&"iron_axe", &"iron_hoe", "copper_axe"]]:
		var axe: Dictionary = DataRegistry.get_crafting(pair[0])
		var hoe: Dictionary = DataRegistry.get_crafting(pair[1])
		assert_dict(axe["unlock"]).is_equal(hoe["unlock"])
		assert_str(str(axe["needs"][0]["item"])).is_equal(pair[2])
		assert_dict(axe["needs"][1]).is_equal(hoe["needs"][1])
		assert_str(Crafting.tab_of(axe)).is_equal(Crafting.TAB_MAKE)


# --- Helpers -----------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _wood_at(area: AreaController, cell: Vector2i) -> Breakable:
	for child: Node in area.interactables.get_children():
		if child is Breakable and (child as Breakable).cell() == cell:
			return child
	fail("no wood at %s" % cell)
	return null


func _first(area: AreaController, kind: StringName) -> Breakable:
	for child: Node in area.interactables.get_children():
		if child is Breakable and (child as Breakable).breakable_id == kind and not (child as Breakable).broken:
			return child
	fail("no %s" % kind)
	return null


## Stands the hero below `cell`, facing up at it.
func _face(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)
	area.player.sync_from_motor()


## Lets a stroke finish.
func _finish(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()


## Strikes `what` once with `axe` from the item button, from below, and lets the stroke finish.
func _chop_at(area: AreaController, what: Breakable, axe: StringName) -> void:
	if GameState.item_count(axe) <= 0:
		GameState.add_item(axe)
	GameState.equip(axe)
	_face(area, what.cell())
	assert_bool(area.use_item()).override_failure_message("a stroke of the %s" % axe).is_true()
	_finish(area)


## Swings the sword once at `what` from below and lets the blow land.
func _swing_at(area: AreaController, what: Breakable) -> void:
	_face(area, what.cell())
	assert_bool(area.player.swing()).is_true()
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()


## Sets a bomb down at `cell`, steps well away, and lets it burn out.
func _bomb(area: AreaController, cell: Vector2i) -> void:
	GameState.equip(&"bomb")
	area.player.motor.place(cell)
	area.player.sync_from_motor()
	assert_bool(area.use_item()).is_true()
	var bomb: Bomb = area.last_projectile
	area.player.motor.place(cell + Vector2i(6, 0))
	area.player.sync_from_motor()
	for i: int in roundi(2.6 / FRAME):
		bomb.tick(FRAME)
		area.resolve_combat()
		if not is_instance_valid(bomb) or bomb.is_queued_for_deletion():
			break


func _on_sound(id: StringName) -> void:
	_heard.append(id)
