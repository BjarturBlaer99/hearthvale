class_name WorldPaths
extends RefCounted
## Where each map's scene lives. Districts follow TECH_DESIGN §1:
## res://world/districts/<id>/<id>.tscn. The sea is its own map, id "sea".

const SEA_ID: StringName = &"sea"
const SEA_SCENE: String = "res://world/sea/sea.tscn"


static func scene_for(map_id: StringName) -> String:
	if map_id == SEA_ID:
		return SEA_SCENE
	return "res://world/districts/%s/%s.tscn" % [map_id, map_id]
