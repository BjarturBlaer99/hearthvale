class_name QuestRunner
extends RefCounted
## Runs quests from data (docs/data/quest.schema.json, TECH_DESIGN §7) against a game state:
## GameState, or anything with get_quest_stage(), set_quest_stage(), get_flag(), set_flag(),
## add_item() and to_dict(). Pure, and it keeps nothing of its own: a quest's stage is in the
## state's quests, and QuestState's flags record what has been applied, so it all saves.
##
## update() does the work, and is safe to call any time something changes:
## - a quest that has reached a stage gets that stage's `on_enter` effects, once (the
##   `complete_quest` effect finishes the quest)
## - an active quest moves on by the first of its stage's `transitions` whose condition is met
## - a quest marked `auto_start` that hasn't started is started (the main story)
## It repeats until nothing changes. Quests start with start(), or when anything sets their
## stage (a dialogue's set_quest_stage effect).

## A quest reached `stage_id`: `first` for its first stage, `completed` if that finished it.
signal stage_entered(quest_id: StringName, stage_id: StringName, first: bool, completed: bool)

## One change is made per pass, so this bounds how far a single update() can go. Quest data that
## loops (two stages whose conditions send each to the other) stops here, with a warning.
const MAX_PASSES: int = 64

var _quests: Dictionary = {}
var _state: Object
var _effects: EffectApplier


## `quests` maps quest id -> quest data (as DataRegistry holds them).
func _init(quests: Dictionary, state: Object) -> void:
	for id: Variant in quests:
		_quests[StringName(str(id))] = quests[id]
	_state = state
	_effects = EffectApplier.new(state)


func quest_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _quests:
		out.append(id)
	return out


func has_quest(quest_id: StringName) -> bool:
	return _quests.has(quest_id)


## Whether `quest_id` begins by itself (its `auto_start`): nobody gives it.
func starts_itself(quest_id: StringName) -> bool:
	var marked: Variant = (_quests.get(quest_id, {}) as Dictionary).get("auto_start", false)
	return typeof(marked) == TYPE_BOOL and marked


func title(quest_id: StringName) -> String:
	return str((_quests.get(quest_id, {}) as Dictionary).get("title", quest_id))


## The stage `quest_id` is in (empty: not started).
func stage(quest_id: StringName) -> StringName:
	return StringName(str(_state.call(&"get_quest_stage", quest_id)))


func status(quest_id: StringName) -> StringName:
	if _state.call(&"get_flag", QuestState.complete_flag(quest_id)) == true:
		return QuestState.COMPLETE
	return QuestState.ACTIVE if stage(quest_id) != &"" else QuestState.NOT_STARTED


## Starts `quest_id` at its start stage. Returns false if it's unknown or already started.
func start(quest_id: StringName) -> bool:
	if not has_quest(quest_id) or status(quest_id) != QuestState.NOT_STARTED:
		return false
	_state.call(&"set_quest_stage", quest_id, StringName(str(_quests[quest_id].get("start_stage", ""))))
	update()
	return true


## The current stage's journal line (empty: not started).
func journal(quest_id: StringName) -> String:
	return str(_stage_data(quest_id, stage(quest_id)).get("journal", ""))


## The current stage's objectives: [{ "text", "done", "optional" }].
func objectives(quest_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var listed: Variant = _stage_data(quest_id, stage(quest_id)).get("objectives", [])
	if typeof(listed) != TYPE_ARRAY:
		return out
	var evaluator: ConditionEvaluator = ConditionEvaluator.new(_state.call(&"to_dict"))
	for objective: Variant in listed:
		if typeof(objective) != TYPE_DICTIONARY:
			continue
		out.append({
			"text": str((objective as Dictionary).get("text", "")),
			"done": evaluator.is_met((objective as Dictionary).get("complete_when", {})),
			"optional": bool((objective as Dictionary).get("optional", false)),
		})
	return out


## Every started quest, for the quest log: active ones first, then finished ones, each group
## by title: [{ "id", "title", "status", "journal", "objectives" }].
func started_quests() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for wanted: StringName in [QuestState.ACTIVE, QuestState.COMPLETE]:
		var group: Array[Dictionary] = []
		for quest_id: StringName in _quests:
			if status(quest_id) == wanted:
				group.append({
					"id": quest_id, "title": title(quest_id), "status": wanted,
					"journal": journal(quest_id), "objectives": objectives(quest_id),
				})
		group.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["title"]) < str(b["title"]))
		out.append_array(group)
	return out


