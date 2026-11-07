extends GdUnitTestSuite
## The real maps against M3: where the boat can sail at each water level (searched from each
## district's Mooring with BoatRules.floats), harbours that are dry at every level, and a sea
## where every port can be reached from every other port's exit.

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const DISTRICTS: Array[StringName] = [&"st_aud", &"spire_nine", &"greenterrace"]


func test_the_water_changes_where_the_boat_can_sail_in_st_aud() -> void:
	var map: Dictionary = _district(&"st_aud")
	var flooded: Dictionary = _sailable(map, 4)
	var waist: Dictionary = _sailable(map, 2)
	print("  St. Aud sailable cells: flooded %d, waist %d" % [flooded.size(), waist.size()])
	assert_bool(waist.is_empty()).is_false()
	assert_int(flooded.size()).is_greater(waist.size())
	for cell: Vector2i in waist:
		assert_bool(flooded.has(cell)).override_failure_message("%s sailable at waist but not flooded" % cell).is_true()
	# Rubble is open water when flooded but shallow at waist.
	assert_bool(flooded.has(Vector2i(13, 17))).is_true()
	assert_bool(waist.has(Vector2i(13, 17))).is_false()
	# Drained: no deep water anywhere, so the boat has to wait at sea.
	assert_bool(_sailable(map, 0).is_empty()).is_true()
	assert_that(BoatRules.nearest_deep_cell(map["terrain"], map["mooring"], 0)).is_equal(BoatRules.NO_CELL)


func test_the_water_changes_where_the_boat_can_sail_in_greenterrace() -> void:
	var map: Dictionary = _district(&"greenterrace")
	var flooded: Dictionary = _sailable(map, 3)
	print("  Greenterrace sailable cells: flooded %d, dry %d" % [flooded.size(), _sailable(map, 1).size()])
	assert_int(flooded.size()).is_greater(100)
	assert_bool(_sailable(map, 1).is_empty()).is_true()
	assert_that(BoatRules.nearest_deep_cell(map["terrain"], map["mooring"], 1)).is_equal(BoatRules.NO_CELL)


func test_spire_nine_always_has_water_for_the_boat() -> void:
	var map: Dictionary = _district(&"spire_nine")
	assert_int(_sailable(map, 4).size()).is_greater(100)


func test_harbours_and_docks_stay_dry_at_every_level() -> void:
	for district_id: StringName in DISTRICTS:
		var map: Dictionary = _district(district_id)
		var terrain: TerrainQuery = map["terrain"]
		var levels: Array = DataRegistry.get_district(district_id)["levels"]
		for level: Dictionary in levels:
			var kind: TerrainQuery.CellKind = terrain.cell_kind(map["harbour"], int(level["water_height"]))
			assert_that(kind).override_failure_message("%s harbour at %s" % [district_id, level["id"]]).is_equal(TerrainQuery.CellKind.DRY)
		# The boat at its mooring can always be boarded from a dock cell beside it.
		var dock_beside_mooring: bool = false
		for side: Vector2i in SIDES:
			var dry_at_every_level: bool = true
			for level: Dictionary in levels:
				if terrain.cell_kind(map["mooring"] + side, int(level["water_height"])) != TerrainQuery.CellKind.DRY:
					dry_at_every_level = false
			if dry_at_every_level:
				dock_beside_mooring = true
		assert_bool(dock_beside_mooring).override_failure_message("%s: no dock beside the mooring" % district_id).is_true()


func test_every_sea_port_can_be_reached_from_every_other() -> void:
	var scene: Node = auto_free((load(WorldPaths.SEA_SCENE) as PackedScene).instantiate())
	var terrain: TerrainQuery = TerrainQuery.new(HeightGridBuilder.from_layer(scene.get_node("Height")))
	var ports: Array[SeaPort] = []
	for child: Node in scene.get_node("Ports").get_children():
		ports.append(child as SeaPort)
	assert_int(ports.size()).is_equal(3)
	var water: int = SeaController.WATER_HEIGHT
	for port: SeaPort in ports:
		assert_bool(BoatRules.floats(terrain, port.exit_cell, water)).override_failure_message("%s exit floats" % port.district_id).is_true()
		assert_bool(port.covers(port.exit_cell)).override_failure_message("%s exit outside its port" % port.district_id).is_false()
		var reachable: Dictionary = _flood(terrain, port.exit_cell, water)
		for other: SeaPort in ports:
			var reaches: bool = false
			for y: int in other.footprint.y:
				for x: int in other.footprint.x:
					if reachable.has(other.origin_cell() + Vector2i(x, y)):
						reaches = true
			assert_bool(reaches).override_failure_message("from %s to %s" % [port.district_id, other.district_id]).is_true()


## Cells the boat can reach from the mooring at this water height (empty if it can't float there).
func _sailable(map: Dictionary, water_height: int) -> Dictionary:
	if not BoatRules.floats(map["terrain"], map["mooring"], water_height):
		return {}
	return _flood(map["terrain"], map["mooring"], water_height)


func _flood(terrain: TerrainQuery, start: Vector2i, water_height: int) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and BoatRules.floats(terrain, next, water_height):
				seen[next] = true
				queue.append(next)
	return seen


func _district(district_id: StringName) -> Dictionary:
	var scene: Node = auto_free((load(WorldPaths.scene_for(district_id)) as PackedScene).instantiate())
	return {
		"terrain": TerrainQuery.new(HeightGridBuilder.from_layer(scene.get_node("Height"))),
		"mooring": PlayerMotor.cell_of((scene.get_node("Mooring") as Node2D).position),
		"harbour": (scene.get_node("Harbour") as HarbourMarker).cell(),
	}

