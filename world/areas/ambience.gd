class_name Ambience
extends RefCounted
## What kind of place an area is, for its light and air (docs/TECH_DESIGN.md §6, art pass 4),
## read from its tiles so no scene has to say: outdoors under the sun, a house's inside by its
## hearth, or a dungeon. Also finds the tiles that give light (lamp posts, hearths, candles).
## AreaLighting turns the kind into an ambient colour and the glows into real lights (P1b).
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
## Areas with mist among the trees (P1c).
const MISTY: Array[StringName] = [&"old_wood"]
## The hero is always seen: how far the pool of light around them reaches where it is dim (px).
const HERO_POOL: float = 88.0
## Where it is dim, a glow's pool reaches this much further than the glow itself.
const REACH: float = 2.1


## A dungeon if it has an id; else a house's inside if it has inner walls; else outdoors.
static func kind_of(height_layer: TileMapLayer, dungeon_id: StringName) -> StringName:
	if dungeon_id != &"":
		return DUNGEON
	if height_layer != null and not height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("inner_wall")).is_empty():
		return INTERIOR
	return OUTDOOR


static func has_mist(area_id: StringName) -> bool:
	return MISTY.has(area_id)


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