func active_count() -> int:
	var count: int = 0
	for quest_id: StringName in _quests:
		if status(quest_id) == QuestState.ACTIVE:
			count += 1
	return count


## Applies what's due: on_enter effects of stages just reached, then transitions whose
## conditions are met, until nothing changes. Returns how many changes it made.
func update() -> int:
	var changes: int = 0
	for pass_index: int in MAX_PASSES:
		if not _step():
			return changes
		changes += 1
	push_warning("QuestRunner: quests still changing after %d steps; is a quest's data going round in a loop?" % MAX_PASSES)
	return changes


## Makes the first change that's due, if any. Returns whether it made one.
func _step() -> bool:
	var evaluator: ConditionEvaluator = null
	for quest_id: StringName in _quests:
		var stage_id: StringName = stage(quest_id)
		if stage_id == &"" and starts_itself(quest_id) and status(quest_id) == QuestState.NOT_STARTED:
			_state.call(&"set_quest_stage", quest_id, StringName(str(_quests[quest_id].get("start_stage", ""))))
			return true
		if stage_id == &"" or status(quest_id) == QuestState.COMPLETE:
			continue
		var stage_data: Dictionary = _stage_data(quest_id, stage_id)
		if stage_data.is_empty():
			continue
		if str(_state.call(&"get_flag", QuestState.entered_flag(quest_id), "")) != String(stage_id):
			_enter(quest_id, stage_id, stage_data)
			return true
		var transitions: Variant = stage_data.get("transitions", [])
		if typeof(transitions) != TYPE_ARRAY or (transitions as Array).is_empty():
			continue
		if evaluator == null:
			evaluator = ConditionEvaluator.new(_state.call(&"to_dict"))
		for transition: Variant in transitions:
			if typeof(transition) == TYPE_DICTIONARY and evaluator.is_met((transition as Dictionary).get("when", {})):
				_state.call(&"set_quest_stage", quest_id, StringName(str((transition as Dictionary).get("to", ""))))
				return true
	return false


## Records that `quest_id` reached `stage_id`, then applies the stage's on_enter effects.
func _enter(quest_id: StringName, stage_id: StringName, stage_data: Dictionary) -> void:
	var flag: StringName = QuestState.entered_flag(quest_id)
	var first: bool = str(_state.call(&"get_flag", flag, "")) == ""
	# Recorded first, so nothing the effects set off can apply them a second time.
	_state.call(&"set_flag", flag, String(stage_id))
	var completed: bool = false
	var effects: Variant = stage_data.get("on_enter", [])
	if typeof(effects) == TYPE_ARRAY:
		for effect: Variant in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue
			if str((effect as Dictionary).get("type", "")) == "complete_quest":
				completed = true
			else:
				_effects.apply(effect)
	if completed:
		_state.call(&"set_flag", QuestState.complete_flag(quest_id), true)
	stage_entered.emit(quest_id, stage_id, first, completed)


func _stage_data(quest_id: StringName, stage_id: StringName) -> Dictionary:
	var stages: Variant = (_quests.get(quest_id, {}) as Dictionary).get("stages", {})
	if typeof(stages) != TYPE_DICTIONARY:
		return {}
	var found: Variant = (stages as Dictionary).get(String(stage_id), {})
	return found if typeof(found) == TYPE_DICTIONARY else {}
