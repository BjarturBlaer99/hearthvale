extends RefCounted
## Helpers for area scene tests: load areas one at a time, and walk the hero until they take
## an exit (without changing the real scene).


## Frees `previous` (if any), then loads the area at `path` into the running tree. Its _ready
## has run when this returns. The caller frees the last one.
static func load_area(path: String, previous: Node = null) -> AreaController:
	if previous != null and is_instance_valid(previous):
		previous.free()
	var area: AreaController = (load(path) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(area)
	return area


## Walks the hero one way, a frame's worth at a time, until the area asks to change scene.
## Returns that scene's path, or "" if the hero never left.
static func walk_until_travel(area: AreaController, direction: Vector2, max_steps: int = 240) -> String:
	var travelled: Array[String] = []
	area.travel = func(path: String) -> void: travelled.append(path)
	for i: int in max_steps:
		area.player.motor.step(direction, 1.0 / 60.0)
		if not travelled.is_empty():
			return travelled[0]
	return ""


## Puts the hero in the cell below the named Interactables child, facing up at it.
static func stand_before(area: AreaController, node_name: String) -> Talkable:
	var talkable: Talkable = area.interactables.get_node(NodePath(node_name))
	area.player.motor.place(talkable.cell() + Vector2i.DOWN)
	area.player.face(Vector2.UP)
	return talkable
