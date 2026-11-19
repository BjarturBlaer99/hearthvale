class_name BuildMode
extends Node2D
## Build mode (the Homestead, phase 2; docs/TECH_DESIGN.md §30; the plan's D12): a screen, as
## a menu is, in which the hero sets things down on his land and takes them up again. The area
## opens it (B, on the homestead only) and keeps him still, and the clock with him, while it
## is open (`is_in_menu()`).
## - The mouse points at a cell, and the movement keys move the ghost a cell at a time. Only
##   what is on screen can be built on: the ghost stops at the edge of the view.
## - The ghost shows the thing chosen, green where it fits and red where it doesn't, and a
##   line of words says why (Placement.why_not; the area's HUD shows them).
## - A left click (or the sword's key) sets it down and takes one from the pack. A right click
##   (or the item's key) takes up what is under the ghost, into the pack: what stands there
##   before what lies there.
## - The wheel steps along the build bar, which takes the item bar's place, and the keys 1 to
##   9 choose on it (BuildBar).
## - Tab, Esc or B leave.
## Placement (pure) says what fits; GameState sets down and takes up; PlacedThings shows it.
## This is the only place anything is set down from: in play the mouse is two buttons, as
## ever, and where a click lands doesn't matter.

signal closed

## The ghost's colours: where the thing fits, where it doesn't, and with nothing to set down.
const FITS: Color = Color(0.42, 1.0, 0.52)
const REFUSED: Color = Color(1.0, 0.36, 0.30)
const POINTER: Color = Color(1.0, 0.93, 0.70)
## How solid the ghost's picture, its cell's wash and its outline are drawn.
const PICTURE_ALPHA: float = 0.78
const WASH_ALPHA: float = 0.24
const EDGE_ALPHA: float = 0.95
## The words under the ghost: the thing chosen and how many he carries, and what is said with
## nothing to set down.
const CHOSEN_WORDS: String = "%s x%d"
const NOTHING_WORDS: String = "You carry nothing to set down."
## What is said when a thing is taken up (its name).
const TAKEN_UP_WORDS: String = "Taken up: %s."
## The ghost is drawn over the world and under the HUD, in the world's own coordinates, clear
## of the night's tint (a layer of its own that follows the camera).
const GHOST_LAYER: int = 1

var area: AreaController
## The id of the placeable chosen on the bar (&"": he carries none).
var chosen: StringName = &""
## The cell the ghost is on.
var cell: Vector2i = Vector2i.ZERO

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
## chosen still, if he has any left.
func open() -> void:
	if _open:
		return
	_open = true
	chosen = BuildBar.kept(entries(), chosen)
	cell = in_view(area.player.front_cell())
	_ghost.visible = true
	EventBus.sound.emit(&"menu_select")
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	_ghost.visible = false
	area.hud.hide_build()
	EventBus.sound.emit(&"menu_select")
	closed.emit()


func is_open() -> bool:
	return _open


## What is on the build bar: every placeable he carries (item data entries).
func entries() -> Array[Dictionary]:
	return BuildBar.entries(GameState.inventory, DataRegistry.entries(&"items"))


## The data of the thing chosen, or {} with nothing chosen.
func chosen_item() -> Dictionary:
	return DataRegistry.get_item(chosen) if chosen != &"" and GameState.item_count(chosen) > 0 else {}


## Chooses the thing `step` slots on along the bar (the wheel). Returns whether the choice
## changed.
func step(by: int) -> bool:
	return _choose(BuildBar.stepped(entries(), chosen, by))


## Chooses the thing in slot `slot` of the bar as it shows (a number key; 0 is the leftmost).
## Returns whether the choice changed.
func choose_slot(slot: int) -> bool:
	var held: Array[Dictionary] = entries()
	var top: int = BuildBar.first_shown(area.hud.build_bar.top, BuildBar.index_of(held, chosen), held.size())
	return slot >= 0 and slot < BuildBar.SLOTS and _choose(BuildBar.id_at(held, top + slot))


func _choose(item_id: StringName) -> bool:
	if item_id == &"" or item_id == chosen:
		return false
	chosen = item_id
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


