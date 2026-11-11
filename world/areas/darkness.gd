class_name Darkness
extends Node2D
## The dark of an unlit area (docs/TECH_DESIGN.md §6): a sheet of black over the tiles and
## actors (below the room mask and the HUD), with holes where light reaches. The area gives it
## the lights every frame; a shader draws them by LightRules' rule (full to CORE of a light's
## radius, fading to its edge, the brightest light counting), in a few steps like the pixel
## art. Made in code, shader and all.

## The most lights drawn at once (LightRules.reaching picks them).
const MAX_LIGHTS: int = 12
const SHADE: Color = Color(0.03, 0.02, 0.06)
## How black full darkness is: a hint of the room stays.
const DEPTH: float = 0.95
## Steps between dark and lit.
const STEPS: int = 4

const SHADER_CODE: String = """
shader_type canvas_item;
uniform vec3 lights[12];
uniform int count = 0;
uniform vec3 shade = vec3(0.03, 0.02, 0.06);
uniform float depth = 0.95;
uniform float core = 0.55;
uniform float steps = 4.0;
varying vec2 at;

void vertex() {
	at = VERTEX;
}

void fragment() {
	vec2 point = floor(at) + vec2(0.5);
	float best = 0.0;
	for (int i = 0; i < 12; i++) {
		if (i >= count) {
			break;
		}
		float reach = distance(point, lights[i].xy) / max(lights[i].z, 0.001);
		best = max(best, clamp((1.0 - reach) / (1.0 - core), 0.0, 1.0));
	}
	best = floor(best * steps + 0.5) / steps;
	COLOR = vec4(shade, depth * (1.0 - best));
}
"""

## The part of the area it covers (area pixels): the room on screen.
var rect: Rect2 = Rect2()
## The lights it last drew, as given (for tests).
var shown: Array = []

var _material: ShaderMaterial


func _init() -> void:
	z_index = 40
	var shader: Shader = Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter(&"shade", Vector3(SHADE.r, SHADE.g, SHADE.b))
	_material.set_shader_parameter(&"depth", DEPTH)
	_material.set_shader_parameter(&"core", LightRules.CORE)
	_material.set_shader_parameter(&"steps", float(STEPS))
	material = _material


## A different dark: its colour, how black it gets, the steps from dark to lit, and how much
## of a light's reach is fully lit. The gloom of houses and dungeons is a soft one.
func set_look(shade: Color, depth: float, steps: int, core: float) -> void:
	_material.set_shader_parameter(&"shade", Vector3(shade.r, shade.g, shade.b))
	_material.set_shader_parameter(&"depth", depth)
	_material.set_shader_parameter(&"steps", float(steps))
	_material.set_shader_parameter(&"core", core)


## Covers `area_rect` in darkness, less what `lights` (LightRules lights) reach.
func show_lights(lights: Array, area_rect: Rect2) -> void:
	shown = LightRules.reaching(area_rect, lights, MAX_LIGHTS)
	var packed: PackedVector3Array = PackedVector3Array()
	packed.resize(MAX_LIGHTS)
	for i: int in shown.size():
		var at: Vector2 = (shown[i] as Dictionary)["at"]
		packed[i] = Vector3(at.x, at.y, float((shown[i] as Dictionary)["radius"]))
	_material.set_shader_parameter(&"lights", packed)
	_material.set_shader_parameter(&"count", shown.size())
	if area_rect != rect:
		rect = area_rect
		queue_redraw()


func _draw() -> void:
	draw_rect(rect, Color.WHITE)
