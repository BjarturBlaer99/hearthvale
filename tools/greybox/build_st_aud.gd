extends SceneTree
## Fills the Height layer of St. Aud with the greybox layout below. Step 4 of 4 (see
## make_tile_texture.gd). It OVERWRITES the Height layer, including anything painted in
## the editor since. The rest of the scene is hand-written and kept as it is.
##
## Design constraints the reachability test checks (tests/world/st_aud_reachability_test.gd):
## - the east wing roof (height 4, rooftop door) is ringed by street, so it can only be
##   reached by swimming at "flooded" (water height 4);
## - the clinic roof (height 2, balcony hatch) is ringed by street: reachable only at
##   "waist" (water height 2);
## - the subway entrance is at street level: usable only at "drained".

const SCENE_PATH: String = "res://world/districts/st_aud/st_aud.tscn"
const SIZE: Vector2i = Vector2i(64, 64)

## [x, y, width, height, terrain height, kind]: kind "" plain, "c" climbable, "r" ramp.
## Everything else is street (height 0). Later entries overwrite earlier ones.
const BLOCKS: Array = [
	# Lookout tower, where the player starts: ivy up its west face, stairs down its south side.
	[6, 6, 6, 6, 5, ""],
	[6, 6, 1, 6, 5, "c"],
	[8, 12, 2, 1, 4, "r"],
	[8, 13, 2, 1, 3, "r"],
	[8, 14, 2, 1, 2, "r"],
	[8, 15, 2, 1, 1, "r"],
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
]


func _initialize() -> void:
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		push_error("tools/greybox: cannot load %s" % SCENE_PATH)
		quit(1)
		return
	# Edit state MAIN (as the editor opens scenes) keeps instanced children (Player, HUD) as
	# clean instances; without it pack() would pin every inherited property as an override.
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var layer: TileMapLayer = root.get_node("Height")
	layer.clear()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(0, false, false))
	for block: Array in BLOCKS:
		var coords: Vector2i = GreyboxTiles.terrain_coords(block[4], block[5] == "c", block[5] == "r")
		for y: int in range(block[1], block[1] + block[3]):
			for x: int in range(block[0], block[0] + block[2]):
				layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, coords)
	var out: PackedScene = PackedScene.new()
	var error: Error = out.pack(root)
	if error == OK:
		error = ResourceSaver.save(out, SCENE_PATH)
	root.free()
	print("tools/greybox: baked %d blocks into %s (%s)" % [BLOCKS.size(), SCENE_PATH, error_string(error)])
	quit(0 if error == OK else 1)
