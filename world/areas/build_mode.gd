class_name BuildMode
extends Node2D
## Build mode (the Homestead, phase 2; docs/TECH_DESIGN.md §30; the plan's D12): a screen, as
## a menu is, in which the hero sets things down on his land, moves them and takes them up
## again. The area opens it (B, on the homestead only) and keeps him still, and the clock with
## him, while it is open (`is_in_menu()`).
## - The mouse points at a cell, and the movement keys move the ghost a cell at a time. Only
##   what is on screen can be built on: the ghost stops at the edge of the view.
## - The ghost shows the thing chosen, green where it fits and red where it doesn't, and a
##   line of words says why (Placement.why_not; the area's HUD shows them).
## - A left click (or the sword's key) sets it down and takes one from the pack. A right click
##   (or the item's key) takes up what is under the ghost, into the pack: what stands there
##   before what lies there.
## - With the hand chosen, a left click lifts the thing under the ghost and the next sets it
##   down elsewhere, as it is (a sapling keeps its mornings). It is not in the pack meanwhile:
##   it stays where it was until it is set down, so leaving, or a right click, puts it back.
## - The wheel steps along the build bar, which takes the item bar's place, and the keys 1 to
##   9 choose on it (BuildBar: the hand first, then what he carries).
## - Tab, Esc or B leave.
## - A building's kit (the Homestead, phase 3) is set down the same way: its ghost covers every
##   cell of the building and the doorstep before its door, held by its door (or the middle of
##   its bottom row), green or red over all of them with the first reason found (the plan's
##   D15). Set down, it is a building site today and the building the next morning.
## Placement (pure) says what fits; GameState sets down, moves and takes up; PlacedThings
## and PlacedBuildings show it. This is the only place anything is set down from: in play the
## mouse is two buttons, as ever, and where a click lands doesn't matter.

signal closed

## The ghost's colours: where the thing fits, where it doesn't, and the hand with nothing to do.
const FITS: Color = Color(0.42, 1.0, 0.52)
const REFUSED: Color = Color(1.0, 0.36, 0.30)
const POINTER: Color = Color(1.0, 0.93, 0.70)
## How solid the ghost's picture, its cell's wash and its outline are drawn.
const PICTURE_ALPHA: float = 0.78
const WASH_ALPHA: float = 0.24
const EDGE_ALPHA: float = 0.95
## The words under the ghost: the thing chosen and how many he carries; and for the hand, with
## nothing under it, with a thing under it (its name), and with a thing lifted, over where it
## was and over a place it fits.
const CHOSEN_WORDS: String = "%s x%d"
const HAND_WORDS: String = "The hand lifts a thing to move it."
const LIFT_WORDS: String = "Lift the %s"
const BACK_WORDS: String = "Put the %s back"
const MOVE_WORDS: String = "Set the %s down here"
## What is said when a thing is taken up (its name).
const TAKEN_UP_WORDS: String = "Taken up: %s."
## The ghost is drawn over the world and under the HUD, in the world's own coordinates, clear
## of the night's tint (a layer of its own that follows the camera).
const GHOST_LAYER: int = 1

var area: AreaController
## What is chosen on the bar: BuildBar.HAND, or the id of a placeable he carries. (&"" until
## the mode has been opened once.)
var chosen: StringName = &""
## The cell the ghost is on.
var cell: Vector2i = Vector2i.ZERO
## What the hand has lifted: { "cell": where it is, "layer", "item": its id }, or {}.
var lifted: Dictionary = {}

var _open: bool = false
var _layer: CanvasLayer
var _ghost: Node2D


func _init() -> void:
	name = "BuildMode"


## Takes up the area it builds in.
func setup(area_controller: AreaController) -> void:
	area = area_controller
	_layer = CanvasLayer.new()
	_layer.name = "GhostLayer"
	_layer.layer = GHOST_LAYER
	_layer.follow_viewport_enabled = true
	add_child(_layer)
	_ghost = Node2D.new()
	_ghost.name = "Ghost"
	_ghost.visible = false
	_ghost.draw.connect(_draw_ghost)
	_layer.add_child(_ghost)


## Opens the mode with the ghost on the cell the hero faces, and what was chosen last time
## chosen still, if it is still on the bar (else the first thing he carries to set down).
func open() -> void:
	if _open:
		return
	_open = true
	chosen = BuildBar.opening(entries(), chosen)
	cell = in_view(area.player.front_cell())
	_ghost.visible = true
	EventBus.sound.emit(&"menu_select")
	_refresh()


