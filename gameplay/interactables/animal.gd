class_name Animal
extends Node2D
## An animal of the hero's land as it is met (the Homestead, phase 4; docs/TECH_DESIGN.md §30):
## a hen, a sheep or a cow, out in its pasture by day or in its building's room by night. It is a
## creature, like the village's chickens: it wanders among the cells it is given (AnimalMotion),
## blocks nobody and is never in the way. A right click facing it pets it and takes what it has
## ready (the area calls GameState.pet_animal). What it has ready shows over its head; an animal
## that went hungry this morning shows it too. GameState keeps what it is (its place in the herd);
## PlacedAnimals makes one for each animal that is where the area is, and moves it.
## Position = where it stands.

const HENS: Texture2D = preload("res://gameplay/art/critters.png")
const SHEET: Texture2D = preload("res://gameplay/art/animals.png")
## Frames of animals.png in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"sheep": 0, &"sheep_walk": 1, &"sheep_graze": 2, &"cow": 3, &"cow_walk": 4, &"cow_graze": 5,
	&"sheep_blink": 6, &"cow_blink": 7,
}
const SIZE: Vector2i = Vector2i(24, 20)
## How fast each kind walks (px/s), and the shadow under it.
const SPEED: Dictionary = {&"chicken": 16.0, &"sheep": 12.0, &"cow": 10.0}
const SHADOW: Dictionary = {&"chicken": Vector2(4, 1.5), &"sheep": Vector2(8, 2), &"cow": Vector2(9, 2.5)}
## A standing animal blinks for BLINK_TIME every BLINK_EVERY seconds.
const BLINK_EVERY: float = 3.3
const BLINK_TIME: float = 0.16
## The prompt facing it: what a right click does.
const PET_PROMPT: String = "Pet the %s"
const TAKE_PROMPT: String = "Take the %s"
## How far from where it stands it can be reached (px).
const REACH: float = 12.0
## Where the top of its head is, above where it stands (px): what it has ready shows over it.
const HEAD_TOP: Dictionary = {&"chicken": -10, &"sheep": -14, &"cow": -16}
## The bubble over the head of one that went hungry this morning.
const BUBBLE: Color = Color(0.98, 0.96, 0.90, 0.80)
const BUBBLE_EDGE: Color = Color(0.25, 0.20, 0.22, 0.9)

## Its place in the herd (GameState.homestead().animal(index)).
var index: int = -1
var kind_id: StringName = &""
var motion: AnimalMotion

var _clock: float = 0.0


## Shows the animal at `herd_index`, standing in `start` among `cells`.
func setup(herd_index: int, cells: Array[Vector2i], start: Vector2i, rng: RandomNumberGenerator) -> void:
	index = herd_index
	kind_id = StringName(str(record().get("kind", "")))
	name = "Animal_%d" % index
	motion = AnimalMotion.new(cells, start, float(SPEED.get(kind_id, 12.0)), rng)
	position = motion.position
	_clock = rng.randf() * 10.0


## What GameState keeps of it.
func record() -> Dictionary:
	return GameState.homestead().animal(index)


func kind() -> Dictionary:
	return DataRegistry.get_animal(kind_id)


## Moves it on by `delta` seconds (PlacedAnimals calls this, and stops calling while build mode
## holds the world still).
func walk(delta: float) -> void:
	if motion == null:
		return
	_clock += delta
	motion.step(delta)
	position = motion.position
	queue_redraw()


func cell() -> Vector2i:
	return motion.cell() if motion != null else PlayerMotor.cell_of(position)


## Whether it can be reached from `at` (the cell the hero faces): it stands there, or near the
## middle of it.
func reached_from(at: Vector2i) -> bool:
	return cell() == at or position.distance_to(GridBody.cell_center(at)) <= REACH


## Whether something of its is ready to be taken.
func has_ready() -> bool:
	return bool(record().get("ready", false))


func is_hungry() -> bool:
	return bool(record().get("hungry", false))


## The HUD's prompt facing it: "Take the Egg" when one waits, else "Pet the Chicken".
func prompt() -> String:
	if has_ready():
		return TAKE_PROMPT % str(DataRegistry.get_item(Herd.gives(kind())).get("name", ""))
	return PET_PROMPT % Herd.name_of(kind())


