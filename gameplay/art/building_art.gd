class_name BuildingArt
extends RefCounted
## How a building of the hero's land is drawn (the Homestead, phase 3; docs/TECH_DESIGN.md
## §30): as the farmhouse is, which is the village's own house tiles laid on its map. A
## building's look (Buildings.look_of) names those tiles, and the few of its own (the site, the
## barn's planks and doors, the silo), all painted by tools/greybox/make_tile_texture.gd into
## the one atlas; they are drawn flat on the ground, under everyone, with the shadow a tall
## thing casts east and south (HeightShading's), and a roof's ridge rises over its top row as a
## strip that the hero walks behind (Scenery's, ReliefAtlas). A site is one picture: dug ground
## pegged out over its cells, and its stack of timber.

const T: float = float(GreyboxTiles.TILE_SIZE)
## The shadow a tall thing casts on the ground (HeightShading's numbers).
const CAST: float = HeightShading.CAST

static var _atlas: Texture2D
static var _relief: Texture2D


static func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(GreyboxTiles.TEXTURE_PATH)
	return _atlas


static func relief() -> Texture2D:
	if _relief == null:
		_relief = load(ReliefAtlas.TEXTURE_PATH)
	return _relief


## The tiles to draw for `building` (a data entry): its look (or its upgrade's, `big`), or a
## site's. cell (from its top-left) -> GreyboxTiles kind.
static func tiles(building: Dictionary, big: bool, site: bool) -> Dictionary:
	return Buildings.site_tiles(Buildings.size_of(building)) if site else Buildings.tiles_of(Buildings.look_of(building, big))


## Draws `building` on `canvas` with its top-left corner at `origin` (px): its shadow (unless
## `shadow` is false, or its data says it casts none), its tiles and decorations, tinted by
## `tint`. The ridge is drawn here too only with `ridge` (the ghost's); in the world it is a
## strip of the area's scenery.
static func draw(canvas: CanvasItem, building: Dictionary, origin: Vector2, big: bool = false, site: bool = false,
		tint: Color = Color.WHITE, shadow: bool = true, ridge: bool = false) -> void:
	var size: Vector2 = Vector2(Buildings.size_of(building)) * T
	if shadow and Buildings.casts_shadow(building) and not site:
		draw_shadow(canvas, origin, size, tint.a)
	var laid: Dictionary = tiles(building, big, site)
	for cell: Vector2i in laid:
		draw_tile(canvas, str(laid[cell]), origin + Vector2(cell) * T, tint)
	if not site:
		var decor: Dictionary = Buildings.decor_of(Buildings.look_of(building, big))
		for cell: Vector2i in decor:
			draw_tile(canvas, str(decor[cell]), origin + Vector2(cell) * T, tint)
		if ridge:
			for strip: Dictionary in ridges(building, big):
				canvas.draw_texture_rect_region(relief(), Rect2(origin + strip["at"], Vector2(ReliefAtlas.RIDGE_SIZE)), strip["region"], tint)


## Draws the atlas tile `kind` on `canvas` with its top-left at `at`.
static func draw_tile(canvas: CanvasItem, kind: String, at: Vector2, tint: Color = Color.WHITE) -> void:
	var coords: Vector2i = GreyboxTiles.coords(kind)
	canvas.draw_texture_rect_region(atlas(), Rect2(at.round(), Vector2(T, T)), Rect2(Vector2(coords) * T, Vector2(T, T)), tint)


## The shadow a tall thing of `size` (px) at `origin` casts: a band along its south side, one
## down its east side and the corner between, each darker nearest it (HeightShading's look).
static func draw_shadow(canvas: CanvasItem, origin: Vector2, size: Vector2, strength: float = 1.0) -> void:
	var far: Color = Color(HeightShading.SHADE_FAR, HeightShading.SHADE_FAR.a * strength)
	var near: Color = Color(HeightShading.SHADE_NEAR, HeightShading.SHADE_NEAR.a * strength)
	var half: float = CAST / 2.0
	canvas.draw_rect(Rect2(origin + Vector2(0.0, size.y), Vector2(size.x, CAST)), far)
	canvas.draw_rect(Rect2(origin + Vector2(0.0, size.y), Vector2(size.x, half)), near)
	canvas.draw_rect(Rect2(origin + Vector2(size.x, 0.0), Vector2(CAST, size.y)), far)
	canvas.draw_rect(Rect2(origin + Vector2(size.x, 0.0), Vector2(half, size.y)), near)
	canvas.draw_rect(Rect2(origin + size, Vector2(CAST, CAST)), far)
	canvas.draw_rect(Rect2(origin + size, Vector2(half, half)), near)


## The strips of ridge over `building`'s roof: for each cell of a roof's top row with no roof
## above it, { "cell": its cell (from the top-left), "at": where the strip's top-left is (px,
## from the building's top-left), "region": its picture in the relief atlas }.
static func ridges(building: Dictionary, big: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var laid: Dictionary = Buildings.tiles_of(Buildings.look_of(building, big))
	for cell: Vector2i in laid:
		var ridge: Array = ReliefAtlas.ridge_of(str(laid[cell]))
		if ridge.is_empty() or Scenery.is_roof(str(laid.get(cell + Vector2i.UP, ""))):
			continue
		out.append({"cell": cell, "at": Vector2(cell) * T + Vector2(0.0, -float(ReliefAtlas.RIDGE_SIZE.y)),
			"region": ReliefAtlas.ridge(ridge[0], ridge[1])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["cell"] as Vector2i).x < (b["cell"] as Vector2i).x)
	return out
