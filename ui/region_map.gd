class_name RegionMap
extends Control
## The Network Key's mini-map (ROADMAP M4). A box per district and basin, placed by its
## "map" position in res://data/water, with a water gauge (now, and after the previewed
## change) and its level. The network's pipes are lines; the node in use is highlighted, with
## an arrow showing which way the water goes. Whatever the change touches is outlined amber;
## a district whose level rises (it floods) is outlined red.

const CELL: Vector2 = Vector2(96, 42)
const BOX: Vector2 = Vector2(88, 30)
const FONT_SIZE: int = 8
const PIPE: Color = Color(0.55, 0.60, 0.62, 0.6)
const ACTIVE: Color = Color(1.0, 0.78, 0.32)
const FLOODS: Color = Color(1.0, 0.42, 0.36)
const QUIET: Color = Color(0.42, 0.47, 0.50)
const TEXT: Color = Color(0.92, 0.92, 0.88)
const WATER: Color = Color(0.20, 0.62, 0.66)
const BOX_FILL: Color = Color(0.08, 0.11, 0.13, 0.95)

var _network: WaterNetwork
var _change: WaterChangeResult
var _node_id: StringName


func show_change(network: WaterNetwork, change: WaterChangeResult, node_id: StringName) -> void:
	_network = network
	_change = change
	_node_id = node_id
	queue_redraw()


## The outline colour this map would use for `district_id` (also handy for tests).
func outline_for(district_id: StringName) -> Color:
	var entry: Dictionary = _district_change(district_id)
	if entry.is_empty():
		return QUIET
	var district: WaterNetwork.District = _network.get_district(district_id)
	var to_index: int = district.level_ids.find(entry["to_level"])
	return FLOODS if to_index < district.level_index else ACTIVE


func _draw() -> void:
	if _network == null:
		return
	for id: StringName in _network.nodes:
		var node: WaterNetwork.NetworkNode = _network.nodes[id]
		if not _placed(node.district) or not _placed(node.target):
			continue
		var from: Vector2 = _center(node.district)
		var to: Vector2 = _center(node.target)
		var active: bool = id == _node_id
		draw_line(from, to, ACTIVE if active else PIPE, 2.0 if active else 1.0)
		if active and _change != null and not _change.is_rejected():
			if _change.direction == WaterSolver.LOWER:
				_arrow(from, to)
			else:
				_arrow(to, from)
	for id: StringName in _network.districts:
		if _placed(id):
			_draw_district(id)
	for id: StringName in _network.basins:
		if _placed(id):
			_draw_basin(id)


func _draw_district(id: StringName) -> void:
	var district: WaterNetwork.District = _network.get_district(id)
	var before: float = _fraction(district, district.level_index, district.pending)
	var after: float = before
	var label: String = String(district.level_id())
	var entry: Dictionary = _district_change(id)
	if not entry.is_empty():
		after = _fraction(district, district.level_ids.find(entry["to_level"]), int(entry["to_pending"]))
		if entry["from_level"] != entry["to_level"]:
			label = "%s -> %s" % [entry["from_level"], entry["to_level"]]
		else:
			label = "%s, +%d/%d" % [entry["to_level"], int(entry["to_pending"]), int(entry["step_volume"])]
	_draw_box(id, district.name, label, before, after, outline_for(id), not entry.is_empty())


func _draw_basin(id: StringName) -> void:
	var basin: WaterNetwork.Basin = _network.get_basin(id)
	var capacity: float = maxf(1.0, float(basin.capacity))
	var before: float = basin.stored / capacity
	var after: float = before
	var label: String = "%d / %d" % [basin.stored, basin.capacity]
	var changed: bool = _change != null and not _change.is_rejected() and _change.basins.has(id)
	if changed:
		var entry: Dictionary = _change.basins[id]
		after = int(entry["to_stored"]) / capacity
		label = "%d -> %d / %d" % [int(entry["from_stored"]), int(entry["to_stored"]), basin.capacity]
	_draw_box(id, basin.name, label, before, after, ACTIVE if changed else QUIET, changed)


func _draw_box(id: StringName, title: String, label: String, before: float, after: float, outline: Color, changed: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	var rect: Rect2 = Rect2(_place(id), BOX)
	draw_rect(rect, BOX_FILL)
	draw_rect(rect, outline, false, 2.0 if changed else 1.0)
	draw_string(font, rect.position + Vector2(4, 10), title, HORIZONTAL_ALIGNMENT_LEFT, BOX.x - 6.0, FONT_SIZE, TEXT)
	draw_string(font, rect.position + Vector2(4, 20), label, HORIZONTAL_ALIGNMENT_LEFT, BOX.x - 6.0, FONT_SIZE, outline if changed else QUIET)
	var gauge: Rect2 = Rect2(rect.position + Vector2(4, 23), Vector2(BOX.x - 8.0, 4))
	draw_rect(gauge, Color(0.02, 0.03, 0.04))
	draw_rect(Rect2(gauge.position, Vector2(gauge.size.x * clampf(after, 0.0, 1.0), gauge.size.y)), WATER)
	if changed and not is_equal_approx(before, after):
		var x: float = gauge.position.x + gauge.size.x * clampf(before, 0.0, 1.0)
		draw_line(Vector2(x, gauge.position.y - 1), Vector2(x, gauge.end.y + 1), TEXT, 1.0)


func _arrow(from: Vector2, to: Vector2) -> void:
	var direction: Vector2 = (to - from).normalized()
	var tip: Vector2 = from.lerp(to, 0.62)
	var side: Vector2 = direction.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([tip + direction * 5.0, tip - direction * 3.0 + side, tip - direction * 3.0 - side]), ACTIVE)


func _district_change(id: StringName) -> Dictionary:
	if _change == null or _change.is_rejected():
		return {}
	return _change.districts.get(id, {})


## How full a district is, 0..1: levels above its lowest plus pending water.
func _fraction(district: WaterNetwork.District, level_index: int, pending: int) -> float:
	var top: int = district.level_ids.size() - 1
	if top <= 0:
		return 1.0
	return clampf((float(top - level_index) + float(pending) / float(district.volume_per_step)) / float(top), 0.0, 1.0)


func _placed(id: StringName) -> bool:
	return _map_entry(id).has("map")


func _place(id: StringName) -> Vector2:
	var map: Array = _map_entry(id)["map"]
	return Vector2(float(map[0]), float(map[1])) * CELL


func _center(id: StringName) -> Vector2:
	return _place(id) + BOX * 0.5


func _map_entry(id: StringName) -> Dictionary:
	if DataRegistry.has_entry(&"districts", id):
		return DataRegistry.get_district(id)
	return DataRegistry.get_entry(&"basins", id)
