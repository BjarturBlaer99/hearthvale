class_name BuildingSpot
extends Node2D
## A building of the hero's land, or its site, as the hero meets it (the Homestead, phase 3;
## docs/TECH_DESIGN.md §30): what he faces when he stands before any of its cells. It draws
## nothing (PlacedBuildings draws every building flat on the ground, as the farmhouse is) and
## fills no cell itself (PlacedBuildings does). Faced, a building that keeps something takes
## it from him with interact (the right click): the Silo takes the hay he carries.
## GameState says what it is and where; PlacedBuildings makes one for each and moves it.
## Position = its top-left corner.

const SILO_PROMPT: String = "Put hay in the %s"

## Which building it is (data/buildings), and where its top-left corner is.
var building_id: StringName = &""
var building: Dictionary = {}
var origin: Vector2i = Vector2i.ZERO


## Shows it as building `id` with its top-left corner at `at`.
func show_as(id: StringName, at: Vector2i) -> void:
	building_id = id
	building = DataRegistry.get_building(id)
	origin = at
	position = Vector2(at * GreyboxTiles.TILE_SIZE)


func cell() -> Vector2i:
	return origin


## Whether `at` is one of its cells.
func covers(at: Vector2i) -> bool:
	return Buildings.covers(building, origin, at)


## Whether it stands today (else it is a site).
func stands() -> bool:
	return GameState.is_built(building_id)


## Interact, facing it: a building that keeps something takes it (the Silo, the hay he carries),
## and the words say how it went. "" for one that does nothing, and for a site.
func use() -> String:
	return GameState.put_hay(building_id) if stands() and not Buildings.holds(building).is_empty() else ""


## The HUD's prompt facing it: "Put hay in the Silo", or nothing.
func prompt() -> String:
	if not stands() or Buildings.holds(building).is_empty():
		return ""
	return SILO_PROMPT % Buildings.name_of(building)
