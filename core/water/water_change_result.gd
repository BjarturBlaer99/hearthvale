class_name WaterChangeResult
extends RefCounted
## What one network operation would do, computed by WaterSolver.preview() before anything
## changes (docs/TECH_DESIGN.md §3.1). The UI shows it so the player sees every consequence
## before confirming (GDD pillar 2); WaterSolver.apply() then makes exactly this happen.

var node_id: StringName
## WaterSolver.LOWER (-1) or WaterSolver.RAISE (+1).
var direction: int = 0
## The district the node raises or lowers.
var source_district: StringName
## Units the operation moves (one step of the source district).
var volume: int = 0
## Why the operation cannot happen. Empty when it can.
var rejected_reason: String = ""
## Affected districts, in the order the water reached them:
## id -> { name, from_level, to_level, from_pending, to_pending, step_volume }
var districts: Dictionary[StringName, Dictionary] = {}
## Affected basins, in the order the water reached them:
## id -> { name, from_stored, to_stored, capacity }
var basins: Dictionary[StringName, Dictionary] = {}


func is_rejected() -> bool:
	return not rejected_reason.is_empty()


## District id -> new level id, only for districts whose level changes, in flow order.
func level_changes() -> Dictionary[StringName, StringName]:
	var out: Dictionary[StringName, StringName] = {}
	for id: StringName in districts:
		var entry: Dictionary = districts[id]
		if entry["from_level"] != entry["to_level"]:
			out[id] = entry["to_level"]
	return out


## One line per consequence, for the preview UI (M4) and logs.
func describe() -> PackedStringArray:
	var lines: PackedStringArray = []
	if is_rejected():
		lines.append(rejected_reason)
		return lines
	for id: StringName in districts:
		var entry: Dictionary = districts[id]
		var toward: String = "%d of %d toward the next level" % [entry["to_pending"], entry["step_volume"]]
		if entry["from_level"] != entry["to_level"]:
			var line: String = "%s: %s -> %s" % [entry["name"], entry["from_level"], entry["to_level"]]
			if int(entry["to_pending"]) > 0:
				line += " (%s)" % toward
			lines.append(line)
		else:
			var trend: String = "rising" if int(entry["to_pending"]) > int(entry["from_pending"]) else "falling"
			lines.append("%s: water %s, %s" % [entry["name"], trend, toward])
	for id: StringName in basins:
		var entry: Dictionary = basins[id]
		lines.append("%s: %d -> %d of %d" % [entry["name"], entry["from_stored"], entry["to_stored"], entry["capacity"]])
	return lines
