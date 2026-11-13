extends Node
## Runs the game's quests (docs/TECH_DESIGN.md §7): a QuestRunner over every quest in
## data/quests, against GameState. Whenever a flag, an item or a quest's stage changes, it lets
## the runner apply what's due, and each morning too (a stage may wait for a day to pass). It
## announces quests starting, moving on and finishing
## (EventBus.quest_announced) with a sound. It holds no state: progress is in GameState.

var runner: QuestRunner

var _busy: bool = false
## Whether this refresh has chimed already. A quest catching up (an older save, a playtest
## scenario) can enter several stages at once: every one is announced, but it chimes once.
var _chimed: bool = false


func _ready() -> void:
	var quests: Dictionary = {}
	for quest: Dictionary in DataRegistry.entries(&"quests"):
		quests[StringName(str(quest["id"]))] = quest
	runner = QuestRunner.new(quests, GameState)
	runner.stage_entered.connect(_on_stage_entered)
	EventBus.flag_set.connect(func(_flag: StringName, _value: Variant) -> void: refresh())
	EventBus.item_added.connect(func(_item: StringName, _count: int) -> void: refresh())
	EventBus.quest_updated.connect(func(_quest: StringName) -> void: refresh())
	EventBus.day_started.connect(func(_day: int) -> void: refresh())


## Lets the runner apply what's due. Changes it makes come straight back here as signals; the
## update already running picks those up, so they're let through.
func refresh() -> void:
	# No game, no quests: the main quest begins with a game, not on the title screen.
	if _busy or not GameState.is_started():
		return
	_busy = true
	_chimed = false
	runner.update()
	_busy = false
	_chimed = false


## "New quest: The Lost Shuttle" and the like, for a notice on screen.
func announcement(quest_id: StringName, what: StringName) -> String:
	match what:
		&"started":
			return "New quest: %s" % runner.title(quest_id)
		&"completed":
			return "Quest complete: %s" % runner.title(quest_id)
	return "Quest updated: %s" % runner.title(quest_id)


func _on_stage_entered(quest_id: StringName, _stage_id: StringName, first: bool, completed: bool) -> void:
	var what: StringName = &"completed" if completed else (&"started" if first else &"updated")
	if not _chimed:
		EventBus.sound.emit(&"item_get" if completed else &"quest")
	_chimed = _busy
	EventBus.quest_announced.emit(quest_id, what)
