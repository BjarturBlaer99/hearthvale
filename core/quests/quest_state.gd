class_name QuestState
extends RefCounted
## Where a quest stands, read from game state (docs/TECH_DESIGN.md §7). Pure: the names of the
## flags that record a quest's progress, and its status from a GameState.to_dict() snapshot.
## A quest's current stage is in the snapshot's "quests"; two flags add the rest:
##   quest/<id>/entered   the stage whose on_enter effects were applied (a String)
##   quest/<id>/complete  true once the quest is finished
## Flags are saved, so a load never repeats a stage's rewards.

const NOT_STARTED: StringName = &"not_started"
const ACTIVE: StringName = &"active"
const COMPLETE: StringName = &"complete"
const STATUSES: Array[StringName] = [NOT_STARTED, ACTIVE, COMPLETE]


static func entered_flag(quest_id: StringName) -> StringName:
	return StringName("quest/%s/entered" % quest_id)


static func complete_flag(quest_id: StringName) -> StringName:
	return StringName("quest/%s/complete" % quest_id)


## The status of `quest_id` given a snapshot's "quests" (id -> stage) and "flags" sections.
static func status_in(quests: Dictionary, flags: Dictionary, quest_id: String) -> StringName:
	var done: Variant = flags.get(String(complete_flag(StringName(quest_id))), false)
	if typeof(done) == TYPE_BOOL and done:
		return COMPLETE
	return ACTIVE if str(quests.get(quest_id, "")) != "" else NOT_STARTED
