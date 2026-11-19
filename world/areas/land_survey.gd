class_name LandSurvey
extends RefCounted
## Reads the hero's land from its scene into a LandMap (the Homestead, phase 4;
## docs/TECH_DESIGN.md §30): what the map is before he has done anything to it. The scene is
## made but never added to the tree (nothing of it runs), read, and freed. GameState asks it once
## a run, whenever a pasture is first needed (a morning with animals, Oda's stall, the land).


## The land `area_id` as a LandMap: the Height layer's solid cells and path tiles, the cells of
## every way out (road), the field (its FarmPlot, the farm rules' size) and every spawn marker
## but the meadow's tall grass (the overgrowth). An empty map if the scene can't be read.
static func survey(area_id: StringName, plot_size: Vector2i) -> LandMap:
	var packed: PackedScene = load(WorldPaths.scene_for(area_id)) as PackedScene
	if packed == null:
		return LandMap.new()
	var scene: Node = packed.instantiate()
	var height: TileMapLayer = scene.get_node_or_null(^"Height") as TileMapLayer
	if height == null:
		scene.free()
		return LandMap.new()
	var grid: HeightGrid = HeightGridBuilder.from_layer(height)
	var solid: Array[Vector2i] = []
	var road: Array[Vector2i] = []
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			if grid.is_solid(cell):
				solid.append(cell)
			if height.get_cell_atlas_coords(cell).y == GreyboxTiles.ROW_PATH:
				road.append(cell)
	var interactables: Node = scene.get_node_or_null(^"Interactables")
	if interactables != null:
		for child: Node in interactables.get_children():
			var way_out: AreaExit = child as AreaExit
			if way_out == null:
				continue
			for dy: int in way_out.size.y:
				for dx: int in way_out.size.x:
					road.append(way_out.cell() + Vector2i(dx, dy))
	var debris: Array[Vector2i] = []
	var spawns: TileMapLayer = scene.get_node_or_null(^"Spawns") as TileMapLayer
	if spawns != null:
		for cell: Vector2i in spawns.get_used_cells():
			if GreyboxTiles.marker_kind(spawns.get_cell_atlas_coords(cell)) != "meadow_grass":
				debris.append(cell)
	var field: Rect2i = Rect2i()
	var plot: Node2D = scene.get_node_or_null(^"FarmPlot") as Node2D
	if plot != null:
		field = Rect2i(PlayerMotor.cell_of(plot.position + Vector2(0.5, 0.5)), plot_size)
	var land: LandMap = LandMap.new(grid.size, solid, road, debris, field)
	scene.free()
	return land
