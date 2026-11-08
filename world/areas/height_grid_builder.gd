class_name HeightGridBuilder
extends RefCounted
## Reads an area's `Height` TileMapLayer into a HeightGrid (docs/TECH_DESIGN.md §3).
## The grid spans (0, 0) to the far corner of the painted area; unpainted cells inside it
## are open ground at height 0, and cells at negative coordinates are ignored.


static func from_layer(layer: TileMapLayer) -> HeightGrid:
	var used: Rect2i = layer.get_used_rect()
	var grid: HeightGrid = HeightGrid.new(Vector2i(maxi(used.end.x, 0), maxi(used.end.y, 0)))
	for cell: Vector2i in layer.get_used_cells():
		if not grid.in_bounds(cell):
			continue
		var data: TileData = layer.get_cell_tile_data(cell)
		if data == null:
			continue
		grid.set_height(cell, int(data.get_custom_data(GreyboxTiles.DATA_HEIGHT)))
		grid.set_ramp(cell, bool(data.get_custom_data(GreyboxTiles.DATA_RAMP)))
		grid.set_solid(cell, bool(data.get_custom_data(GreyboxTiles.DATA_SOLID)))
	return grid
