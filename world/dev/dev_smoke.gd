extends Node2D
## Dev smoke scene: proves the project boots and shows what the logic layers do, as text,
## until there is a real district to look at (M2).

const COLLECTIONS: Array[StringName] = [
	&"districts", &"basins", &"nodes", &"interiors",
	&"items", &"factions", &"companions", &"quests", &"dialogues",
]

@onready var _report: Label = $UI/Report


func _ready() -> void:
	GameState.new_game()
	var lines: PackedStringArray = [
		"LOW TIDE  -  dev smoke (M1)      Godot %s" % Engine.get_version_info()["string"],
		_content_line(),
		_data_line(),
		"",
		"Water at the start of a new game:",
	]
	var network: WaterNetwork = GameState.water_network()
	for id: StringName in network.districts:
		var district: WaterNetwork.District = network.get_district(id)
		lines.append("  %s: %s (water height %d)" % [district.name, district.level_id(), district.water_height()])
	for id: StringName in network.basins:
		var basin: WaterNetwork.Basin = network.get_basin(id)
		lines.append("  %s: %d of %d" % [basin.name, basin.stored, basin.capacity])

	var solver: WaterSolver = WaterSolver.new()
	var repaired: WaterNetwork = network.copy()
	for id: StringName in repaired.nodes:
		repaired.set_node_state(id, WaterNetwork.STATE_REPAIRED)
	lines.append("")
	lines.append("Preview: lowering one level through each node, if it were repaired:")
	for id: StringName in DataRegistry.ids(&"nodes"):
		var node: WaterNetwork.NetworkNode = repaired.get_network_node(id)
		lines.append("  %s (drains %s into %s):" % [id, repaired.display_name(node.district), repaired.display_name(node.target)])
		for line: String in solver.preview(repaired, id, WaterSolver.LOWER).describe():
			lines.append("    " + line)
	var first_node: StringName = DataRegistry.ids(&"nodes")[0]
	lines.append("Right now: " + solver.preview(network, first_node, WaterSolver.LOWER).rejected_reason)

	_report.text = "\n".join(lines)
	print(_report.text)


func _content_line() -> String:
	var parts: PackedStringArray = []
	for collection: StringName in COLLECTIONS:
		parts.append("%d %s" % [DataRegistry.ids(collection).size(), collection])
	return "Content: " + ", ".join(parts)


func _data_line() -> String:
	if DataRegistry.errors.is_empty():
		return "Data: OK - every file valid, every reference resolves."
	return "Data: %d problem(s) - see the Output panel." % DataRegistry.errors.size()
