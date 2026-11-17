class_name LadderHole
extends AreaExit
## A ladder down a shaft in the floor of the Old Quarry (2026-11-17): a way out that shows
## itself, where a door's tiles show an ordinary exit. One stands in the entrance hall; on a
## floor of the mine the area puts one where the day's rock hid it, once that rock is broken.
## Stepping onto it goes down. Position = its cell's top-left corner.


func _draw() -> void:
	SpriteSheet.draw(self, Rock.SHEET, int(Rock.FRAMES[&"ladder"]), Rock.SIZE, Vector2.ZERO)
