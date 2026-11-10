class_name EndingScreen
extends Control
## The ending (docs/TECH_DESIGN.md §12): shown once, when the crypt's closing words are done
## (the area comes here when the flag AreaController.ENDING_FLAG is set). "The End" over the
## title's picture with the keep's window dark, what the game took (EndingSummary), and two
## choices: keep exploring (back to where the hero stood) or save and go to the title. Up and
## down pick, E or Enter chooses.

const KEEP_EXPLORING: StringName = &"explore"
const SAVE_AND_QUIT: StringName = &"save_quit"
const TITLE_SCENE: String = "res://ui/title_screen.tscn"

var cursor: MenuCursor = MenuCursor.new()
## Changes the scene (gets its path). Tests replace it.
var travel: Callable

@onready var _stats: Label = $Stats
@onready var _list: Label = $Menu/List
@onready var _note: Label = $Note


func _init() -> void:
	travel = func(path: String) -> void: get_tree().change_scene_to_file(path)


func _ready() -> void:
	get_tree().paused = false
	EventBus.music_requested.emit(&"village")
	cursor.set_options([
		MenuCursor.option(KEEP_EXPLORING, "Keep exploring"),
		MenuCursor.option(SAVE_AND_QUIT, "Save and go to the title"),
	])
	_stats.text = "\n".join(summary_lines())
	_list.text = "\n".join(cursor.lines())
	_note.text = ""


## The game just finished, in lines: time played, hearts, quests finished.
static func summary_lines() -> PackedStringArray:
	var quest_ids: Array[StringName] = DataRegistry.ids(&"quests")
	return EndingSummary.lines(GameState.format_play_time(GameState.play_time), GameState.hearts_max,
		EndingSummary.quests_done(quest_ids, GameState.quests, GameState.flags), quest_ids.size())


func shown_stats() -> String:
	return _stats.text


func shown_lines() -> PackedStringArray:
	return cursor.lines()


func note() -> String:
	return _note.text


func move_cursor(step: int) -> void:
	EventBus.sound.emit(&"menu_move")
	cursor.move(step)
	_list.text = "\n".join(cursor.lines())


## Does what option `id` says (the highlighted one by default).
func choose(id: StringName = &"") -> void:
	if id == &"":
		id = cursor.selected_id()
	EventBus.sound.emit(&"menu_select")
	match id:
		KEEP_EXPLORING:
			var area: StringName = StringName(str(GameState.player.get("area", WorldPaths.START_AREA)))
			travel.call(WorldPaths.scene_for(area if ResourceLoader.exists(WorldPaths.scene_for(area)) else WorldPaths.START_AREA))
		SAVE_AND_QUIT:
			var error: Error = SaveSystem.save_game()
			if error != OK:
				_note.text = "Couldn't save (%s)." % error_string(error)
				return
			travel.call(TITLE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	# Take the viewport now: a choice changes the scene, which takes this screen out of the tree.
	var viewport: Viewport = get_viewport()
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_confirm(event):
		choose()
	else:
		return
	viewport.set_input_as_handled()
