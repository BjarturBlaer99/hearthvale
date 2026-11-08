class_name MenuCursor
extends RefCounted
## A menu's cursor (docs/TECH_DESIGN.md §12): a list of options, each an id, a label and whether
## it can be chosen now. move() steps up or down, wrapping round and skipping options that can't
## be chosen. Pure: the title screen, the pause menu and the settings menu draw it.

var options: Array[Dictionary] = []
var selected: int = 0


## One option: {"id", "text", "enabled"}.
static func option(id: StringName, text: String, enabled: bool = true) -> Dictionary:
	return {"id": id, "text": text, "enabled": enabled}


func _init(list: Array[Dictionary] = []) -> void:
	set_options(list)


## Replaces the options, keeping the cursor on `keep` if it's still there and can be chosen,
## else on the first option that can.
func set_options(list: Array[Dictionary], keep: StringName = &"") -> void:
	options = list
	selected = -1
	if keep != &"":
		for i: int in options.size():
			if options[i]["id"] == keep and _enabled(i):
				selected = i
				return
	for i: int in options.size():
		if _enabled(i):
			selected = i
			return


## Steps `step` options (negative: up), wrapping and skipping ones that can't be chosen.
func move(step: int) -> void:
	if selected < 0 or options.is_empty():
		return
	var direction: int = signi(step)
	for count: int in absi(step):
		for i: int in options.size():
			selected = wrapi(selected + direction, 0, options.size())
			if _enabled(selected):
				break


## The id under the cursor, or empty when nothing can be chosen.
func selected_id() -> StringName:
	return options[selected]["id"] if selected >= 0 and selected < options.size() else &""


## Each option's label, the selected one marked with `cursor`, ones that can't be chosen in
## brackets.
func lines(cursor: String = "> ") -> PackedStringArray:
	var out: PackedStringArray = []
	for i: int in options.size():
		var text: String = str(options[i]["text"])
		if not _enabled(i):
			text = "(%s)" % text
		out.append((cursor if i == selected else " ".repeat(cursor.length())) + text)
	return out


func _enabled(index: int) -> bool:
	return bool(options[index].get("enabled", true))
