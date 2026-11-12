class_name Reflections
extends Node2D
## Reflections on the water (P1c): the hero and the trees by the bank, upside down under their
## feet, tinted by the water and broken by its ripples. Each is a mirror picture hanging below
## the thing it mirrors; a shader shows it only where there is water (the same one-pixel-a-cell
## map the water's surface uses), so nothing has to know where the bank is. Drawn over the
## water and under everything that stands. For show only.

## How far south of a tree water must be for its mirror to be worth making (cells).
const REACH: int = 3
const CODE: String = """
shader_type canvas_item;
uniform sampler2D cells : filter_nearest, repeat_disable;
uniform vec2 map_cells = vec2(1.0);
uniform vec4 water : source_color = vec4(0.20, 0.42, 0.72, 1.0);
uniform float strength = 0.45;
varying vec2 at;

void vertex() {
	at = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(at);
	vec2 cell = floor(p / 16.0);
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= map_cells.x || cell.y >= map_cells.y) {
		discard;
	}
	if (texture(cells, (cell + 0.5) / map_cells).r < 0.5) {
		discard;
	}
	// The ripples break it up: one row in five is missing, and the gaps drift.
	if (mod(p.y + floor(TIME * 2.5), 5.0) < 1.0) {
		discard;
	}
	COLOR = vec4(mix(COLOR.rgb, water.rgb, 0.4), COLOR.a * strength);
}
"""

## The hero's mirror, and the trees' (by the tree's cell).
var hero: Sprite2D
var trees: Dictionary[Vector2i, Sprite2D] = {}

var _look: ShaderMaterial


## Mirrors for the water of `surface`: one for the hero, and one for each tree of `scenery`
## that stands within REACH cells north of water.
func setup(surface: WaterSurface, scenery: Scenery) -> void:
	name = "Reflections"
	var shader: Shader = Shader.new()
	shader.code = CODE
	_look = ShaderMaterial.new()
	_look.shader = shader
	_look.set_shader_parameter(&"cells", surface.material.get(&"shader_parameter/cells"))
	_look.set_shader_parameter(&"map_cells", surface.material.get(&"shader_parameter/map_cells"))
	var wet: Dictionary = {}
	for cell: Vector2i in surface.cells:
		wet[cell] = true
	for cell: Vector2i in scenery.by_cell:
		if not near_water(cell, wet):
			continue
		var tree: Sprite2D = scenery.by_cell[cell]
		var mirror: Sprite2D = _mirror()
		mirror.texture = tree.texture
		mirror.region_rect = tree.region_rect
		mirror.offset = Vector2(-SceneryAtlas.FOOT.x, -(SceneryAtlas.SIZE.y - 1.0 - SceneryAtlas.FOOT.y))
		mirror.position = tree.position
		trees[cell] = mirror
	hero = _mirror()
	hero.offset = Vector2(-PlayerAnimator.FRAME_SIZE.x / 2.0, 0.0)


## Whether water lies within REACH cells south of `cell`, straight down or one cell to a side.
static func near_water(cell: Vector2i, wet: Dictionary) -> bool:
	for dy: int in range(1, REACH + 1):
		for dx: int in [-1, 0, 1]:
			if wet.has(cell + Vector2i(dx, dy)):
				return true
	return false


## Keeps the hero's mirror under their feet, showing the same frame the same way round.
func follow(player: PlayerController) -> void:
	hero.texture = player.sheet()
	hero.region_rect = player.shown_region()
	hero.flip_h = player.shown_flipped()
	hero.position = player.position.round()
	hero.visible = not player.is_falling()


func _mirror() -> Sprite2D:
	var mirror: Sprite2D = Sprite2D.new()
	mirror.centered = false
	mirror.region_enabled = true
	mirror.flip_v = true
	mirror.material = _look
	add_child(mirror)
	return mirror
