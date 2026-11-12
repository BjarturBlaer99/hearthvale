class_name Ambience
extends RefCounted
## What kind of place an area is, for its light and air (docs/TECH_DESIGN.md §6, art pass 4),
## read from its tiles so no scene has to say: outdoors under the sun, a house's inside by its
## hearth, or a dungeon. Also finds the tiles that give light (lamp posts, hearths, candles).
## Pure but for reading the layers.

const OUTDOOR: StringName = &"outdoor"
const INTERIOR: StringName = &"interior"
const DUNGEON: StringName = &"dungeon"

const FIRE: Color = Color(1.0, 0.62, 0.26)
const CANDLE: Color = Color(1.0, 0.80, 0.45)
const LAMP: Color = Color(1.0, 0.88, 0.55)

## Tiles that give light: kind -> [where in the cell (px), how far it glows (px), colour,
## how strong the glow is drawn, whether it flickers].
const TILE_LIGHTS: Dictionary = {
	"hearth": [Vector2(8, 10), 46.0, FIRE, 0.42, true],
	"candle": [Vector2(8, 4), 26.0, CANDLE, 0.34, true],
	"prop_lamp": [Vector2(8, 3), 22.0, LAMP, 0.30, false],
}

## How many times bigger than life the camera shows each kind of place (P1a): rooms are small,
## so houses and dungeons are shown at twice the size. Whole numbers keep pixels square.
const ZOOM: Dictionary = {OUTDOOR: 1, INTERIOR: 2, DUNGEON: 2}
## How dim the unlit parts are (0: not at all), by kind.
const GLOOM: Dictionary = {OUTDOOR: 0.0, INTERIOR: 0.34, DUNGEON: 0.40}
## The hero is always seen: how far the light around them reaches in the gloom (px).
const HERO_POOL: float = 88.0
## A glow lights the gloom this much further than it is drawn.
const REACH: float = 2.1


## A dungeon if it has an id; else a house's inside if it has inner walls; else outdoors.
static func kind_of(height_layer: TileMapLayer, dungeon_id: StringName) -> StringName:
	if dungeon_id != &"":
		return DUNGEON
	if height_layer != null and not height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("inner_wall")).is_empty():
		return INTERIOR
	return OUTDOOR


## One glow: where (area px), how far, its colour, how strong, and whether it flickers.
static func glow(at: Vector2, radius: float, color: Color, strength: float, flickers: bool) -> Dictionary:
	return {"at": at, "radius": radius, "color": color, "strength": strength, "flickers": flickers}


## The glows of every light-giving tile on `layers` (the Height and Decor layers), in cell order.
static func tile_glows(layers: Array) -> Array:
	var out: Array = []
	for layer: Variant in layers:
		if not layer is TileMapLayer:
			continue
		for kind: String in TILE_LIGHTS:
			var spec: Array = TILE_LIGHTS[kind]
			var cells: Array[Vector2i] = (layer as TileMapLayer).get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind))
			cells.sort()
			for cell: Vector2i in cells:
				out.append(glow(Vector2(cell) * float(GreyboxTiles.TILE_SIZE) + spec[0], spec[1], spec[2], spec[3], spec[4]))
	return out


## The lights (LightRules) that `glows` cast into the gloom.
static func lights_of(glows: Array) -> Array:
	var out: Array = []
	for one: Dictionary in glows:
		out.append(LightRules.light(one["at"], float(one["radius"]) * REACH))
	return out