## Leaves the mode. A thing the hand had lifted is where it was.
func close() -> void:
	if not _open:
		return
	_open = false
	lifted = {}
	_ghost.visible = false
	area.hud.hide_build()
	EventBus.sound.emit(&"menu_select")
	closed.emit()


func is_open() -> bool:
	return _open


## What is on the build bar: the hand, then every placeable he carries (item data entries).
func entries() -> Array[Dictionary]:
	return BuildBar.entries(GameState.inventory, DataRegistry.entries(&"items"))


## Whether the hand is chosen.
func is_hand() -> bool:
	return chosen == BuildBar.HAND


## The data of the placeable chosen, or {} with the hand chosen.
func chosen_item() -> Dictionary:
	return DataRegistry.get_item(chosen) if not is_hand() and GameState.item_count(chosen) > 0 else {}


## The data of the thing the hand has lifted, or {}.
func lifted_item() -> Dictionary:
	return DataRegistry.get_item(lifted["item"]) if not lifted.is_empty() else {}


## Chooses the thing `step` slots on along the bar (the wheel). Returns whether the choice
## changed.
func step(by: int) -> bool:
	return _choose(BuildBar.stepped(entries(), chosen, by))


## Chooses the thing in slot `slot` of the bar as it shows (a number key; 0 is the leftmost,
## the hand's unless the bar has moved along). Returns whether the choice changed.
func choose_slot(slot: int) -> bool:
	var held: Array[Dictionary] = entries()
	var top: int = BuildBar.first_shown(area.hud.build_bar.top, BuildBar.index_of(held, chosen), held.size())
	return slot >= 0 and slot < BuildBar.SLOTS and _choose(BuildBar.id_at(held, top + slot))


## Chooses `id` (BuildBar.HAND, or a placeable he carries). What the hand had lifted is let go.
func _choose(id: StringName) -> bool:
	if id == &"" or id == chosen:
		return false
	chosen = id
	lifted = {}
	EventBus.sound.emit(&"menu_move")
	_refresh()
	return true


## The cells that can be built on now: those of the map whose middle the camera shows.
func view_cells() -> Rect2i:
	var to_world: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	var size: float = float(GreyboxTiles.TILE_SIZE)
	var from: Vector2 = to_world * Vector2.ZERO
	var to: Vector2 = to_world * get_viewport().get_visible_rect().size
	var first: Vector2i = Vector2i(ceili(from.x / size - 0.5), ceili(from.y / size - 0.5))
	var last: Vector2i = Vector2i(ceili(to.x / size - 0.5) - 1, ceili(to.y / size - 0.5) - 1)
	return Rect2i(first, last - first + Vector2i.ONE).intersection(Rect2i(Vector2i.ZERO, area.grid.size))


## `at`, or the nearest cell to it that is on screen.
func in_view(at: Vector2i) -> Vector2i:
	var view: Rect2i = view_cells()
	if view.size.x <= 0 or view.size.y <= 0:
		return at
	return Vector2i(clampi(at.x, view.position.x, view.end.x - 1), clampi(at.y, view.position.y, view.end.y - 1))


## Puts the ghost on `at` (or as near to it as the view lets it be). Returns whether it moved.
func point_at(at: Vector2i) -> bool:
	var to: Vector2i = in_view(at)
	if to == cell:
		return false
	cell = to
	_refresh()
	return true


## The cell the mouse is on in `event`.
func cell_under(event: InputEventMouse) -> Vector2i:
	return PlayerMotor.cell_of((make_input_local(event) as InputEventMouse).position)


## What the area knows of `at`, for Placement.why_not. A building's cells (a site's too) are
## no ground to stand on, as the farmhouse's aren't, and the cell before its door is a
## doorstep; `except` names a building that is not counted (the one being moved).
func site_at(at: Vector2i, except: StringName = &"") -> Dictionary:
	var home: Homestead = GameState.homestead()
	var on_map: bool = area.grid.in_bounds(at)
	var covering: StringName = GameState.building_covering(area.area_id, at)
	var before_door: StringName = GameState.doorstep_of(area.area_id, at)
	return Placement.site(
		GameState.homestead_rules().is_land(area.area_id),
		on_map and not area.grid.is_solid(at) and (covering == &"" or covering == except),
		on_map and is_road(at),
		on_map and (is_doorstep(at) or (before_door != &"" and before_door != except)),
		area.plot != null and area.plot.covers(at),
		area.debris_at(at) != null or grass_at(at),
		home.lying_at(at),
		home.standing_at(at),
		area.player.motor.cell == at,
		lies_at(at))


