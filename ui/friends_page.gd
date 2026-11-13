class_name FriendsPage
extends Control
## The Friends page (pause menu, "Friends"; P4c, GDD §10): every villager by name, with their
## marks of friendship as a row of blossoms, and a line that says how friendship grows. A
## click or Esc returns to the pause menu. It reads the friendships as they stand when opened,
## and works while the game is paused.

signal closed

const HOW_WORDS: String = "Talk to them each day, and bring a gift they like."
## How far apart the rows are, and where a row's blossoms begin.
const ROW_HEIGHT: float = 12.0
const MARKS_X: float = 150.0
const NAME_COLOUR: Color = Color(0.78, 0.88, 1.0)

@onready var _rows: Control = $Panel/Rows
@onready var _how: Label = $Panel/How


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func open() -> void:
	for old: Node in _rows.get_children():
		_rows.remove_child(old)
		old.queue_free()
	var listed: Array[Dictionary] = rows()
	for i: int in listed.size():
		var name_label: Label = Label.new()
		name_label.text = str(listed[i]["name"])
		name_label.position = Vector2(0, float(i) * ROW_HEIGHT)
		name_label.add_theme_font_size_override(&"font_size", 8)
		name_label.add_theme_color_override(&"font_color", NAME_COLOUR)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows.add_child(name_label)
		var marks: FriendMarks = FriendMarks.new()
		marks.position = Vector2(MARKS_X, float(i) * ROW_HEIGHT + 2.0)
		marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.show_marks(int(listed[i]["marks"]), int(listed[i]["of"]))
		_rows.add_child(marks)
	_how.text = HOW_WORDS
	show()


func is_open() -> bool:
	return visible


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## Every villager, by name: [{ "id", "name", "marks", "of" }].
static func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var most: int = GameState.friendship().marks
	for villager: Dictionary in DataRegistry.entries(&"villagers"):
		var id: StringName = StringName(str(villager["id"]))
		out.append({"id": id, "name": str(villager.get("name", id)), "marks": GameState.friend_marks(id), "of": most})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["name"]) < str(b["name"]))
	return out


## The page in words, a villager a line: "Elder Bram 2/5".
func shown_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	if visible:
		for row: Dictionary in rows():
			lines.append("%s %d/%d" % [row["name"], row["marks"], row["of"]])
	return lines


## The blossoms drawn for each villager now, in the page's order.
func shown_marks() -> Array[FriendMarks]:
	var out: Array[FriendMarks] = []
	for child: Node in _rows.get_children():
		if child is FriendMarks and not child.is_queued_for_deletion():
			out.append(child as FriendMarks)
	return out


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if MenuInput.is_back(event) or MenuInput.is_confirm(event):
		get_viewport().set_input_as_handled()
		close()