## What the area knows of `at`, for Placement.why_not.
func site_at(at: Vector2i) -> Dictionary:
	var home: Homestead = GameState.homestead()
	var on_map: bool = area.grid.in_bounds(at)
	return Placement.site(
		GameState.homestead_rules().is_land(area.area_id),
		on_map and not area.grid.is_solid(at),
		on_map and is_road(at),
		on_map and is_doorstep(at),
		area.plot != null and area.plot.covers(at),
		area.debris_at(at) != null,
		home.lying_at(at),
		home.standing_at(at),
		area.player.motor.cell == at,
		lies_at(at))


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


## Why the thing chosen can't be set down where the ghost is, in Placement's words; "" if it
## can, and with nothing chosen.
func why_not() -> String:
	var item: Dictionary = chosen_item()
	return "" if item.is_empty() else Placement.why_not(item, site_at(cell))


## Whether the ghost is green: there is a thing chosen, and it fits here.
func fits() -> bool:
	return not chosen_item().is_empty() and why_not().is_empty()


## The line of words under the ghost: why the thing doesn't fit, or what it is and how many
## he carries.
func words() -> String:
	var item: Dictionary = chosen_item()
	if item.is_empty():
		return NOTHING_WORDS
	var why: String = why_not()
	return why if not why.is_empty() else CHOSEN_WORDS % [str(item.get("name", chosen)), GameState.item_count(chosen)]


## Sets the thing chosen down where the ghost is (a left click). Returns whether it was set
## down; refused, nothing changes and the words say why.
func set_down() -> bool:
	if not _open:
		return false
	if not fits() or not GameState.set_down(area.area_id, cell, chosen):
		EventBus.sound.emit(&"nope")
		_refresh()
		return false
	EventBus.sound.emit(&"set_down")
	Burst.spawn(area.interactables, GridBody.cell_center(cell), &"dust", 0.6)
	# The last of a thing leaves the bar: the next on it is chosen.
	chosen = BuildBar.kept(entries(), chosen)
	_refresh()
	return true


## The layer of what a right click takes up at `at`: what stands there, else what lies there.
func layer_to_take(at: Vector2i) -> StringName:
	return Placement.STANDING if GameState.homestead().standing_at(at) != &"" else Placement.LYING


## Takes up what is under the ghost into the pack (a right click). Returns whether a thing was
## taken up; with nothing there, or no room for it, he is told and nothing changes.
func take_up() -> bool:
	if not _open:
		return false
	var layer: StringName = layer_to_take(cell)
	var why: String = GameState.why_not_take_up(area.area_id, cell, layer)
	if not why.is_empty():
		EventBus.sound.emit(&"nope")
		area.hud.show_message(why)
		return false
	var item_id: StringName = GameState.take_up(area.area_id, cell, layer)
	EventBus.sound.emit(&"take_up")
	area.hud.show_message(TAKEN_UP_WORDS % str(DataRegistry.get_item(item_id).get("name", item_id)))
	chosen = BuildBar.kept(entries(), chosen)
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


## Shows the mode as it now is: the bar, the words, the ghost.
func _refresh() -> void:
	if not _open:
		return
	var held: Array[Dictionary] = entries()
	area.hud.show_build(held, BuildBar.index_of(held, chosen), words(), fits() or chosen_item().is_empty())
	_ghost.queue_redraw()


func _draw_ghost() -> void:
	var size: float = float(GreyboxTiles.TILE_SIZE)
	var origin: Vector2 = Vector2(cell) * size
	var item: Dictionary = chosen_item()
	var colour: Color = POINTER if item.is_empty() else (FITS if fits() else REFUSED)
	_ghost.draw_rect(Rect2(origin, Vector2(size, size)), Color(colour, WASH_ALPHA))
	if not item.is_empty():
		PlacedArt.draw_thing(_ghost, item, 0, origin, PlacedThing.joined_at(cell, item), Color(colour.lerp(Color.WHITE, 0.45), PICTURE_ALPHA))
	var edge: Color = Color(colour, EDGE_ALPHA)
	_ghost.draw_rect(Rect2(origin, Vector2(size, 1.0)), edge)
	_ghost.draw_rect(Rect2(origin + Vector2(0.0, size - 1.0), Vector2(size, 1.0)), edge)
	_ghost.draw_rect(Rect2(origin + Vector2(0.0, 1.0), Vector2(1.0, size - 2.0)), edge)
	_ghost.draw_rect(Rect2(origin + Vector2(size - 1.0, 1.0), Vector2(1.0, size - 2.0)), edge)
