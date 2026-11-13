class_name WindowGlow
extends Node2D
## Lit windows (P2e, GDD §6): from dusk to dawn the glass of every house window glows warm,
## however dark the night around it (it is drawn unshaded, so the hour's light doesn't dim it).
## Made at load from the window tiles of the Height layer, drawn just above it, so the hero and
## the trees pass in front. The area says when (set_lit, with the lamps). For show only.

## Each window tile (GreyboxTiles kind) and where its glass is in the tile (px).
const GLASS: Dictionary = {
	"wall_window": Rect2i(5, 5, 6, 4),
	"wall_upper_window": Rect2i(5, 4, 6, 7),
}
const LIGHT: Color = Color(1.0, 0.80, 0.42, 0.88)
const HALO: Color = Color(1.0, 0.74, 0.36, 0.22)

## The glass of every window, in area px.
var windows: Array[Rect2] = []
var lit: bool = false


## The glow for the windows of `layer`, or null if it has none.
static func make(layer: TileMapLayer) -> WindowGlow:
	var glow: WindowGlow = WindowGlow.new()
	glow.name = "WindowGlow"
	for kind: String in GLASS:
		var cells: Array[Vector2i] = layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind))
		cells.sort()
		for cell: Vector2i in cells:
			var glass: Rect2i = GLASS[kind]
			glow.windows.append(Rect2(Vector2(cell * GreyboxTiles.TILE_SIZE + glass.position), Vector2(glass.size)))
	if glow.windows.is_empty():
		glow.free()
		return null
	var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = unshaded
	return glow


## Lights the windows, or puts them out.
func set_lit(now: bool) -> void:
	if now == lit:
		return
	lit = now
	queue_redraw()


func _draw() -> void:
	if not lit:
		return
	for glass: Rect2 in windows:
		draw_rect(glass.grow(1.0), HALO)
		draw_rect(glass, LIGHT)
