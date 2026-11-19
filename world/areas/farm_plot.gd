class_name FarmPlot
extends Node2D
## The hero's plot as it lies in an area (P3, GDD §7): a bed of soil, each cell drawn bare,
## tilled or watered as GameState's Farm says, with whatever grows in it. Position = the
## top-left corner of its first cell; its size is the farm rules'. It is ground to walk on: it
## blocks nothing, crops and all. The area works its cells with the tools and seeds
## (AreaController.use_item) and picks what is ripe (interact).
## A cell worked by a stroke is drawn as it was until the stroke's blow (tool polish, D4): the
## area holds it (hold()) as the work is done and lets go at the blow (let_go()). For show only:
## the farm is changed at once.

const SHEET: Texture2D = preload("res://gameplay/art/soil.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {&"bare": 0, &"bare_b": 1, &"tilled": 2, &"watered": 3}
const CELL: Vector2i = Vector2i(16, 16)
## What grows (gameplay/art/crops.png), in the order the tool paints the frames (a test
## checks): three pictures every crop shares, then each crop growing and ripe.
const CROPS: Texture2D = preload("res://gameplay/art/crops.png")
const CROP_FRAMES: Dictionary = {
	&"seeded": 0, &"sprout": 1, &"withered": 2,
	&"turnip_growing": 3, &"turnip_ripe": 4, &"carrot_growing": 5, &"carrot_ripe": 6,
	&"wheat_growing": 7, &"wheat_ripe": 8, &"potato_growing": 9, &"potato_ripe": 10,
	&"pumpkin_growing": 11, &"pumpkin_ripe": 12,
}
## The bed's rim: a dark shade of the soil, a pixel wide, so it reads as dug and not as a path.
const RIM: Color = Color(0.30, 0.20, 0.13)

## The cells (the plot's own) drawn as they were, each { "soil", "crop", "phase", "sprinkler" }.
var _held: Dictionary = {}


func _ready() -> void:
	EventBus.farm_changed.connect(queue_redraw)


## The map cell of its north-west corner.
func origin() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Its size in cells (the farm rules').
func plot_size() -> Vector2i:
	return GameState.farm().size


## Whether the map cell `at` is one of the plot's.
func covers(at: Vector2i) -> bool:
	return Rect2i(origin(), plot_size()).has_point(at)


## The plot's own cell for the map cell `at` ((0, 0) is its north-west corner).
func plot_cell(at: Vector2i) -> Vector2i:
	return at - origin()


## The map cell of the plot's own cell `cell`.
func map_cell(cell: Vector2i) -> Vector2i:
	return origin() + cell


## Every map cell of the plot, row by row.
func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in plot_size().y:
		for x: int in plot_size().x:
			out.append(origin() + Vector2i(x, y))
	return out


## What the map cell `at` is: a Farm state, or "" if it isn't a cell of the plot.
func soil_at(at: Vector2i) -> StringName:
	return GameState.farm().state_of(plot_cell(at)) if covers(at) else &""


## Keeps drawing each of `at` (map cells) as it is now, whatever happens to it, until let_go().
func hold(at: Array[Vector2i]) -> void:
	var farm: Farm = GameState.farm()
	for map: Vector2i in at:
		if not covers(map):
			continue
		var cell: Vector2i = plot_cell(map)
		if _held.has(cell):
			continue
		_held[cell] = {"soil": farm.state_of(cell), "crop": farm.crop_at(cell) if farm.has_crop(cell) else "",
			"phase": GameState.crop_phase(cell) if farm.has_crop(cell) else &"", "sprinkler": farm.has_sprinkler(cell)}


## Draws every cell as it is again.
func let_go() -> void:
	_held.clear()
	queue_redraw()


## What the map cell `at` is drawn as: { "soil", "crop", "phase", "sprinkler" } (for tests).
func shown_at(at: Vector2i) -> Dictionary:
	var cell: Vector2i = plot_cell(at)
	if _held.has(cell):
		return _held[cell]
	var farm: Farm = GameState.farm()
	return {"soil": farm.state_of(cell), "crop": farm.crop_at(cell) if farm.has_crop(cell) else "",
		"phase": GameState.crop_phase(cell) if farm.has_crop(cell) else &"", "sprinkler": farm.has_sprinkler(cell)}


## Takes whatever grows on the plot's cells off `layer` (flowers and tufts on the Decor layer):
## it is a bed of soil. For show: those tiles block nothing.
func clear_ground(layer: TileMapLayer) -> void:
	if layer == null:
		return
	for cell: Vector2i in cells():
		layer.erase_cell(cell)


## The picture a cell shows: its state's, bare soil in two kinds so the bed isn't a pattern.
static func frame_for(state: StringName, cell: Vector2i) -> StringName:
	if state == Farm.BARE and (cell.x * 7 + cell.y * 13) % 3 == 0:
		return &"bare_b"
	return state


## The picture for `crop` (a crop id) at `phase` (a Farm phase): its own while it is growing
## or ripe; the one every crop shares when it is just planted, a sprout or withered, and for a
## crop that has no pictures of its own.
static func crop_frame(crop: String, phase: StringName) -> StringName:
	var own: StringName = StringName("%s_%s" % [crop, phase])
	if CROP_FRAMES.has(own):
		return own
	if CROP_FRAMES.has(phase):
		return phase
	return &"sprout"


func _draw() -> void:
	var size: Vector2i = plot_size()
	var shown: Dictionary = {}
	for y: int in size.y:
		for x: int in size.x:
			shown[Vector2i(x, y)] = shown_at(map_cell(Vector2i(x, y)))
	for y: int in size.y:
		for x: int in size.x:
			var cell: Vector2i = Vector2i(x, y)
			SpriteSheet.draw(self, SHEET, FRAMES[frame_for(shown[cell]["soil"], cell)], CELL, Vector2(cell * CELL))
	var bed: Vector2 = Vector2(size * CELL)
	draw_rect(Rect2(0.0, 0.0, bed.x, 1.0), RIM)
	draw_rect(Rect2(0.0, bed.y - 1.0, bed.x, 1.0), RIM)
	draw_rect(Rect2(0.0, 0.0, 1.0, bed.y), RIM)
	draw_rect(Rect2(bed.x - 1.0, 0.0, 1.0, bed.y), RIM)
	# What grows, over the soil and its rim.
	for y: int in size.y:
		for x: int in size.x:
			var cell: Vector2i = Vector2i(x, y)
			if not str(shown[cell]["crop"]).is_empty():
				SpriteSheet.draw(self, CROPS, CROP_FRAMES[crop_frame(str(shown[cell]["crop"]), shown[cell]["phase"])], CELL, Vector2(cell * CELL))
			elif shown[cell]["sprinkler"]:
				SpriteSheet.draw(self, Furnishing.SHEET, int(Furnishing.FRAMES[&"sprinkler"]), CELL, Vector2(cell * CELL))