## Whether the meadow's tall grass stands uncut in `at` (the Homestead, phase 3): it is cleared
## first, as debris is.
func grass_at(at: Vector2i) -> bool:
	for child: Node in area.interactables.get_children():
		if child is Breakable and (child as Breakable).is_daily() and not (child as Breakable).broken and (child as Breakable).cell() == at:
			return true
	return false


## Whether `at` is the road, the path to the door, or a way out of the area: a path tile of
## the map, or a cell an exit covers.
func is_road(at: Vector2i) -> bool:
	return area.height_layer.get_cell_atlas_coords(at).y == GreyboxTiles.ROW_PATH or area.exit_at(at) != null


## Whether `at` is the cell before a door: the one below a door in a house's wall.
func is_doorstep(at: Vector2i) -> bool:
	var above: Vector2i = at + Vector2i.UP
	return area.exit_at(above) != null and area.height_layer.get_cell_atlas_coords(above) == GreyboxTiles.coords("door")


## Whether something lies at `at` to be picked up: what a rock or a log left, or what a full
## pack couldn't take.
func lies_at(at: Vector2i) -> bool:
	for child: Node in area.interactables.get_children():
		if child is ItemDrop and not (child as ItemDrop).taken and PlayerMotor.cell_of((child as ItemDrop).position + Vector2(0.5, 0.5)) == at:
			return true
		if child is ItemPickup and not (child as ItemPickup).taken() and (child as ItemPickup).cell() == at:
			return true
	return false


## The thing a left click would set down where the ghost is: the placeable chosen, or what the
## hand has lifted. {} with the hand empty.
func thing_in_hand() -> Dictionary:
	return lifted_item() if is_hand() else chosen_item()


## The building a left click would set down where the ghost is (a building's data entry): the
## one whose kit is chosen. {} for a placeable, or nothing.
func building_in_hand() -> Dictionary:
	var item: Dictionary = thing_in_hand()
	return DataRegistry.get_building(Buildings.building_of_kit(item)) if Buildings.is_kit(item) else {}


## Where the top-left corner of the building in hand is with the ghost where it is: the ghost
## holds it by its door, or the middle of its bottom row.
func building_origin() -> Vector2i:
	return Buildings.origin_at(building_in_hand(), cell)


## Whether the ghost is over the place the lifted thing was lifted from.
func over_its_own_place() -> bool:
	return not lifted.is_empty() and cell == lifted["cell"]


## Why the thing chosen (or lifted) can't be set down where the ghost is, in Placement's
## words; "" if it can, with the hand empty, and over the place a lifted thing came from.
func why_not() -> String:
	var item: Dictionary = thing_in_hand()
	if item.is_empty() or over_its_own_place():
		return ""
	var building: Dictionary = building_in_hand()
	if not building.is_empty():
		return Buildings.why_not_at(building, building_origin(), func(at: Vector2i) -> Dictionary: return site_at(at))
	return Placement.why_not(item, site_at(cell))


## Whether a left click would set a thing down here: there is one in hand, and it fits.
func fits() -> bool:
	return not thing_in_hand().is_empty() and why_not().is_empty()


## The layer of what a click takes at `at`: what stands there, else what lies there.
func layer_to_take(at: Vector2i) -> StringName:
	return Placement.STANDING if GameState.homestead().standing_at(at) != &"" else Placement.LYING


## The id of what a click would take at `at` (to lift it, or to take it up), or &"".
func thing_under(at: Vector2i) -> StringName:
	return GameState.homestead().thing_at(at, layer_to_take(at))


## The line of words under the ghost: why the thing doesn't fit, or what it is and how many
## he carries; and for the hand, what a click would lift or do with what it has lifted.
func words() -> String:
	var why: String = why_not()
	if not why.is_empty():
		return why
	if not is_hand():
		return CHOSEN_WORDS % [str(chosen_item().get("name", chosen)), GameState.item_count(chosen)]
	if not lifted.is_empty():
		return (BACK_WORDS if over_its_own_place() else MOVE_WORDS) % _name_of(lifted["item"])
	var under: StringName = thing_under(cell)
	return LIFT_WORDS % _name_of(under) if under != &"" else HAND_WORDS


