class_name WaterSurface
extends Node2D
## The moving surface of an area's water (P1c): over the water tiles, under the lily pads.
## Thin glints of light drift across it, a few sparkles come and go, and foam laps at the bank,
## wider and narrower with the swell. A shader draws it from a small map of which cells are
## water (one pixel a cell), in whole pixels. For show only.
## Since the farm-look plan's phase A the bank itself is a picture (earth, then a line of foam:
## HeightShading draws it over this, BANK pixels deep), so the foam here laps on from where that
## picture ends, and the colours are the art pack's water.

const CODE: String = """
shader_type canvas_item;
uniform sampler2D cells : filter_nearest, repeat_disable;
uniform vec2 map_cells = vec2(1.0);
uniform vec4 glint : source_color = vec4(0.56, 0.94, 0.95, 0.9);
uniform vec4 foam : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform vec4 deep : source_color = vec4(0.475, 0.722, 0.808, 0.45);
uniform float bank = 4.0;
varying vec2 at;

void vertex() {
	at = VERTEX;
}

float wet(vec2 p) {
	vec2 cell = floor(p / 16.0);
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= map_cells.x || cell.y >= map_cells.y) {
		return 1.0;
	}
	return texture(cells, (cell + 0.5) / map_cells).r;
}

void fragment() {
	vec2 p = floor(at);
	if (wet(p) < 0.5) {
		discard;
	}
	vec4 colour = vec4(0.0);
	// A slow swell: broad bands a shade deeper, sliding by.
	float swell = sin(p.y * 0.21 + p.x * 0.07 + TIME * 0.5);
	if (swell > 0.55) {
		colour = deep;
	}
	// Glints: short bright dashes that drift along the rows.
	float row = sin(p.y * 1.7 + floor(p.y / 3.0) * 2.1);
	float along = sin(p.x * 0.45 + TIME * 0.9 + floor(p.y / 3.0) * 1.9);
	if (row > 0.86 && along > 0.82) {
		colour = glint;
	}
	// Sparkles: single pixels that blink.
	float spark = fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
	if (spark > 0.992 && sin(TIME * 2.0 + spark * 400.0) > 0.6) {
		colour = vec4(1.0, 1.0, 1.0, 0.9);
	}
	// Foam at the bank: one to three pixels wide past the bank's own picture, breathing with
	// the swell.
	float reach = bank + 1.0 + floor(1.5 + 1.5 * sin(TIME * 1.3 + (p.x + p.y) * 0.19));
	float edge = 99.0;
	for (int d = 1; d <= 7; d++) {
		float f = float(d);
		if (wet(p + vec2(f, 0.0)) < 0.5 || wet(p - vec2(f, 0.0)) < 0.5 || wet(p + vec2(0.0, f)) < 0.5 || wet(p - vec2(0.0, f)) < 0.5) {
			edge = f;
			break;
		}
	}
	if (edge <= reach) {
		float broken = fract(sin(dot(floor(p / vec2(2.0, 1.0)), vec2(41.3, 17.7))) * 9731.1);
		if (edge <= bank + 1.0 || broken > 0.35) {
			colour = foam;
		}
	}
	COLOR = colour;
}
"""

## How deep the bank's picture lies over the water's edge (px): the shader's `bank`.
const BANK: float = 4.0

## The rectangle of the area that holds water (area px).
var bounds: Rect2 = Rect2()
## The water cells.
var cells: Array[Vector2i] = []


## A surface for the water cells of `layer` (the Height layer), or null if it has none.
static func make(layer: TileMapLayer, map_cells: Vector2i) -> WaterSurface:
	var water: Array[Vector2i] = layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("water"))
	if water.is_empty():
		return null
	var surface: WaterSurface = WaterSurface.new()
	surface.name = "WaterSurface"
	surface.cells = water
	var image: Image = Image.create(map_cells.x, map_cells.y, false, Image.FORMAT_R8)
	var box: Rect2i = Rect2i(water[0], Vector2i.ONE)
	for cell: Vector2i in water:
		image.set_pixelv(cell, Color(1, 0, 0))
		box = box.expand(cell).expand(cell + Vector2i.ONE)
	surface.bounds = Rect2(box.position * GreyboxTiles.TILE_SIZE, box.size * GreyboxTiles.TILE_SIZE)
	var shader: Shader = Shader.new()
	shader.code = CODE
	var look: ShaderMaterial = ShaderMaterial.new()
	look.shader = shader
	look.set_shader_parameter(&"cells", ImageTexture.create_from_image(image))
	look.set_shader_parameter(&"map_cells", Vector2(map_cells))
	look.set_shader_parameter(&"bank", BANK)
	surface.material = look
	return surface


func _draw() -> void:
	draw_rect(bounds, Color.WHITE)
