class_name StoryGates
extends RefCounted
## The flags the story's gates turn on (P4a; docs/GDD.md §9). Pure. The gates themselves are
## data: Elder Bram's conversation, the main quest, and two doors that open on a flag.
##   planted_first_crop  the hero has put a first seed in his plot: Elder Bram speaks of the keep
##   keep_gate_open      Bram has had the chain taken off the Old Keep's gate
##   keep_warden_beaten  the Iron Warden has fallen
##   crypt_open          the dawn after: the bars under the chapel are up

const FIRST_CROP: StringName = &"planted_first_crop"
const KEEP_GATE: StringName = &"keep_gate_open"
const WARDEN_BEATEN: StringName = &"keep_warden_beaten"
const CRYPT_OPEN: StringName = &"crypt_open"


## The flags of a game saved before the gates were there (`flags`: name -> value, as a save
## holds them), put past them: the first crop counts as planted and the keep's gate is open,
## and the crypt's bars are up if the Warden has fallen. Returns a new Dictionary.
static func past_the_gates(flags: Dictionary) -> Dictionary:
	var out: Dictionary = flags.duplicate(true)
	out[String(FIRST_CROP)] = true
	out[String(KEEP_GATE)] = true
	var beaten: Variant = out.get(String(WARDEN_BEATEN), false)
	if typeof(beaten) == TYPE_BOOL and beaten:
		out[String(CRYPT_OPEN)] = true
	return out
