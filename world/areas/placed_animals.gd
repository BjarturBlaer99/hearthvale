class_name PlacedAnimals
extends Node
## The animals of the hero's land, where they are (the Homestead, phase 4; docs/TECH_DESIGN.md
## §30; the plan's D28). They keep the villagers' hours (Hours.villagers_out: 06:00 to 20:00):
## - **on the homestead**, by day, the animals of each building that has a pasture are out in it,
##   wandering among its cells;
## - **in a building's room** (the coop, the barn), the animals that live there and are not out:
##   all of them by night, and by day those whose building has no pasture.
## Nobody walks them anywhere: at 20:00 and at 06:00 they simply are where they belong. They block
## nobody and never use a door. Each is an Animal in the area's Interactables, sorted with the
## hero. This keeps them in step with the herd and the hour (EventBus.homestead_changed: an animal
## bought, a fence set down; EventBus.time_changed), and moves them on each frame, but not while
## build mode holds the world still.

var area: AreaController
## The building whose animals are shown here: &"" on the homestead (all of them that are out).
var room_of: StringName = &""

## Each animal shown, by its place in the herd.
var _shown: Dictionary[int, Animal] = {}
var _out: bool = false


func _init() -> void:
	name = "PlacedAnimals"


## Takes up the area it is in: the homestead, or the room of building `building` (else nothing
## lives here and nothing is shown).
func setup(area_controller: AreaController, building: StringName = &"") -> void:
	area = area_controller
	room_of = building
	_out = area.hours().villagers_out(GameState.minute)
	EventBus.homestead_changed.connect(sync)
	EventBus.time_changed.connect(_on_time_changed)
	sync()


func _exit_tree() -> void:
	if EventBus.homestead_changed.is_connected(sync):
		EventBus.homestead_changed.disconnect(sync)
	if EventBus.time_changed.is_connected(_on_time_changed):
		EventBus.time_changed.disconnect(_on_time_changed)


## Whether animals are out of doors at this hour.
func is_daytime() -> bool:
	return _out


## The animals shown here, in the herd's order.
func shown() -> Array[Animal]:
	var out: Array[Animal] = []
	var keys: Array[int] = _shown.keys()
	keys.sort()
	for i: int in keys:
		out.append(_shown[i])
	return out


## The animal shown here at its place `index` in the herd, or null.
func animal(index: int) -> Animal:
	return _shown.get(index)


## The animal the hero reaches facing `at` (the nearest one there), or null.
func animal_at(at: Vector2i) -> Animal:
	var best: Animal = null
	for one: Animal in shown():
		if one.reached_from(at) and (best == null or one.position.distance_to(GridBody.cell_center(at)) < best.position.distance_to(GridBody.cell_center(at))):
			best = one
	return best


## Whether an animal stands in `at` (build mode sets nothing standing on one).
func stands_in(at: Vector2i) -> bool:
	for one: Animal in shown():
		if one.cell() == at:
			return true
	return false


## Where each animal that is here now may walk, by its place in the herd: on the homestead its
## pasture's cells, in a room the room's floor.
func wanted() -> Dictionary:
	var out: Dictionary = {}
	if room_of == &"":
		if not _out:
			return out
		for id: StringName in GameState.homestead().building_ids():
			var herd: Array[int] = GameState.animals_in(id)
			if herd.is_empty():
				continue
			var pasture: Dictionary = GameState.pasture_of(id)
			if not Pasture.is_pasture(pasture):
				continue
			for i: int in herd:
				out[i] = pasture["cells"]
		return out
	if _out and GameState.has_pasture(room_of):
		return out
	var floor_cells: Array[Vector2i] = room_floor()
	for i: int in GameState.animals_in(room_of):
		out[i] = floor_cells
	return out


## The cells of the room an animal may stand in: open floor, not the doormat and not the row
## before it (so nobody stands in the hero's way as he comes in).
func room_floor() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var mat: Vector2i = Vector2i(-1, -1)
	for child: Node in area.interactables.get_children():
		if child is AreaExit:
			mat = (child as AreaExit).cell()
	for y: int in area.grid.size.y:
		for x: int in area.grid.size.x:
			var at: Vector2i = Vector2i(x, y)
			if area.grid.is_solid(at) or area.terrain.is_occupied(at) or at == mat or at == mat + Vector2i.UP:
				continue
			out.append(at)
	return out


## Brings the animals here in step with the herd and the hour: one that should be here and isn't
## is put on a cell of its own ground; one whose ground changed walks on the new ground; one that
## should no longer be here is gone.
func sync() -> void:
	if area == null:
		return
	var wanted_now: Dictionary = wanted()
	for i: int in _shown.keys():
		if not wanted_now.has(i):
			_shown[i].free()
			_shown.erase(i)
	var ground_used: Dictionary = {}
	for i: int in wanted_now:
		var cells: Array[Vector2i] = []
		cells.assign(wanted_now[i])
		if cells.is_empty():
			continue
		if _shown.has(i):
			_shown[i].motion.set_cells(cells)
			continue
		var one: Animal = Animal.new()
		one.setup(i, cells, _start_cell(cells, ground_used), area.rng)
		area.interactables.add_child(one)
		_shown[i] = one


## A cell of `cells` for the next animal put down, spread out from the others.
func _start_cell(cells: Array[Vector2i], used: Dictionary) -> Vector2i:
	var free: Array[Vector2i] = []
	for at: Vector2i in cells:
		if not used.has(at) and not stands_in(at):
			free.append(at)
	var from: Array[Vector2i] = free if not free.is_empty() else cells
	var start: Vector2i = from[area.rng.randi_range(0, from.size() - 1)]
	used[start] = true
	return start


func _on_time_changed(_day: int, _minute: int) -> void:
	var out: bool = area.hours().villagers_out(GameState.minute)
	if out != _out:
		_out = out
		sync()


func _process(delta: float) -> void:
	if area == null or area.is_building():
		return
	for one: Animal in _shown.values():
		one.walk(delta)
