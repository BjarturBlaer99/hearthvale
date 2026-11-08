class_name WorldPaths
extends RefCounted
## Where each area's scene lives (TECH_DESIGN §1): res://world/areas/<id>/<id>.tscn.

const START_AREA: StringName = &"village"


static func scene_for(area_id: StringName) -> String:
	return "res://world/areas/%s/%s.tscn" % [area_id, area_id]
