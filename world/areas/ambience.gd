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
## Where a marsh lantern hangs in its cell (px), and how far its light gives a Bogwisp a body
## (px): a little less than the Lantern the hero carries.
const LANTERN_AT: Vector2 = Vector2(10, 7)
const LANTERN_HOLD: float = 44.0

## Tiles that give light: kind -> [where in the cell (px), how far it glows (px), colour,
## how strong the glow is drawn, whether it flickers].
const TILE_LIGHTS: Dictionary = {
	"hearth": [Vector2(8, 10), 46.0, FIRE, 0.42, true],
	"candle": [Vector2(8, 4), 26.0, CANDLE, 0.34, true],
	"prop_lamp": [Vector2(8, 3), 22.0, LAMP, 0.30, false],
	"prop_marsh_lantern_lit": [LANTERN_AT, 24.0, LAMP, 0.32, true],
}

## How many times bigger than life the camera shows each kind of place (P1a): rooms are small,
## so houses and dungeons are shown at twice the size. Whole numbers keep pixels square.
## The tile lights that are lit only from dusk to dawn (DayClock.lamps_lit): street lamps.
## A fire or a candle burns at any hour.
const LIT_AT_DUSK: Array[String] = ["prop_lamp", "prop_marsh_lantern_lit"]
const ZOOM: Dictionary = {OUTDOOR: 1, INTERIOR: 2, DUNGEON: 2}
## Areas with mist among the trees (P1c).
const MISTY: Array[StringName] = [&"old_wood", &"willowmere"]
## Areas whose fireflies keep out of sight until the lamps are lit (Willowmere: "fireflies at
## dusk"). The Old Wood's are out at every hour, as they always were.
const DUSK_FIREFLIES: Array[StringName] = [&"willowmere"]
## How thick an area's mist gets at night, where that is thicker than by day (Willowmere: "the
## mist thickens"). The mist still lies where it lies: it thickens, it doesn't drift.
const NIGHT_MIST: Dictionary = {&"willowmere": 0.36}
## The hero is always seen: how far the pool of light around them reaches where it is dim (px).
const HERO_POOL: float = 88.0
## Where it is dim, a glow's pool reaches this much further than the glow itself.
const REACH: float = 2.1


## A dungeon if it has an id, or lies underground (the mine: shown and lit as one); else a
## house's inside if it has inner walls; else outdoors.
static func kind_of(height_layer: TileMapLayer, dungeon_id: StringName, underground: bool = false) -> StringName:
	if dungeon_id != &"" or underground:
		return DUNGEON
	if height_layer != null and not height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("inner_wall")).is_empty():
		return INTERIOR
	return OUTDOOR


static func has_mist(area_id: StringName) -> bool:
	return MISTY.has(area_id)


static func fireflies_wait_for_dusk(area_id: StringName) -> bool:
	return DUSK_FIREFLIES.has(area_id)


## Where the burning marsh lanterns on `layer` (the Decor layer) hang, in area px and cell order.
static func lantern_points(layer: TileMapLayer) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if layer == null:
		return out
	var cells: Array[Vector2i] = layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(GreyboxTiles.LANTERN_LIT))
	cells.sort()
	for cell: Vector2i in cells:
		out.append(Vector2(cell) * float(GreyboxTiles.TILE_SIZE) + LANTERN_AT)
	return out


## Puts a burning lantern in the place of every dark one on `layer` (the Decor layer). Returns
## how many it lit.
static func light_lanterns(layer: TileMapLayer) -> int:
	if layer == null:
		return 0
	var cells: Array[Vector2i] = layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(GreyboxTiles.LANTERN_DARK))
	for cell: Vector2i in cells:
		layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(GreyboxTiles.LANTERN_LIT))
	return cells.size()


## How thick the mist of `area_id` is at most, by day or by `night`.
static func mist_thickness(area_id: StringName, night: bool) -> float:
	return float(NIGHT_MIST.get(area_id, Mist.THICKEST)) if night else Mist.THICKEST


## One glow: where (area px), how far, its colour, how strong, whether it flickers, and
## whether it waits for dusk to be lit (a street lamp).
static func glow(at: Vector2, radius: float, color: Color, strength: float, flickers: bool, at_dusk: bool = false) -> Dictionary:
	return {"at": at, "radius": radius, "color": color, "strength": strength, "flickers": flickers, "at_dusk": at_dusk}


## Those of `glows` that shine when lamps are `lamps_lit` or not: one that waits for dusk is
## left out by day.
static func shining(glows: Array, lamps_lit: bool) -> Array:
	var out: Array = []
	for one: Dictionary in glows:
		if lamps_lit or not one.get("at_dusk", false):
			out.append(one)
	return out


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
				out.append(glow(Vector2(cell) * float(GreyboxTiles.TILE_SIZE) + spec[0], spec[1], spec[2], spec[3], spec[4], LIT_AT_DUSK.has(kind)))
	return out
