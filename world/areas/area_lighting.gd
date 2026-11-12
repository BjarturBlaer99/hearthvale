class_name AreaLighting
extends Node2D
## The light of an area (P1b, docs/TECH_DESIGN.md §6): its ambient colour, and a real light
## (PointLight2D) for everything the area says is shining right now.
##
## - The ambient colour tints everything in the area (a CanvasModulate): clear outdoors, a warm
##   dimness in a house, a cool one in a dungeon, near black in a `dark` area.
## - A POOL light shows what it reaches in its own colours (the engine's "mix" blend): two pools
##   that overlap don't glare, and a white pool undoes the dimness exactly.
## - A GLOW light adds its colour on top ("add"): the bloom round a flame, a lamp in daylight.
##
## In a dark area the pools are LightRules' lights and nothing else, drawn with a picture made
## from the rule's own falloff (`exact`), so what is drawn lit is what the rule says is lit.
## The area hands over its lights every frame (show_lights); fires flicker here.

const POOL: StringName = &"pool"
const GLOW: StringName = &"glow"

## By Ambience kind. Houses and dungeons are dim, never dark: an enemy is always easy to see.
const AMBIENT: Dictionary = {
	&"outdoor": Color(1.0, 1.0, 1.0),
	&"interior": Color(0.62, 0.55, 0.66),
	&"dungeon": Color(0.54, 0.54, 0.72),
}
## A `dark` area: a hint of the room stays, as it always has.
const DARK: Color = Color(0.06, 0.05, 0.11)
## The light pictures: their size (px across), and the look of a soft pool (how much of its
## reach is fully lit, and the steps it fades in). A rule's light uses LightRules.CORE.
const SIZE: int = 256
const SOFT_CORE: float = 0.2
const SOFT_STEPS: int = 10
const RULE_STEPS: int = 4
## The most lights at once. The engine lights one drawn thing with at most 16.
const MAX_LIGHTS: int = 14
## How much a flickering light breathes, and how fast.
const FLICKER: float = 0.06
const FLICKER_SPEED: float = 7.0

## The area's ambient colour.
var ambient: Color = Color.WHITE
## The lights last shown, as given (for tests).
var shown: Array = []

var _tint: CanvasModulate
var _nodes: Array[PointLight2D] = []
var _clock: float = 0.0

static var _pictures: Dictionary = {}


## One light: where (area px), how far it reaches, its colour, POOL or GLOW, how strong, whether
## it flickers, and whether it must match LightRules exactly (a dark area's pools).
static func light(at: Vector2, radius: float, color: Color, kind: StringName, strength: float = 1.0, flickers: bool = false, exact: bool = false) -> Dictionary:
	return {"at": at, "radius": radius, "color": color, "kind": kind, "strength": strength, "flickers": flickers, "exact": exact}


## How bright a light is at `share` of its radius (0 at its middle, 1 at its edge): full out to
## `core`, then fading in `steps` steps. Any light at all counts as the first step, so a light
## reaches exactly as far as LightRules says it does.
static func falloff(share: float, core: float, steps: int) -> float:
	var smooth: float = clampf((1.0 - share) / (1.0 - core), 0.0, 1.0)
	if steps <= 0:
		return smooth
	return ceilf(smooth * float(steps) - 0.0001) / float(steps)


## The picture of a light with that falloff: white, see-through by how dark it is there.
static func picture(core: float, steps: int) -> ImageTexture:
	var key: String = "%.3f/%d" % [core, steps]
	if _pictures.has(key):
		return _pictures[key]
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var middle: float = SIZE / 2.0
	for y: int in SIZE:
		for x: int in SIZE:
			var share: float = Vector2(x + 0.5 - middle, y + 0.5 - middle).length() / middle
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff(share, core, steps)))
	var made: ImageTexture = ImageTexture.create_from_image(image)
	_pictures[key] = made
	return made


## The ambient colour for a kind of place; a `dark` area is DARK whatever its kind.
static func ambient_for(kind: StringName, dark: bool) -> Color:
	return DARK if dark else AMBIENT.get(kind, Color.WHITE)


func _init() -> void:
	name = "Lighting"


## Sets the ambient colour for `kind` of place (Ambience), or for a `dark` one.
func setup(kind: StringName, dark: bool) -> void:
	ambient = ambient_for(kind, dark)
	if _tint == null:
		_tint = CanvasModulate.new()
		add_child(_tint)
	_tint.color = ambient


## Changes the ambient colour (outdoors it follows the hour).
func set_ambient(color: Color) -> void:
	if color == ambient:
		return
	ambient = color
	_tint.color = color


## Whether the ambient colour dims the area, so a pool of light shows.
func is_dim() -> bool:
	return ambient.v < 0.95


## Shows `lights` (AreaLighting.light dictionaries): those that reach `view` (area px), the
## widest first, at most MAX_LIGHTS.
func show_lights(lights: Array, view: Rect2) -> void:
	shown = LightRules.reaching(view, lights, MAX_LIGHTS)
	while _nodes.size() < shown.size():
		var node: PointLight2D = PointLight2D.new()
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(node)
		_nodes.append(node)
	for i: int in _nodes.size():
		var node: PointLight2D = _nodes[i]
		node.enabled = i < shown.size()
		if not node.enabled:
			continue
		var one: Dictionary = shown[i]
		var radius: float = float(one["radius"])
		var strength: float = float(one["strength"])
		if one["flickers"] and not one["exact"]:
			var breath: float = sin(_clock * FLICKER_SPEED + float(i) * 1.7) * 0.6 + sin(_clock * FLICKER_SPEED * 2.3 + float(i)) * 0.4
			radius *= 1.0 + FLICKER * breath
			strength *= 1.0 + FLICKER * breath
		node.position = (one["at"] as Vector2).round()
		node.texture = picture(LightRules.CORE, RULE_STEPS) if one["exact"] else picture(SOFT_CORE, SOFT_STEPS)
		node.texture_scale = radius * 2.0 / float(SIZE)
		node.color = one["color"]
		node.energy = strength
		node.blend_mode = Light2D.BLEND_MODE_MIX if one["kind"] == POOL else Light2D.BLEND_MODE_ADD


## The engine's lights that are on, in the order of `shown` (for tests).
func lit_nodes() -> Array[PointLight2D]:
	var out: Array[PointLight2D] = []
	for node: PointLight2D in _nodes:
		if node.enabled:
			out.append(node)
	return out


## How far the engine's light `node` reaches (area px): its picture's half-width, scaled.
static func reach_of(node: PointLight2D) -> float:
	return node.texture_scale * float(SIZE) / 2.0


func _process(delta: float) -> void:
	_clock += delta
