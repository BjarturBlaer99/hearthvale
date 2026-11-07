extends SceneTree
## Fills the Height layer of each greybox map with its layout below. Step 4 of 4 (see
## make_tile_texture.gd). Bakes every map, or just the ones named:
##   godot --headless --path . -s res://tools/greybox/build_maps.gd [-- st_aud sea ...]
## It OVERWRITES each Height layer, including anything painted in the editor since. The rest
## of each scene is hand-written and kept as it is.
##
## Layout rules the tests check (tests/world/):
## - St. Aud: the east wing roof (rooftop door) is reachable on foot only when flooded, the
##   clinic roof only at waist, the subway only when drained. The pier (Harbour) is dry at
##   every level; the Mooring beside it is deep when flooded or at waist.
## - Greenterrace: the quay (Harbour) is dry at both levels; the Mooring is deep only when flooded.
## - Spire Nine: one water level; the dock (Harbour) is dry and the Mooring deep.
## - Sea: every port can be reached from every other port's exit.

## Each map: scene, size in cells, and blocks. Block = [x, y, width, height, terrain height,
## kind]; kind "" plain, "c" climbable, "r" ramp. Everything else is height 0. Later blocks win.
const MAPS: Dictionary = {
	"st_aud": {
		"scene": "res://world/districts/st_aud/st_aud.tscn",
		"size": Vector2i(64, 64),
		"blocks": [
			# Lookout tower, where a new game starts: ivy up its west face, stairs down its south side.
			[6, 6, 6, 6, 5, ""],
			[6, 6, 1, 6, 5, "c"],
			[8, 12, 2, 1, 4, "r"],
			[8, 13, 2, 1, 3, "r"],
			[8, 14, 2, 1, 2, "r"],
			[8, 15, 2, 1, 1, "r"],
			# Pier from the tower to the west edge: the Harbour is at its end.
			[0, 9, 6, 1, 4, ""],
			# Rubble field: wade through it at waist level.
			[13, 17, 6, 4, 1, "r"],
			# Block with an ivy-covered west face.
			[20, 6, 4, 8, 3, ""],
			[20, 6, 1, 8, 3, "c"],
			# Low warehouse with a step up from the street.
			[30, 4, 6, 6, 2, ""],
			[30, 10, 6, 1, 1, "r"],
			# Low roof north of the hospital.
			[40, 6, 8, 8, 2, ""],
			# Tall tower with ivy on its south face.
			[52, 4, 8, 10, 7, ""],
			[52, 13, 8, 1, 7, "c"],
			# St. Aud Hospital, main block.
			[24, 18, 14, 12, 6, ""],
			# Hospital east wing: the rooftop door is up here.
			[42, 20, 8, 8, 4, ""],
			# West apartments.
			[4, 24, 6, 8, 4, ""],
			# East block.
			[52, 30, 8, 8, 3, ""],
			# Clinic: its balcony hatch is up here.
			[12, 36, 6, 6, 2, ""],
			# Rubble south of the hospital.
			[22, 40, 10, 6, 1, "r"],
			# Shops around the subway plaza.
			[36, 44, 4, 8, 3, ""],
			[50, 44, 6, 6, 1, "r"],
			# South-west tower with ivy on its east face, south row, south-east tower.
			[4, 46, 6, 10, 6, ""],
			[9, 46, 1, 10, 6, "c"],
			[24, 52, 10, 8, 4, ""],
			[54, 52, 8, 8, 5, ""],
		],
	},
	"spire_nine": {
		"scene": "res://world/districts/spire_nine/spire_nine.tscn",
		"size": Vector2i(32, 32),
		"blocks": [
			# The settlement platform, at the surface, ringed by open water.
			[8, 8, 16, 16, 4, ""],
			# The spire, with a ramp up its north face.
			[13, 13, 6, 6, 6, ""],
			[15, 12, 2, 1, 5, "r"],
			# Shacks on the platform.
			[9, 9, 2, 2, 5, ""],
			[19, 9, 3, 2, 5, ""],
			[21, 20, 2, 2, 5, ""],
			# Dock out to the west edge: the Harbour is at its end.
			[0, 15, 8, 2, 4, ""],
		],
	},
	"greenterrace": {
		"scene": "res://world/districts/greenterrace/greenterrace.tscn",
		"size": Vector2i(32, 32),
		"blocks": [
			# Quay on the west edge (height 3: dry at both levels), with steps down to the street.
			[0, 14, 5, 3, 3, ""],
			[5, 14, 1, 3, 2, "r"],
			[6, 14, 1, 3, 1, "r"],
			# Terraced farm roofs, each with stairs up from the street.
			[9, 4, 8, 8, 2, ""],
			[12, 12, 2, 1, 1, "r"],
			[20, 4, 8, 8, 3, ""],
			[23, 12, 2, 1, 2, "r"],
			[23, 13, 2, 1, 1, "r"],
			[9, 19, 8, 8, 4, ""],
			[12, 16, 2, 1, 1, "r"],
			[12, 17, 2, 1, 2, "r"],
			[12, 18, 2, 1, 3, "r"],
			[20, 19, 8, 8, 5, ""],
			[20, 19, 1, 8, 5, "c"],
		],
	},
	"sea": {
		"scene": "res://world/sea/sea.tscn",
		"size": Vector2i(48, 30),
		"blocks": [
			# St. Aud (east): high ground ringed by shallows.
			[29, 7, 14, 16, 3, ""],
			[30, 8, 12, 14, 6, ""],
			# Spire Nine (north-west): a lone spire.
			[7, 2, 7, 7, 3, ""],
			[8, 3, 5, 5, 7, ""],
			# Greenterrace (south-west): stepped roofs.
			[5, 18, 12, 10, 3, ""],
			[6, 19, 10, 8, 4, ""],
			[8, 20, 6, 6, 5, ""],
			[10, 21, 2, 4, 6, ""],
			# Reefs.
			[20, 5, 3, 2, 3, ""],
			[22, 26, 3, 2, 3, ""],
		],
	},
}


func _initialize() -> void:
	var names: PackedStringArray = OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(MAPS.keys())
	for map_name: String in names:
		if not MAPS.has(map_name):
			push_error("tools/greybox: no map '%s'. Maps: %s" % [map_name, ", ".join(MAPS.keys())])
			quit(1)
			return
		if _bake(MAPS[map_name]) != OK:
			quit(1)
			return
	quit(0)


func _bake(map: Dictionary) -> Error:
	var path: String = map["scene"]
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("tools/greybox: cannot load %s" % path)
		return ERR_CANT_OPEN
	# Edit state MAIN (as the editor opens scenes) keeps instanced children (Player, HUD,
	# Boat) as clean instances; without it pack() pins every inherited property.
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var layer: TileMapLayer = root.get_node("Height")
	var size: Vector2i = map["size"]
	layer.clear()
	for y: int in size.y:
		for x: int in size.x:
			layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(0, false, false))
	for block: Array in map["blocks"]:
		var coords: Vector2i = GreyboxTiles.terrain_coords(block[4], block[5] == "c", block[5] == "r")
		for y: int in range(block[1], block[1] + block[3]):
			for x: int in range(block[0], block[0] + block[2]):
				layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, coords)
	var out: PackedScene = PackedScene.new()
	var error: Error = out.pack(root)
	if error == OK:
		error = ResourceSaver.save(out, path)
	root.free()
	print("tools/greybox: baked %d blocks into %s (%s)" % [(map["blocks"] as Array).size(), path, error_string(error)])
	return error
