class_name Hours
extends RefCounted
## Who keeps what hours (P2e, GDD §6), read from data (data/rules/hours.json): when a place is
## open (a shop's door, by the place's id), and when villagers who stand outdoors are out.
## Pure: it is told the time of day (minutes, as DayClock counts them) and answers.

## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {"outdoors": {"from": "06:00", "to": "20:00"}}
## What is said at a shut door that has no words of its own.
const SHUT_WORDS: String = "It is shut."

## place id -> its hours as minutes since midnight (from, to).
var _open: Dictionary = {}
## place id -> what is said at its door when it is shut.
var _shut_words: Dictionary = {}
var _outdoors: Vector2i


func _init(rules: Dictionary = {}) -> void:
	_outdoors = DayClock.span_of(rules.get("outdoors", DEFAULTS["outdoors"]))
	var places: Variant = rules.get("places", {})
	if typeof(places) != TYPE_DICTIONARY:
		return
	for place: Variant in places:
		_open[str(place)] = DayClock.span_of(places[place])
		_shut_words[str(place)] = str((places[place] as Dictionary).get("shut", SHUT_WORDS))


## Whether `place` is open at `minute`. A place the rules don't name keeps no hours: it is
## always open.
func is_open(place: StringName, minute: float) -> bool:
	if not _open.has(String(place)):
		return true
	return DayClock.within(minute, _open[String(place)])


## What is said at `place`'s door when it is shut.
func shut_words(place: StringName) -> String:
	return str(_shut_words.get(String(place), SHUT_WORDS))


## Whether villagers who stand outdoors are out at `minute` (they go home for the night).
func villagers_out(minute: float) -> bool:
	return DayClock.within(minute, _outdoors)


## What is wrong with `rules` as hours, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	if not _is_span(rules.get("outdoors")):
		out.append("'outdoors' must have a 'from' and a 'to', each a time of day.")
	var places: Variant = rules.get("places")
	if typeof(places) != TYPE_DICTIONARY:
		out.append("'places' must be an object: a place's id, then its hours.")
		return out
	for place: Variant in places:
		if not _is_span(places[place]):
			out.append("place '%s' must have a 'from' and a 'to', each a time of day." % place)
		elif typeof((places[place] as Dictionary).get("shut", "")) != TYPE_STRING:
			out.append("place '%s': 'shut' must be the words said at its door." % place)
	return out


static func _is_span(rule: Variant) -> bool:
	if typeof(rule) != TYPE_DICTIONARY:
		return false
	return DayClock.parse(str((rule as Dictionary).get("from", ""))) >= 0 and DayClock.parse(str((rule as Dictionary).get("to", ""))) >= 0
