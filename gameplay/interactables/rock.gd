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
## The area makes rocks from the map's Spawns markers. Position = the cell's top-left corner.

const SHEET: Texture2D = preload("res://gameplay/art/rocks.png")
## Frames in the order tools/art/make_sprites.gd paints them (a test checks).
const FRAMES: Dictionary = {
	&"stone": 0, &"copper_ore": 1, &"coal": 2, &"iron_ore": 3, &"gold_ore": 4, &"crystal": 5,
	&"ladder": 6, &"lift": 7,
	# The hero's land (the Homestead): a field stone, a boulder and a great boulder.
	&"rock": 8, &"boulder": 9, &"great_boulder": 10,
}
const SIZE: Vector2i = Vector2i(16, 16)
## How long it shudders under a blow that doesn't break it (s).
const SHAKE_TIME: float = 0.14

## What it holds today (a kind of rock in the mine's rules).
var kind: StringName = MineRules.STONE
## How many more blows it takes.
var blows_left: int = 1
var broken: bool = false

var _terrain: TerrainQuery
var _shake: float = 0.0


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
## whichever was in hand when he came in.
func strike(fewer: int = 0) -> bool:
	if broken:
		return false
	blows_left -= 1
	if blows_left - maxi(fewer, 0) > 0:
		_shake = SHAKE_TIME
		if get_parent() != null:
			Burst.spawn(get_parent(), position + Vector2(8, 8), &"dust", 0.5)
		queue_redraw()
		return false
	broken = true
	visible = false
	if _terrain != null:
		_terrain.set_occupied(cell(), false)
	if get_parent() != null:
		Burst.spawn(get_parent(), position + Vector2(8, 8), &"shards")
	return true


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	if broken:
		return
	SoftShadow.draw(self, Vector2(8, 14), Vector2(6, 1.8), 0.8)
	# A blow that doesn't break it knocks it a pixel sideways and back.
	var nudge: Vector2 = Vector2(1, 0) if _shake > SHAKE_TIME * 0.5 else (Vector2(-1, 0) if _shake > 0.0 else Vector2.ZERO)
	SpriteSheet.draw(self, SHEET, int(FRAMES.get(kind, FRAMES[MineRules.STONE])), SIZE, nudge)
