extends RefCounted
## The list of art PNGs (art/sheets.json, since the art became PNG on 2026-11-19): what each
## picture's size, frames, rows, flash row and pivot are. Tests check the PNGs and the scripts
## that draw them against it.

const PATH: String = "res://art/sheets.json"


## Every sheet's entry, in the file's order.
static func all() -> Array:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return []
	return (JSON.parse_string(file.get_as_text()) as Dictionary)["sheets"]


## The entry of the sheet whose PNG is named `file` ("slime", "player_sheet"), or {}.
static func sheet(file: String) -> Dictionary:
	for entry: Dictionary in all():
		if str(entry["path"]).get_file().get_basename() == file:
			return entry
	return {}


## The frames of the sheet named `file`, in order.
static func frames(file: String) -> Array:
	return sheet(file).get("frames", [])


## The PNG itself, as saved (not as imported).
static func image(entry: Dictionary) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(str(entry["path"])))