## A left click where the ghost is. With a placeable chosen it is set down, and one leaves the
## pack. With the hand, the thing there is lifted, or the lifted thing set down. Returns
## whether anything was done; refused, nothing changes and the words say why.
func set_down() -> bool:
	if not _open:
		return false
	if is_hand():
		return _use_hand()
	var building: Dictionary = building_in_hand()
	var origin: Vector2i = building_origin()
	var done: bool = fits() and (GameState.set_down_kit(area.area_id, origin, chosen) if not building.is_empty()
		else GameState.set_down(area.area_id, cell, chosen))
	if not done:
		EventBus.sound.emit(&"nope")
		_refresh()
		return false
	EventBus.sound.emit(&"set_down")
	if building.is_empty():
		Burst.spawn(area.interactables, GridBody.cell_center(cell), &"dust", 0.6)
	else:
		for at: Vector2i in Buildings.cells_of(building, origin):
			Burst.spawn(area.interactables, GridBody.cell_center(at), &"dust", 0.4)
	# The last of a thing leaves the bar, and the hand is chosen.
	chosen = BuildBar.kept(entries(), chosen)
	_refresh()
	return true


## The hand's click: lifts what is under the ghost; or, with a thing lifted, sets it down
## here (where it came from: it is simply put back). Returns whether anything was done.
func _use_hand() -> bool:
	if lifted.is_empty():
		var layer: StringName = layer_to_take(cell)
		var under: StringName = GameState.homestead().thing_at(cell, layer)
		if under == &"":
			EventBus.sound.emit(&"nope")
			return false
		lifted = {"cell": cell, "layer": layer, "item": under}
		EventBus.sound.emit(&"take_up")
		_refresh()
		return true
	if over_its_own_place():
		lifted = {}
		EventBus.sound.emit(&"set_down")
		_refresh()
		return true
	if not fits() or not GameState.move_placed(area.area_id, lifted["cell"], cell, lifted["layer"]):
		EventBus.sound.emit(&"nope")
		_refresh()
		return false
	lifted = {}
	EventBus.sound.emit(&"set_down")
	Burst.spawn(area.interactables, GridBody.cell_center(cell), &"dust", 0.6)
	_refresh()
	return true


## A right click where the ghost is: takes up what is there into the pack. With a thing
## lifted it lets that go instead (it is where it was). Returns whether a thing was taken up;
## with nothing there, or no room for it, he is told and nothing changes.
func take_up() -> bool:
	if not _open:
		return false
	if not lifted.is_empty():
		lifted = {}
		EventBus.sound.emit(&"menu_move")
		_refresh()
		return false
	var layer: StringName = layer_to_take(cell)
	var why: String = GameState.why_not_take_up(area.area_id, cell, layer)
	if not why.is_empty():
		EventBus.sound.emit(&"nope")
		area.hud.show_message(why)
		return false
	var item_id: StringName = GameState.take_up(area.area_id, cell, layer)
	EventBus.sound.emit(&"take_up")
	area.hud.show_message(TAKEN_UP_WORDS % _name_of(item_id))
	_refresh()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseMotion:
		point_at(cell_under(event))
	elif event.is_action_pressed(&"build") or MenuInput.is_back(event):
		close()
	elif event.is_action_pressed(&"use_hand") or event.is_action_pressed(&"attack"):
		_point_with(event)
		set_down()
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"use_item"):
		_point_with(event)
		take_up()
	elif event.is_action_pressed(&"slot_next"):
		step(1)
	elif event.is_action_pressed(&"slot_previous"):
		step(-1)
	elif event.is_action_pressed(&"move_left", true):
		point_at(cell + Vector2i.LEFT)
	elif event.is_action_pressed(&"move_right", true):
		point_at(cell + Vector2i.RIGHT)
	elif event.is_action_pressed(&"move_up", true):
		point_at(cell + Vector2i.UP)
	elif event.is_action_pressed(&"move_down", true):
		point_at(cell + Vector2i.DOWN)
	else:
		var slot: int = _slot_of(event)
		if slot == BuildBar.NONE:
			return
		choose_slot(slot)
	get_viewport().set_input_as_handled()


