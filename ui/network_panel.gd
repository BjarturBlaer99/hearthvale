class_name NetworkPanel
extends CanvasLayer
## The Network Key's consequence preview (TECH_DESIGN §3.1, GDD pillar 2: every lever has a
## cost, and you see it before you pull). Opened on a repaired network node. Up/Down picks
## Raise or Lower; the text and the region mini-map show every consequence of that choice;
## E confirms through GameState.apply_water_change() and Esc cancels. The game is paused
## while it's open; the panel itself keeps running.

signal closed(applied: bool)

var node_id: StringName
var direction: int = WaterSolver.LOWER
## The preview for the current choice.
var change: WaterChangeResult

@onready var _title: Label = $Panel/Title
@onready var _choices: Label = $Panel/Choices
@onready var _consequences: Label = $Panel/Consequences
@onready var _hint: Label = $Panel/Hint
@onready var map: RegionMap = $Panel/Map


func is_open() -> bool:
	return visible


## Shows the preview for `for_node`, starting with Lower.
func open(for_node: StringName) -> void:
	node_id = for_node
	direction = WaterSolver.LOWER
	visible = true
	get_tree().paused = true
	_refresh()


func choose(new_direction: int) -> void:
	direction = new_direction
	_refresh()


## Applies the previewed change. Does nothing (returns false) if it was rejected.
func confirm() -> bool:
	if not visible or change == null or change.is_rejected():
		return false
	var applied: bool = GameState.apply_water_change(change)
	_close(applied)
	return applied


func cancel() -> void:
	if visible:
		_close(false)


func _close(applied: bool) -> void:
	visible = false
	get_tree().paused = false
	closed.emit(applied)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"move_up"):
		choose(WaterSolver.RAISE)
	elif event.is_action_pressed(&"move_down"):
		choose(WaterSolver.LOWER)
	elif event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		confirm()
	elif event.is_action_pressed(&"ui_cancel"):
		cancel()
	else:
		return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	var network: WaterNetwork = GameState.water_network()
	change = WaterSolver.new().preview(network, node_id, direction)
	var node: WaterNetwork.NetworkNode = network.get_network_node(node_id)
	var district_name: String = network.display_name(node.district) if node != null else String(node_id)
	_title.text = "Network Key: %s %s" % [district_name, node.type if node != null else "node"]
	_choices.text = "%s [Up] Raise %s one level\n%s [Down] Lower %s one level" % [
		">" if direction == WaterSolver.RAISE else " ", district_name,
		">" if direction == WaterSolver.LOWER else " ", district_name,
	]
	if change.is_rejected():
		_consequences.text = "Can't do that:\n%s" % change.rejected_reason
		_hint.text = "[Esc] Back"
	else:
		_consequences.text = "This will change:\n- %s" % "\n- ".join(change.describe())
		_hint.text = "[E] Confirm     [Esc] Cancel"
	map.show_change(network, change, node_id)
