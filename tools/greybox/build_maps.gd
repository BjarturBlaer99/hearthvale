extends SceneTree
## Fills the Height layer of each greybox area with its layout below. Step 4 of 4 (see
## make_tile_texture.gd). Bakes every area, or just the ones named:
##   godot --headless --path . -s res://tools/greybox/build_maps.gd [-- village ...]
## It OVERWRITES each Height layer, including anything painted in the editor since. The rest
## of each scene is hand-written and kept as it is.
##
## Layout rules the tests check (tests/world/village_test.gd):
## - the north rise is reached by its stairs; the east meadow by the stairs at its south end,
##   and its long west edge is a one-way ledge down to the road;
## - houses, the chapel, the well, the pond and the woods are solid;
## - the south road leaves the map through a gap in the woods;
## - two houses have a door in their front wall (tests/world/doors_test.gd).
## House interiors are 11x9 rooms: log walls, the way out a doormat in the middle of the
## bottom wall at (5, 8).

## Each area: scene, size in cells, blocks, and optionally the base kind (default grass).
## Block = [x, y, width, height, terrain height, kind]; kind is "ground", "stairs", "path" (at
## that height) or a fixed-height kind from GreyboxTiles (solid, floor or furniture; the
## height is then ignored). Everything else is the base at height 0. Later blocks win.
const MAPS: Dictionary = {
	"village": {
		"scene": "res://world/areas/village/village.tscn",
		"size": Vector2i(48, 36),
		"blocks": [
			# The north rise, wooded along the top, with the old chapel on it.
			[0, 0, 48, 8, 2, "ground"],
			[0, 0, 48, 2, 2, "tree"],
			[18, 2, 12, 3, 3, "roof_blue"],
			[18, 5, 12, 1, 3, "wall"],
			[22, 8, 4, 1, 1, "stairs"],
			# The east meadow: a long ledge down to the road, stairs at its south end.
			[38, 12, 9, 18, 1, "ground"],
			[40, 30, 3, 1, 1, "stairs"],
			[42, 15, 2, 2, 1, "tree"],
			[44, 22, 2, 2, 1, "tree"],
			[40, 25, 1, 1, 1, "rock"],
			# Houses: a roof over a timber front wall.
			[6, 11, 6, 3, 3, "roof"],
			[6, 14, 6, 1, 3, "wall"],
			[14, 11, 6, 3, 3, "roof"],
			[14, 14, 6, 1, 3, "wall"],
			[28, 11, 6, 3, 3, "roof_blue"],
			[28, 14, 6, 1, 3, "wall"],
			[6, 21, 6, 3, 3, "roof"],
			[6, 24, 6, 1, 3, "wall"],
			# Doors: the weaver's and the elder's.
			[16, 14, 1, 1, 0, "door"],
			[30, 14, 1, 1, 0, "door"],
			# Roads: north-south from the stairs out through the woods; east-west across.
			[22, 9, 4, 27, 0, "path"],
			[3, 16, 35, 2, 0, "path"],
			# The well.
			[18, 19, 2, 2, 2, "stone"],
			# A fenced field with a gate.
			[4, 27, 10, 1, 1, "fence"],
			[4, 33, 10, 1, 1, "fence"],
			[4, 27, 1, 7, 1, "fence"],
			[13, 27, 1, 7, 1, "fence"],
			[8, 27, 2, 1, 0, "ground"],
			# The pond.
			[28, 26, 6, 4, 0, "water"],
			# Rocks and trees about the village.
			[33, 20, 1, 1, 0, "rock"],
			[16, 26, 1, 1, 0, "rock"],
			[3, 9, 2, 2, 0, "tree"],
			[34, 31, 2, 2, 0, "tree"],
			# Woods round the edges; the south road leaves through a gap.
			[0, 8, 2, 26, 0, "tree"],
			[46, 8, 2, 4, 0, "tree"],
			[47, 12, 1, 18, 0, "tree"],
			[44, 30, 4, 4, 0, "tree"],
			[0, 34, 22, 2, 0, "tree"],
			[26, 34, 22, 2, 0, "tree"],
		],
	},
	"elder_house": {
		"scene": "res://world/areas/elder_house/elder_house.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			[5, 1, 1, 1, 0, "hearth"],
			[1, 2, 3, 1, 0, "shelf"],
			[8, 2, 1, 1, 0, "bed"],
			[4, 4, 3, 2, 0, "rug"],
			[1, 5, 2, 1, 0, "table"],
			[1, 7, 1, 1, 0, "barrel"],
			[9, 7, 1, 1, 0, "barrel"],
		],
	},
	"weaver_house": {
		"scene": "res://world/areas/weaver_house/weaver_house.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			[1, 2, 2, 1, 0, "shelf"],
			[6, 2, 3, 1, 0, "table"],
			[9, 2, 1, 1, 0, "barrel"],
			[1, 5, 1, 1, 0, "bed"],
			[3, 4, 3, 2, 0, "rug"],
			[8, 5, 1, 2, 0, "barrel"],
		],
	},
}


func _initialize() -> void:
	var names: PackedStringArray = OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(MAPS.keys())
	for map_name: String in names:
		if not MAPS.has(map_name):
			push_error("tools/greybox: no area '%s'. Areas: %s" % [map_name, ", ".join(MAPS.keys())])
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
	# Edit state MAIN (as the editor opens scenes) keeps instanced children (Player, HUD) as
	# clean instances; without it pack() pins every inherited property.
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var layer: TileMapLayer = root.get_node("Height")
	var size: Vector2i = map["size"]
	var base: Vector2i = GreyboxTiles.coords(str(map.get("base", "ground")), 0)
	layer.clear()
	for y: int in size.y:
		for x: int in size.x:
			layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, base)
	for block: Array in map["blocks"]:
		var kind: String = block[5]
		if not GreyboxTiles.is_known_kind(kind):
			push_error("tools/greybox: unknown tile kind '%s' in %s" % [kind, block])
			root.free()
			return ERR_INVALID_DATA
		var coords: Vector2i = GreyboxTiles.coords(kind, block[4])
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
