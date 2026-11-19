class_name Rock
extends Node2D
## A rock of the Old Quarry (2026-11-17, docs/TECH_DESIGN.md §27). It stands in its cell until
## the pickaxe breaks it: so many blows for what it holds (MineRules), then a burst of shards
## and its cell is free. What it holds shows in it: plain stone, or flecks of copper, a seam of
## coal, rust, gold, crystal. The area tells it what it holds today (hold), strikes it
## (strike), and decides what breaking it gives; a rock broken earlier today is gone when the
## area loads (be_gone). Only the pickaxe touches it: the sword and bombs pass it by.
## On the hero's land (the Homestead, 2026-11-18) a rock is a kind of the homestead's rules
## (a rock, a boulder, a great boulder), and one broken is gone for good.
## A blow shows (tool polish, D6): a white flash, a shudder and chips in the rock's own colours;
## the last throws rubble. Struck from a stroke, it is shown at the stroke's blow (show_blow()).
## The area makes rocks from the map's Spawns markers. Position = the cell's top-left corner.

const SHEET: Texture2D = preload("res://gameplay/art/rocks.png")
## Frames in the order they stand in the sheet (art/sheets.json; a test checks).
const FRAMES: Dictionary = {
	&"stone": 0, &"copper_ore": 1, &"coal": 2, &"iron_ore": 3, &"gold_ore": 4, &"crystal": 5,
	&"ladder": 6, &"lift": 7,
	# The hero's land (the Homestead): a field stone, a boulder and a great boulder.
	&"rock": 8, &"boulder": 9, &"great_boulder": 10,
}
const SIZE: Vector2i = Vector2i(16, 16)
## How long it shudders under a blow that doesn't break it (s).
const SHAKE_TIME: float = 0.14
## How long a blow flashes it white (s).
const FLASH_TIME: float = 0.06
## How much of the white shows in a flash.
const FLASH_TINT: Color = Color(1.0, 1.0, 1.0, 0.55)
## How many of its own colours its chips take.
const CHIP_COLOURS: int = 4

## Each kind's chip colours, read once from its picture.
static var _chip_colours: Dictionary = {}

## What it holds today (a kind of rock in the mine's rules).
var kind: StringName = MineRules.STONE
## How many more blows it takes.
var blows_left: int = 1
var broken: bool = false

var _terrain: TerrainQuery
var _shake: float = 0.0
var _flash: float = 0.0
## A blow struck whose look waits for show_blow().
var _blow_due: bool = false
## Broken, but still drawn whole until the blow shows.
var _shown_whole: bool = false


## The area hands over its terrain, to free the cell once it is broken.
func set_terrain(terrain: TerrainQuery, _rng: RandomNumberGenerator) -> void:
	_terrain = terrain


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Only a whole rock is there to be faced.
func covers(at: Vector2i) -> bool:
	return not broken and at == cell()


## Whole, it stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return not broken


## What it holds today, and the blows that takes.
func hold(what: StringName, blows: int) -> void:
	kind = what
	blows_left = maxi(blows, 1)
	queue_redraw()


## It was broken earlier today: gone, without a sound.
func be_gone() -> void:
	broken = true
	visible = false


## One blow of the pickaxe. Returns whether that broke it. A better pickaxe needs `fewer`
## blows than the plain one (ToolUse.fewer_blows): it is the pickaxe that strikes that counts,
## whichever was in hand when he came in. The blow shows at once, or with `show_now` false when
## show_blow() is called (at a stroke's blow); what it does is done at once either way.
func strike(fewer: int = 0, show_now: bool = true) -> bool:
	if broken:
		return false
	blows_left -= 1
	if blows_left - maxi(fewer, 0) <= 0:
		broken = true
		_shown_whole = true
		if _terrain != null:
			_terrain.set_occupied(cell(), false)
	_blow_due = true
	if show_now:
		show_blow()
	return broken


## Shows the last blow struck: it shudders, flashes and throws chips; broken, it is gone in a
## throw of rubble. Nothing if no blow waits.
func show_blow() -> void:
	if not _blow_due:
		return
	_blow_due = false
	var colours: Array = chip_colours(kind)
	if broken:
		_shown_whole = false
		visible = false
		if get_parent() != null:
			Burst.spawn(get_parent(), position + Vector2(8, 10), &"rubble", 1.0, colours)
		return
	_shake = SHAKE_TIME
	_flash = FLASH_TIME
	if get_parent() != null:
		Burst.spawn(get_parent(), position + Vector2(8, 10), &"chips", 1.0, colours)
		Burst.spawn(get_parent(), position + Vector2(8, 6), &"spark", 0.5)
	queue_redraw()


## Whether it is flashing white (a blow just shown).
func is_flashing() -> bool:
	return _flash > 0.0


## The colours of `rock_kind`'s picture that its chips take: the commonest of its own, but the
## outline's, most first, at most CHIP_COLOURS.
static func chip_colours(rock_kind: StringName) -> Array:
	if _chip_colours.has(rock_kind):
		return _chip_colours[rock_kind]
	var counts: Dictionary = {}
	var frame: int = int(FRAMES.get(rock_kind, FRAMES[MineRules.STONE]))
	var image: Image = SHEET.get_image()
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var colour: Color = image.get_pixel(frame * SIZE.x + x, y)
			if colour.a < 1.0 or colour.get_luminance() < 0.2:
				continue
			counts[colour] = int(counts.get(colour, 0)) + 1
	var colours: Array = counts.keys()
	colours.sort_custom(func(a: Color, b: Color) -> bool: return counts[a] > counts[b])
	_chip_colours[rock_kind] = colours.slice(0, CHIP_COLOURS)
	return _chip_colours[rock_kind]


func _process(delta: float) -> void:
	if _shake > 0.0 or _flash > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		_flash = maxf(_flash - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	if broken and not _shown_whole:
		return
	SoftShadow.draw(self, Vector2(8, 14), Vector2(6, 1.8), 0.8)
	# A blow that doesn't break it knocks it a pixel sideways and back.
	var nudge: Vector2 = Vector2(1, 0) if _shake > SHAKE_TIME * 0.5 else (Vector2(-1, 0) if _shake > 0.0 else Vector2.ZERO)
	SpriteSheet.draw(self, SHEET, int(FRAMES.get(kind, FRAMES[MineRules.STONE])), SIZE, nudge)
	# A blow's flash: its white picture laid over it, half seen.
	if _flash > 0.0:
		SpriteSheet.draw(self, SHEET, int(FRAMES.get(kind, FRAMES[MineRules.STONE])), SIZE, nudge, false, true, FLASH_TINT)
