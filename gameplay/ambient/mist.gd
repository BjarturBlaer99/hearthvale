class_name Mist
extends Node2D
## Mist among the trees (P1c): two layers of pale cloud lying over the Old Wood, in a few flat
## steps like the rest of the art. It lies still (it drifted until 2026-11-13). It follows the
## camera but is pinned to the world, so walking doesn't drag it along. Above the hero, under
## the HUD. For show only.

## How thick it gets at most, and the patch it covers round the camera (px).
const THICKEST: float = 0.20
const COVER: Vector2 = Vector2(704, 424)
const CODE: String = """
shader_type canvas_item;
uniform sampler2D cloud : repeat_enable, filter_linear;
uniform float thickest = 0.2;
uniform vec4 tint : source_color = vec4(0.86, 0.91, 0.97, 1.0);
varying vec2 at;

void vertex() {
	at = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(at / 2.0) * 2.0;
	float near = texture(cloud, p / 320.0).r;
	float far = texture(cloud, p / 520.0 + vec2(0.37, 0.61)).r;
	float thick = clamp((near * 0.6 + far * 0.6 - 0.42) * 2.2, 0.0, 1.0);
	thick = floor(thick * 4.0 + 0.5) / 4.0;
	COLOR = vec4(tint.rgb, thick * thickest);
}
"""


func _init() -> void:
	name = "Mist"
	z_index = 34
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	var cloud: NoiseTexture2D = NoiseTexture2D.new()
	cloud.width = 256
	cloud.height = 256
	cloud.seamless = true
	cloud.noise = noise
	var shader: Shader = Shader.new()
	shader.code = CODE
	var look: ShaderMaterial = ShaderMaterial.new()
	look.shader = shader
	look.set_shader_parameter(&"cloud", cloud)
	look.set_shader_parameter(&"thickest", THICKEST)
	material = look


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera != null:
		position = (camera.get_screen_center_position() - COVER * 0.5).floor()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, COVER), Color.WHITE)
