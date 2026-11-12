class_name Critter
extends Node2D
## A bit of life (docs/TECH_DESIGN.md §15): a chicken, a butterfly or a firefly. It wanders near
## where it was put (CritterMotion), never blocks anyone, never fights and is never saved.
## Chickens and butterflies are drawn from gameplay/art/critters.png (painted by
## tools/art/make_sprites.gd), fireflies as glowing dots in code. The area spawns critters from the
## map's Spawns markers and calls set_terrain(). Position = where it stands, or the spot on the
## ground it hovers over.

const SHEET: Texture2D = preload("res://gameplay/art/critters.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"chicken": 0, &"chicken_peck": 1, &"chicken_walk": 2, &"butterfly_open": 3, &"butterfly_closed": 4,
	&"bluefly_open": 5, &"bluefly_closed": 6,
}
## Each kind: how it moves, how far it wanders (px) and how fast (px/s).
const KINDS: Dictionary = {
	&"chicken": {"style": CritterMotion.WALKER, "radius": 40.0, "speed": 18.0},
	&"butterfly": {"style": CritterMotion.FLIER, "radius": 28.0, "speed": 22.0},
	&"firefly": {"style": CritterMotion.FLIER, "radius": 40.0, "speed": 10.0},
}
const SIZE: Vector2i = Vector2i(16, 16)
const GLOW: Color = Color(0.85, 1.0, 0.45)

@export var kind: StringName = &"chicken"

var motion: CritterMotion

var _clock: float = 0.0
var _blue: bool = false


## Starts it moving, from the middle of the cell it was put in.
func set_terrain(terrain: TerrainQuery, rng: RandomNumberGenerator) -> void:
	var how: Dictionary = KINDS.get(kind, KINDS[&"chicken"])
	position += Vector2(8, 8)
	motion = CritterMotion.new(how["style"], position, float(how["radius"]), float(how["speed"]), rng, terrain)
	_blue = rng.randf() < 0.5
	_clock = rng.randf() * 10.0


func _process(delta: float) -> void:
	if motion == null:
		return
	_clock += delta
	motion.step(delta)
	position = motion.position
	queue_redraw()


func _draw() -> void:
	if motion == null:
		return
	match kind:
		&"chicken":
			SoftShadow.draw(self, Vector2.ZERO, Vector2(4, 1.5))
			var frame: StringName = &"chicken"
			if motion.state == CritterMotion.PECK:
				frame = &"chicken_peck" if fmod(_clock, 0.5) < 0.25 else &"chicken"
			elif motion.state == CritterMotion.WALK:
				frame = &"chicken_walk" if fmod(_clock, 0.3) < 0.15 else &"chicken"
			SpriteSheet.draw(self, SHEET, FRAMES[frame], SIZE, Vector2(-8, -14), motion.facing_x > 0.0)
		&"butterfly":
			var hover: float = roundf(8.0 + sin(_clock * 3.0) * 2.0)
			SoftShadow.draw(self, Vector2.ZERO, Vector2(2, 1), 0.7)
			var wings: String = "open" if fmod(_clock, 0.24) < 0.12 else "closed"
			SpriteSheet.draw(self, SHEET, FRAMES[StringName(("bluefly_" if _blue else "butterfly_") + wings)], SIZE, Vector2(-8, -8 - hover))
		&"firefly":
			var glow: float = 0.5 + 0.5 * sin(_clock * 2.3)
			var at: Vector2 = Vector2(0, -10.0 + sin(_clock * 1.7) * 3.0).round()
			draw_circle(at, 3.0, Color(GLOW, 0.18 * glow))
			draw_rect(Rect2(at - Vector2(0.5, 0.5), Vector2(1, 1)), Color(GLOW, 0.4 + 0.6 * glow))
