class_name DayClock
extends RefCounted
## The rules of the day (P2a, GDD §6), read from data (data/rules/time.json): when a day starts
## and ends, how fast the clock runs, the colour of the light at each hour, when lamps are lit
## and when it is night. Pure: it keeps no time itself. GameState holds the day and the minute
## and asks this how they move on.
##
## A time is a number of minutes since the midnight the day began on. The small hours carry on
## past 1440, so 02:00 at the end of a day that began at 06:00 is 1560, and a day's times only
## ever go up.

const DAY: int = 1440
## The clock on the HUD moves in steps of this many minutes.
const SHOWN_STEP: int = 10
## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {
	"day_starts": "06:00", "day_ends": "02:00", "seconds_per_hour": 42.0,
	"lamps_lit": {"from": "18:30", "to": "06:30"}, "night": {"from": "20:00", "to": "06:00"},
	"light": [{"at": "06:00", "color": [1.0, 1.0, 1.0]}],
}

## When the day starts and ends (minutes), and how many real seconds an hour of it takes.
var starts: int
var ends: int
var seconds_per_hour: float
## The colour of the light at each of these times of the day, in order: [minute, Color].
var lights: Array = []

var _lamps: Vector2i
var _night: Vector2i


func _init(rules: Dictionary = {}) -> void:
	starts = parse(str(rules.get("day_starts", DEFAULTS["day_starts"])))
	ends = in_day(str(rules.get("day_ends", DEFAULTS["day_ends"])))
	seconds_per_hour = maxf(float(rules.get("seconds_per_hour", DEFAULTS["seconds_per_hour"])), 0.001)
	_lamps = _span(rules.get("lamps_lit", DEFAULTS["lamps_lit"]))
	_night = _span(rules.get("night", DEFAULTS["night"]))
	for stop: Variant in rules.get("light", DEFAULTS["light"]):
		var color: Array = (stop as Dictionary)["color"]
		lights.append([in_day(str((stop as Dictionary)["at"])), Color(float(color[0]), float(color[1]), float(color[2]))])


## "HH:MM" as minutes since midnight, or -1 if `text` isn't a time of day.
static func parse(text: String) -> int:
	var parts: PackedStringArray = text.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or parts[1].length() != 2:
		return -1
	var hour: int = int(parts[0])
	var minute: int = int(parts[1])
	if hour < 0 or hour > 23 or minute < 0 or minute > 59:
		return -1
	return hour * 60 + minute


## `minute` as "HH:MM" on a 24-hour clock (the small hours read 00:00 to 05:59 again).
static func format(minute: float) -> String:
	var whole: int = posmod(floori(minute), DAY)
	@warning_ignore("integer_division")
	return "%02d:%02d" % [whole / 60, whole % 60]


## `minute` as the HUD shows it: the last ten minutes passed, so the clock doesn't flicker.
static func shown(minute: float) -> String:
	@warning_ignore("integer_division")
	return format(float(floori(minute) / SHOWN_STEP * SHOWN_STEP))


## The time "HH:MM" within this day: one before the day's start is in the small hours, after
## midnight.
func in_day(text: String) -> int:
	var at: int = parse(text)
	return at + DAY if at < starts else at


## How long a whole day takes, in real seconds.
func length_seconds() -> float:
	return (ends - starts) / 60.0 * seconds_per_hour


## `minute` after `seconds` of real time: it stops at the day's end.
func advance(minute: float, seconds: float) -> float:
	return minf(minute + maxf(seconds, 0.0) * 60.0 / seconds_per_hour, float(ends))


## Whether the day has run out at `minute`.
func is_over(minute: float) -> bool:
	return minute >= float(ends)


## The colour of the light outdoors at `minute`: between two of the rules' times it is between
## their colours.
func light_at(minute: float) -> Color:
	if lights.is_empty():
		return Color.WHITE
	if minute <= float(lights[0][0]):
		return lights[0][1]
	for i: int in range(1, lights.size()):
		if minute <= float(lights[i][0]):
			var share: float = (minute - float(lights[i - 1][0])) / maxf(float(lights[i][0]) - float(lights[i - 1][0]), 1.0)
			return (lights[i - 1][1] as Color).lerp(lights[i][1], share)
	return lights[-1][1]


## Whether lamps are lit at `minute` (from dusk, through the night, to dawn).
func lamps_lit(minute: float) -> bool:
	return _within(minute, _lamps)


## Whether it is night at `minute`.
func is_night(minute: float) -> bool:
	return _within(minute, _night)


## What is wrong with `rules` as a clock's rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for key: String in ["day_starts", "day_ends"]:
		if parse(str(rules.get(key, ""))) < 0:
			out.append("'%s' must be a time of day like \"06:00\"." % key)
	var pace: Variant = rules.get("seconds_per_hour")
	if (typeof(pace) != TYPE_INT and typeof(pace) != TYPE_FLOAT) or float(pace) <= 0.0:
		out.append("'seconds_per_hour' must be a number above 0.")
	for key: String in ["lamps_lit", "night"]:
		var span: Variant = rules.get(key)
		if typeof(span) != TYPE_DICTIONARY or parse(str((span as Dictionary).get("from", ""))) < 0 or parse(str((span as Dictionary).get("to", ""))) < 0:
			out.append("'%s' must have a 'from' and a 'to', each a time of day." % key)
	var light: Variant = rules.get("light")
	if typeof(light) != TYPE_ARRAY or (light as Array).is_empty():
		out.append("'light' must list the colour of the light at one time of day or more.")
		return out
	if not out.is_empty():
		return out
	var starts_at: int = parse(str(rules["day_starts"]))
	var last: int = -1
	for stop: Variant in light:
		var at: int = parse(str((stop as Dictionary).get("at", ""))) if typeof(stop) == TYPE_DICTIONARY else -1
		var color: Variant = (stop as Dictionary).get("color") if typeof(stop) == TYPE_DICTIONARY else null
		if at < 0 or typeof(color) != TYPE_ARRAY or (color as Array).size() != 3:
			out.append("every entry in 'light' needs an 'at' (a time of day) and a 'color' of three numbers.")
			continue
		for part: Variant in color:
			if (typeof(part) != TYPE_INT and typeof(part) != TYPE_FLOAT) or float(part) < 0.0 or float(part) > 1.0:
				out.append("the light at %s: each part of 'color' must be a number from 0 to 1." % stop["at"])
				break
		var in_this_day: int = at + DAY if at < starts_at else at
		if in_this_day <= last:
			out.append("the light at %s is out of order: list the day's light from its start to its end." % stop["at"])
		last = in_this_day
	return out


## A span of the day from the rules ("from" and "to"), as minutes since midnight.
static func _span(rule: Variant) -> Vector2i:
	var span: Dictionary = rule if typeof(rule) == TYPE_DICTIONARY else {}
	return Vector2i(parse(str(span.get("from", "00:00"))), parse(str(span.get("to", "00:00"))))


## Whether the time of day at `minute` is inside `span`, which may run over midnight.
static func _within(minute: float, span: Vector2i) -> bool:
	var of_day: int = posmod(floori(minute), DAY)
	if span.x <= span.y:
		return of_day >= span.x and of_day < span.y
	return of_day >= span.x or of_day < span.y
