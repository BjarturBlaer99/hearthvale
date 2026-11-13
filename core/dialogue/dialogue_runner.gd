class_name DialogueRunner
extends RefCounted
## Plays one conversation from a dialogue file (docs/data/dialogue.schema.json, TECH_DESIGN §7).
## Pure: give it the dialogue data and a game state (GameState, or a stand-in with to_dict()
## and the methods EffectApplier calls). Call start(), show speaker_name(), text() and
## options(), then answer with choose(index), or advance() on a node with no options (a sign,
## a remark). Choosing applies the option's effects and moves to its `next`; null ends it.
## A node's `on_enter` effects apply when the conversation reaches it.
## It begins at `start`, unless one of the dialogue's optional `openings` has its conditions
## met: the first that has is where it begins instead (Elder Bram greets a newcomer otherwise).

## The conversation is over (or never started: a bad start node).
signal ended

var dialogue: Dictionary
## The current node's id; empty before start() and once the conversation is over.
var node_id: String = ""

var _state: Object
var _effects: EffectApplier


func _init(dialogue_data: Dictionary, state: Object) -> void:
	dialogue = dialogue_data
	_state = state
	_effects = EffectApplier.new(state)


## The display name for `speaker` in `dialogue_data`: its optional "speakers" map, else the
## id capitalised ("bram" -> "Bram"). An empty speaker (a sign) has no name.
static func speaker_name_of(dialogue_data: Dictionary, speaker: String) -> String:
	var names: Variant = dialogue_data.get("speakers", {})
	if typeof(names) == TYPE_DICTIONARY and (names as Dictionary).has(speaker):
		return str(names[speaker])
	return speaker.capitalize()


func start() -> void:
	_go(opening())


## The node the conversation begins at now: the first of `openings` whose conditions are met,
## else `start`.
func opening() -> Variant:
	var openings: Variant = dialogue.get("openings", [])
	if typeof(openings) == TYPE_ARRAY and not (openings as Array).is_empty():
		var evaluator: ConditionEvaluator = ConditionEvaluator.new(_state.call(&"to_dict"))
		for entry: Variant in openings:
			if typeof(entry) == TYPE_DICTIONARY and evaluator.all_met((entry as Dictionary).get("conditions", [])):
				return (entry as Dictionary).get("node")
	return dialogue.get("start")


func is_running() -> bool:
	return node_id != ""


func current_node() -> Dictionary:
	var nodes: Variant = dialogue.get("nodes", {})
	if typeof(nodes) != TYPE_DICTIONARY:
		return {}
	var found: Variant = (nodes as Dictionary).get(node_id, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


func speaker_id() -> String:
	return str(current_node().get("speaker", ""))


func speaker_name() -> String:
	return speaker_name_of(dialogue, speaker_id())


func text() -> String:
	return str(current_node().get("text", ""))


## The current node's options whose conditions are met, in file order.
func options() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not is_running():
		return out
	var evaluator: ConditionEvaluator = ConditionEvaluator.new(_state.call(&"to_dict"))
	var all_options: Variant = current_node().get("options", [])
	if typeof(all_options) != TYPE_ARRAY:
		return out
	for option: Variant in all_options:
		if typeof(option) == TYPE_DICTIONARY and evaluator.all_met((option as Dictionary).get("conditions", [])):
			out.append(option)
	return out


func option_texts() -> PackedStringArray:
	var texts: PackedStringArray = []
	for option: Dictionary in options():
		texts.append(str(option.get("text", "")))
	return texts


## Answers with visible option `index`: applies its effects, then moves to its `next`.
## Returns false (and changes nothing) if there's no such option.
func choose(index: int) -> bool:
	var visible: Array[Dictionary] = options()
	if index < 0 or index >= visible.size():
		return false
	var option: Dictionary = visible[index]
	_effects.apply_all(option.get("effects", []))
	_go(option.get("next"))
	return true


## Moves on from a node with no options: the conversation ends. Returns false if the node
## has options to choose from instead.
func advance() -> bool:
	if not is_running() or not options().is_empty():
		return false
	_go(null)
	return true


func _go(next: Variant) -> void:
	var nodes: Variant = dialogue.get("nodes", {})
	if next == null or typeof(nodes) != TYPE_DICTIONARY or not (nodes as Dictionary).has(str(next)):
		node_id = ""
		ended.emit()
		return
	node_id = str(next)
	_effects.apply_all(current_node().get("on_enter", []))
