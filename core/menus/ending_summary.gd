class_name EndingSummary
extends RefCounted
## What the ending screen says about the game just finished (docs/TECH_DESIGN.md §12), pure:
## how long it took, the hearts won and the quests finished, and since P4d the days it took, the
## crops grown and the friends made. Works on plain values, so it's tested without the game
## running.

## The flag the game's last conversation sets (data/dialogue/ending_crypt.json).
const FINISHED_FLAG: StringName = &"game_finished"


## The summary's lines. `time_text` is the play time already written out ("1:02:33"). The
## quests line is left out of a game with no quests. `more` adds the lines P4d brought:
## { "days", "crops", "friends", "villagers" }; any left out is not shown, and the friends line
## is left out of a game with no villagers.
static func lines(time_text: String, hearts: int, quests_done: int, quests_total: int, more: Dictionary = {}) -> PackedStringArray:
	var out: PackedStringArray = ["Time played   %s" % time_text, "Hearts   %d" % maxi(hearts, 0)]
	if quests_total > 0:
		out.append("Quests finished   %d of %d" % [clampi(quests_done, 0, quests_total), quests_total])
	if more.has("days"):
		out.append("Days   %d" % maxi(int(more["days"]), 1))
	if more.has("crops"):
		out.append("Crops grown   %d" % maxi(int(more["crops"]), 0))
	var villagers: int = int(more.get("villagers", 0))
	if more.has("friends") and villagers > 0:
		out.append("Friends   %d of %d" % [clampi(int(more["friends"]), 0, villagers), villagers])
	return out


## How many of `quest_ids` are complete, by the game's quest stages and flags (QuestState).
static func quests_done(quest_ids: Array, quests: Dictionary, flags: Dictionary) -> int:
	var done: int = 0
	for quest_id: Variant in quest_ids:
		if QuestState.status_in(quests, flags, str(quest_id)) == QuestState.COMPLETE:
			done += 1
	return done


## Whether `flags` (the game's, or a save's) say the game was finished.
static func is_finished(flags: Dictionary) -> bool:
	return flags.get(String(FINISHED_FLAG), false) == true