## The picture it shows now: its kind's, standing, walking, grazing or blinking.
func frame() -> StringName:
	var walking: bool = motion != null and motion.state == AnimalMotion.WALK
	var grazing: bool = motion != null and motion.state == AnimalMotion.GRAZE
	if kind_id == &"chicken":
		if grazing:
			return &"chicken_peck" if fmod(_clock, 0.5) < 0.25 else &"chicken"
		if walking:
			return &"chicken_walk" if fmod(_clock, 0.3) < 0.15 else &"chicken"
		return &"chicken_blink" if fmod(_clock, BLINK_EVERY) >= BLINK_EVERY - BLINK_TIME else &"chicken"
	if walking:
		return StringName("%s_walk" % kind_id) if fmod(_clock, 0.5) < 0.25 else kind_id
	if grazing:
		return StringName("%s_graze" % kind_id)
	return StringName("%s_blink" % kind_id) if fmod(_clock, BLINK_EVERY) >= BLINK_EVERY - BLINK_TIME else kind_id


func _draw() -> void:
	SoftShadow.draw(self, Vector2.ZERO, SHADOW.get(kind_id, Vector2(6, 2)))
	var mirrored: bool = motion != null and motion.facing_x > 0.0
	if kind_id == &"chicken":
		_draw_frame(HENS, int(Critter.FRAMES[frame()]), Critter.SIZE, Vector2(-8, -14), mirrored)
	else:
		_draw_frame(SHEET, int(FRAMES.get(frame(), 0)), SIZE, Vector2(-12, -18), mirrored)
	# Over its head: what it has ready, or that it went hungry.
	var head: float = float(HEAD_TOP.get(kind_id, -14))
	if has_ready():
		_draw_ready(Vector2(0, head - 2))
	elif is_hungry():
		_draw_hungry(Vector2(0, head - 2))


## Draws a frame with its top-left at `origin`, mirrored in place with `mirrored` (as PlacedArt
## does: SpriteSheet.draw puts a mirrored frame a frame's width to the right in this engine).
func _draw_frame(texture: Texture2D, frame_index: int, size: Vector2i, origin: Vector2, mirrored: bool) -> void:
	var source: Rect2 = Rect2(Vector2(frame_index * size.x, 0), Vector2(size))
	if mirrored:
		# The engine keeps a rectangle's corner when its width is negative, and mirrors in it.
		draw_texture_rect_region(texture, Rect2(origin.round(), Vector2(-size.x, size.y)), source)
	else:
		draw_texture_rect_region(texture, Rect2(origin.round(), Vector2(size)), source)


## A small bubble whose foot is at `foot`, with what it has ready drawn at half size: small
## enough to sit over its own head, and pointing down at it, so it is plain whose it is.
func _draw_ready(foot: Vector2) -> void:
	var box: Rect2 = Rect2(foot + Vector2(-5, -12), Vector2(10, 10))
	draw_rect(box.grow(1), BUBBLE_EDGE)
	draw_rect(box, BUBBLE)
	draw_rect(Rect2(foot + Vector2(-1, -2), Vector2(2, 2)), BUBBLE)
	var icon: StringName = ItemIcons.name_for(Herd.gives(kind()))
	var index: int = int(ItemIcons.FRAMES.get(icon, ItemIcons.FRAMES[&"gem"]))
	var source: Rect2 = Rect2(Vector2(index * ItemIcons.SIZE.x, 0), Vector2(ItemIcons.SIZE))
	draw_texture_rect_region(ItemIcons.SHEET, Rect2(box.position + Vector2(1, 1), Vector2(8, 8)), source)


## A small bubble with three dots whose foot is at `foot`: a hungry animal.
func _draw_hungry(foot: Vector2) -> void:
	var box: Rect2 = Rect2(foot + Vector2(-6, -9), Vector2(12, 7))
	draw_rect(box.grow(1), BUBBLE_EDGE)
	draw_rect(box, BUBBLE)
	draw_rect(Rect2(foot + Vector2(-1, -2), Vector2(2, 2)), BUBBLE)
	for x: int in [-3, 0, 3]:
		draw_rect(Rect2(foot + Vector2(x - 0.5, -6), Vector2(1, 1)), BUBBLE_EDGE)
