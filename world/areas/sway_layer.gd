class_name SwayLayer
extends RefCounted
## Wind in the small things (P1c): tufts of grass, flowers, crops and washing move off the Decor
## layer onto a layer of their own, whose shader leans each tile's top rows a pixel to and fro,
## each cell in its own time. Whole pixels only, and never past the tile's own edge. For show.

## The Decor kinds (GreyboxTiles) that the wind moves.
const KINDS: Array[String] = ["tuft", "flowers_red", "flowers_yellow", "flowers_blue", "crops", "laundry"]
const CODE: String = """
shader_type canvas_item;
varying vec2 at;
varying vec4 tint;

void vertex() {
	at = VERTEX;
	tint = COLOR;
}

void fragment() {
	vec2 cell = floor(at / 16.0);
	float up = 1.0 - fract(at.y / 16.0);
	float gust = sin(TIME * 1.6 + cell.x * 1.3 + cell.y * 0.7) + 0.5 * sin(TIME * 2.9 + cell.x * 0.6);
	float shift = floor(gust * 0.9 * up + 0.5);
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	vec2 corner = floor(pixel / 16.0) * 16.0;
	float x = clamp(pixel.x - corner.x + shift, 0.5, 15.5);
	COLOR = texture(TEXTURE, vec2(corner.x + x, pixel.y) * TEXTURE_PIXEL_SIZE) * tint;
}
"""


## Moves the swaying tiles of `decor` onto a new layer just above it. Returns that layer (with
## no tiles if nothing sways here), or null without a Decor layer.
static func take_from(decor: TileMapLayer) -> TileMapLayer:
	if decor == null:
		return null
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "Sway"
	layer.tile_set = decor.tile_set
	var moving: Dictionary = {}
	for kind: String in KINDS:
		moving[GreyboxTiles.coords(kind)] = true
	for cell: Vector2i in decor.get_used_cells():
		var coords: Vector2i = decor.get_cell_atlas_coords(cell)
		if moving.has(coords):
			layer.set_cell(cell, GreyboxTiles.SOURCE_ID, coords)
			decor.erase_cell(cell)
	var shader: Shader = Shader.new()
	shader.code = CODE
	var look: ShaderMaterial = ShaderMaterial.new()
	look.shader = shader
	layer.material = look
	return layer
