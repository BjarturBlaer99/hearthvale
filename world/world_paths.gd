class_name WorldPaths
extends RefCounted
## Where each area's scene lives (TECH_DESIGN §1): res://world/areas/<id>/<id>.tscn.

const START_AREA: StringName = &"village"


static func scene_for(area_id: StringName) -> String:
	return "res://world/areas/%s/%s.tscn" % [area_id, area_id]


## The name an area shows (its AreaController's area_name), e.g. for a save on the title
## screen. Falls back to the id, capitalised.
static func area_name(area_id: StringName) -> String:
	var path: String = scene_for(area_id)
	if String(area_id).is_empty() or not ResourceLoader.exists(path):
		return String(area_id).capitalize()
	var scene: Node = (load(path) as PackedScene).instantiate()
	var shown: Variant = scene.get(&"area_name")
	scene.free()
	return str(shown) if shown != null else String(area_id).capitalize()
