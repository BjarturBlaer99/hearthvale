class_name EndingSummary
extends RefCounted
## What the ending screen says about the game just finished (docs/TECH_DESIGN.md §12), pure:
## how long it took, the hearts won and the quests finished. Works on plain values, so it's
## tested without the game running.


## The summary's lines. `time_text` is the play time already written out ("1:02:33"). The
## quests line is left out of a game with no quests.
static func lines(time_text: String, hearts: int, quests_done: int, quests_total: int) -> PackedStringArray:
	var out: PackedStringArray = ["Time played   %s" % time_text, "Hearts   %d" % maxi(hearts, 0)]
	if quests_total > 0:
		out.append("Quests finished   %d of %d" % [clampi(quests_done, 0, quests_total), quests_total])
	return out


## How many of `quest_ids` are complete, by the game's quest stages and flags (QuestState).
static func quests_done(quest_ids: Array, quests: Dictionary, flags: Dictionary) -> int:
	var done: int = 0
	for quest_id: Variant in quest_ids:
		if QuestState.status_in(quests, flags, str(quest_id)) == QuestState.COMPLETE:
			done += 1
	return done
