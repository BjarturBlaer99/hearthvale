extends Node2D
## M0 smoke scene: proves the project boots, the autoloads exist and the content loaded.
## Replaced as the main scene once there is a real district to show (M2).

const COLLECTIONS: Array[StringName] = [
	&"districts", &"basins", &"nodes", &"interiors",
	&"items", &"factions", &"companions", &"quests", &"dialogues",
]

@onready var _report: Label = $UI/Report


func _ready() -> void:
	var lines: PackedStringArray = [
		"LOW TIDE  -  M0 skeleton",
		"Godot %s  |  viewport %s" % [Engine.get_version_info()["string"], get_viewport_rect().size],
		"",
	]
	for collection: StringName in COLLECTIONS:
		var found: PackedStringArray = PackedStringArray(DataRegistry.ids(collection))
		lines.append("%s (%d): %s" % [collection, found.size(), ", ".join(found)])
	lines.append("")
	if DataRegistry.errors.is_empty():
		lines.append("Data: OK - every file valid, every reference resolves.")
	else:
		lines.append("Data: %d problem(s) - see the Output panel." % DataRegistry.errors.size())
	_report.text = "\n".join(lines)
	print(_report.text)
