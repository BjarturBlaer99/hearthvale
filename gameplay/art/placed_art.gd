class_name PlacedArt
extends RefCounted
## The pictures of what the hero sets down on his land (the Homestead, phase 2;
## gameplay/art/placed.png, painted by tools/art/make_sprites.gd): which frame shows what, and
## drawing a thing as it lies or stands in a cell. A placeable's `icon` names its frame here,
## so the same picture is the thing on the ground and its slot on the build bar (ItemIcons
## draws these too). A thing that joins its neighbours (Placement.joins) is put together from
## its own frame and, toward each neighbour that joins, a rail: "<frame>_n", "<frame>_e" (the
## west one is the east one mirrored) and "<frame>_s". One with a "<frame>_v" stands in a run
## going north and south as that picture (a gate). A thing that gives light shows "<frame>_lit"
## while it burns (a lamp post), and a sapling its stage's picture (Placement.frame_of). "hand"
## is the build bar's first slot.

const SHEET: Texture2D = preload("res://gameplay/art/placed.png")
const SIZE: Vector2i = Vector2i(16, 16)
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"dirt_path": 0, &"stone_path": 1, &"wood_path": 2,
	&"fence": 3, &"fence_e": 4, &"fence_n": 5, &"fence_s": 6, &"gate": 7, &"gate_v": 8,
	&"wooden_flooring": 9, &"stone_flooring": 10, &"hedge": 11, &"bench": 12, &"lamp_post_lit": 13,
	&"flower_bed_red": 14, &"oak_sapling": 15, &"oak_sapling_1": 16, &"oak_sapling_2": 17, &"hand": 18,
	&"lamp_post": 19, &"flower_bed_yellow": 20, &"flower_bed_blue": 21,
	&"cherry_sapling": 22, &"cherry_sapling_1": 23, &"cherry_sapling_2": 24,
}
## The neighbours a thing joins, as bits: north, east, south, west.
const NORTH: int = 1
const EAST: int = 2
const SOUTH: int = 4
const WEST: int = 8
## The four ways and their bits, in that order.
const WAYS: Array = [[Vector2i.UP, NORTH], [Vector2i.RIGHT, EAST], [Vector2i.DOWN, SOUTH], [Vector2i.LEFT, WEST]]


static func has(frame: StringName) -> bool:
	return FRAMES.has(frame)


## Draws frame `frame` on `canvas` with its top-left at `origin`: mirrored with `flip_h`,
## tinted by `tint`, as a white silhouette with `white`.
static func draw(canvas: CanvasItem, frame: StringName, origin: Vector2 = Vector2.ZERO, flip_h: bool = false,
		tint: Color = Color.WHITE, white: bool = false) -> void:
	if not FRAMES.has(frame):
		return
	if not flip_h:
		SpriteSheet.draw(canvas, SHEET, int(FRAMES[frame]), SIZE, origin, false, white, tint)
		return
	# Mirrored in place: a rectangle of negative width at the cell's own corner. (The engine
	# keeps such a rectangle's corner and mirrors the picture in it: SpriteSheet.draw, which
	# moves the corner a frame to the right first, would put a west rail in the next cell.)
	var source: Rect2 = Rect2(Vector2(int(FRAMES[frame]) * SIZE.x, SIZE.y if white else 0), Vector2(SIZE))
	canvas.draw_texture_rect_region(SHEET, Rect2(origin.round(), Vector2(-SIZE.x, SIZE.y)), source, tint)


## The frames that show `item` (a placeable's data) after `age` mornings, joined to the
## neighbours in `joined` (NORTH | EAST | ...), burning if `lit`, in the order they are drawn:
## each [frame, mirrored].
static func pieces(item: Dictionary, age: int = 0, joined: int = 0, lit: bool = false) -> Array:
	var frame: StringName = Placement.frame_of(item, age)
	if lit and FRAMES.has(StringName("%s_lit" % frame)):
		frame = StringName("%s_lit" % frame)
	if not Placement.joins(item):
		return [[frame, false]]
	var upright: StringName = StringName("%s_v" % frame)
	if FRAMES.has(upright) and (joined & (NORTH | SOUTH)) != 0 and (joined & (EAST | WEST)) == 0:
		return [[upright, false]]
	var out: Array = []
	if joined & NORTH and FRAMES.has(StringName("%s_n" % frame)):
		out.append([StringName("%s_n" % frame), false])
	if joined & WEST and FRAMES.has(StringName("%s_e" % frame)):
		out.append([StringName("%s_e" % frame), true])
	if joined & EAST and FRAMES.has(StringName("%s_e" % frame)):
		out.append([StringName("%s_e" % frame), false])
	out.append([frame, false])
	if joined & SOUTH and FRAMES.has(StringName("%s_s" % frame)):
		out.append([StringName("%s_s" % frame), false])
	return out


## Draws `item` on `canvas` as it lies or stands in a cell whose top-left is `origin`.
static func draw_thing(canvas: CanvasItem, item: Dictionary, age: int = 0, origin: Vector2 = Vector2.ZERO, joined: int = 0,
		tint: Color = Color.WHITE, lit: bool = false) -> void:
	for piece: Array in pieces(item, age, joined, lit):
		draw(canvas, piece[0], origin, piece[1], tint)
