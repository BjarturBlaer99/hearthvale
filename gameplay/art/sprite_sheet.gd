class_name SpriteSheet
extends RefCounted
## Draws frames from the sprite strips of gameplay/art/ (docs/TECH_DESIGN.md §14). A strip holds
## its frames side by side, in the order art/sheets.json lists them, painted on the
## top row and as white silhouettes on the bottom row (for hit flashes). (Until the farm-look
## plan's phase D it also swapped the villagers' marker colours; each villager is a figure of
## their own now.)


## Draws frame `index` of `texture` (frames of `size` px) on `canvas`, its top-left at `origin`:
## mirrored left to right with `flip_h`, as a white silhouette with `white`, tinted by `tint`.
static func draw(canvas: CanvasItem, texture: Texture2D, index: int, size: Vector2i, origin: Vector2,
		flip_h: bool = false, white: bool = false, tint: Color = Color.WHITE) -> void:
	var source: Rect2 = Rect2(Vector2(index * size.x, size.y if white else 0), Vector2(size))
	canvas.draw_texture_rect_region(texture, target_of(origin, size, flip_h), source, tint)


## Where draw() puts a frame of `size` whose top-left is at `origin`: a rectangle with a negative
## width when `flip_h`, which this engine mirrors in place, over the same columns (measured in a
## window, 2026-11-19: until then the corner was moved a frame's width right first, and every
## mirrored creature stood a frame's width to the right of where it was).
static func target_of(origin: Vector2, size: Vector2i, flip_h: bool) -> Rect2:
	return Rect2(origin.round(), Vector2(-size.x if flip_h else size.x, size.y))