## A click is made where the mouse is: the ghost goes there first.
func _point_with(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		point_at(cell_under(event as InputEventMouse))


## Which slot's number key `event` presses (0 for "1"), or BuildBar.NONE.
static func _slot_of(event: InputEvent) -> int:
	for slot: int in AreaController.SLOT_ACTIONS.size():
		if event.is_action_pressed(AreaController.SLOT_ACTIONS[slot]):
			return slot
	return BuildBar.NONE


func _name_of(item_id: StringName) -> String:
	return str(DataRegistry.get_item(item_id).get("name", item_id))


## Shows the mode as it now is: the bar, the words, the ghost.
func _refresh() -> void:
	if not _open:
		return
	var held: Array[Dictionary] = entries()
	area.hud.show_build(held, BuildBar.index_of(held, chosen), words(), why_not().is_empty())
	_ghost.queue_redraw()


## The colour of the ghost: red where the thing in hand doesn't fit; green where it does, and
## where the empty hand has something to lift; pale with nothing to do.
func ghost_colour() -> Color:
	if not why_not().is_empty():
		return REFUSED
	if thing_in_hand().is_empty():
		return FITS if thing_under(cell) != &"" else POINTER
	return POINTER if over_its_own_place() else FITS


func _draw_ghost() -> void:
	var size: float = float(GreyboxTiles.TILE_SIZE)
	var item: Dictionary = thing_in_hand()
	var colour: Color = ghost_colour()
	var building: Dictionary = building_in_hand()
	if not building.is_empty():
		_draw_building_ghost(building, building_origin(), colour)
		return
	# Where a lifted thing came from: it is still there until it is set down.
	if not lifted.is_empty() and not over_its_own_place():
		_draw_outline(Vector2(lifted["cell"] as Vector2i) * size, Color(POINTER, EDGE_ALPHA * 0.7))
	var origin: Vector2 = Vector2(cell) * size
	_ghost.draw_rect(Rect2(origin, Vector2(size, size)), Color(colour, WASH_ALPHA))
	if not item.is_empty():
		var age: int = GameState.homestead().age_at(lifted["cell"]) if not lifted.is_empty() else 0
		PlacedArt.draw_thing(_ghost, item, age, origin, PlacedThing.joined_at(cell, item), Color(colour.lerp(Color.WHITE, 0.45), PICTURE_ALPHA))
	_draw_outline(origin, Color(colour, EDGE_ALPHA))


## The ghost of a building: a wash of `colour` over each of its cells and its doorstep, its
## picture over them, and outlines round it and round the doorstep.
func _draw_building_ghost(building: Dictionary, origin: Vector2i, colour: Color) -> void:
	var size: float = float(GreyboxTiles.TILE_SIZE)
	for at: Vector2i in Buildings.cells_and_doorstep(building, origin):
		_ghost.draw_rect(Rect2(Vector2(at) * size, Vector2(size, size)), Color(colour, WASH_ALPHA))
	BuildingArt.draw(_ghost, building, Vector2(origin) * size, false, false, Color(colour.lerp(Color.WHITE, 0.55), PICTURE_ALPHA), false, true)
	var whole: Rect2 = Rect2(Vector2(origin) * size, Vector2(Buildings.size_of(building)) * size)
	var edge: Color = Color(colour, EDGE_ALPHA)
	_ghost.draw_rect(Rect2(whole.position, Vector2(whole.size.x, 1.0)), edge)
	_ghost.draw_rect(Rect2(whole.position + Vector2(0.0, whole.size.y - 1.0), Vector2(whole.size.x, 1.0)), edge)
	_ghost.draw_rect(Rect2(whole.position + Vector2(0.0, 1.0), Vector2(1.0, whole.size.y - 2.0)), edge)
	_ghost.draw_rect(Rect2(whole.position + Vector2(whole.size.x - 1.0, 1.0), Vector2(1.0, whole.size.y - 2.0)), edge)
	if Buildings.has_door(building):
		_draw_outline(Vector2(Buildings.doorstep_of(building, origin)) * size, Color(colour, EDGE_ALPHA))


## A one-pixel outline of the cell whose top-left is `origin`.
func _draw_outline(origin: Vector2, colour: Color) -> void:
	var size: float = float(GreyboxTiles.TILE_SIZE)
	_ghost.draw_rect(Rect2(origin, Vector2(size, 1.0)), colour)
	_ghost.draw_rect(Rect2(origin + Vector2(0.0, size - 1.0), Vector2(size, 1.0)), colour)
	_ghost.draw_rect(Rect2(origin + Vector2(0.0, 1.0), Vector2(1.0, size - 2.0)), colour)
	_ghost.draw_rect(Rect2(origin + Vector2(size - 1.0, 1.0), Vector2(1.0, size - 2.0)), colour)
