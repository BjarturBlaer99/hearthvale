extends SceneTree
## Bakes the game's sound effects and music to WAV files, made in code with Synth (no external
## assets; docs/TECH_DESIGN.md §13). Edit the sounds here, never the WAVs, then bake and import:
##   godot --headless --path . -s res://tools/audio/make_audio.gd [-- <id> ...]
##   godot --headless --path . --import
## Effects go to audio/sfx/<id>.wav, songs to audio/music/<id>.wav (22050 Hz, mono, 16-bit).
## The songs are original: short loops, one per kind of place plus the boss.

const SFX_DIR: String = "res://audio/sfx"
const MUSIC_DIR: String = "res://audio/music"

## Every sound effect (Audio.SFX must list the same ids; a test checks).
const SFX: Array[String] = [
	"sword", "hit", "enemy_die", "hurt", "heart", "coin", "item_get", "heart_get", "door", "solved",
	"secret", "arrow", "bomb_set", "bomb", "crystal", "push", "plate", "clink", "stomp", "gaze", "stun",
	"boss_die", "menu_move", "menu_select", "pause", "nope", "cut", "pot", "quest",
	"torch", "snuff", "fall", "sink", "whiff", "eat", "morning", "collapse",
	"hoe", "pour", "fill", "plant", "harvest", "skill", "friend",
	"wisp_flare", "wisp_dart",
	"pick", "rock_break", "lift", "craft", "furnace",
]

## Each song: tempo, bars (4/4; every track must last bars x 8 eighths), and its tracks.
const SONGS: Dictionary = {
	# Warm and easy, F major: | F | C | Dm | Bb | F | C | Bb C | F |
	"village": {"bpm": 100, "bars": 8, "tracks": [
		{"wave": "square", "duty": 0.25, "volume": 0.20, "notes":
			"A4:2 C5:2 F5:3 E5:1 D5:2 C5:2 G4:4 A4:2 D5:2 F5:3 E5:1 D5:4 R:2 C5:2 " +
			"A4:2 C5:2 F5:2 A5:2 G5:3 F5:1 E5:2 C5:2 D5:2 F5:2 E5:2 G5:2 F5:6 R:2"},
		{"wave": "triangle", "volume": 0.32, "notes":
			"F2:4 C3:4 C2:4 G2:4 D2:4 A2:4 A#1:4 F2:4 F2:4 C3:4 C2:4 G2:4 A#1:4 C2:4 F2:4 F2:4"},
		{"wave": "square", "duty": 0.5, "volume": 0.07, "notes":
			"F4:1 A4:1 C5:1 A4:1 F4:1 A4:1 C5:1 A4:1 E4:1 G4:1 C5:1 G4:1 E4:1 G4:1 C5:1 G4:1 " +
			"D4:1 F4:1 A4:1 F4:1 D4:1 F4:1 A4:1 F4:1 D4:1 F4:1 A#4:1 F4:1 D4:1 F4:1 A#4:1 F4:1 " +
			"F4:1 A4:1 C5:1 A4:1 F4:1 A4:1 C5:1 A4:1 E4:1 G4:1 C5:1 G4:1 E4:1 G4:1 C5:1 G4:1 " +
			"D4:1 F4:1 A#4:1 F4:1 E4:1 G4:1 C5:1 G4:1 F4:1 A4:1 C5:1 A4:1 F4:4"},
	]},
	# Brisk and out on the road, G major, with drums: | G | D | Em | C | G | D | C D | G |
	"countryside": {"bpm": 132, "bars": 8, "tracks": [
		{"wave": "square", "duty": 0.25, "volume": 0.19, "notes":
			"G4:1 B4:1 D5:2 D5:1 E5:1 D5:2 A4:2 D5:2 F#5:3 E5:1 E5:2 G5:2 B5:2 G5:2 E5:3 D5:1 C5:2 E5:2 " +
			"D5:1 B4:1 G4:2 B4:1 D5:1 G5:2 F#5:2 E5:2 D5:2 A4:2 C5:2 E5:2 D5:2 F#5:2 G5:4 D5:2 B4:2"},
		{"wave": "triangle", "volume": 0.32, "notes":
			"G2:2 G2:2 G2:2 D2:2 D2:2 D2:2 D2:2 A1:2 E2:2 E2:2 E2:2 B1:2 C2:2 C2:2 C2:2 G1:2 " +
			"G2:2 G2:2 G2:2 D2:2 D2:2 D2:2 D2:2 A1:2 C2:2 C2:2 D2:2 D2:2 G2:2 D2:2 G2:4"},
		{"wave": "drums", "volume": 0.22, "notes":
			"K:2 H:2 S:2 H:2 K:2 H:2 S:2 H:2 K:2 H:2 S:2 H:2 K:2 K:1 H:1 S:2 H:2 " +
			"K:2 H:2 S:2 H:2 K:2 H:2 S:2 H:2 K:2 H:2 S:2 H:2 K:2 S:2 S:2 S:2"},
	]},
	# Still and slow, A minor, for the open air after dark: | Am | F | C | G | Am | Dm | F G | Am |
	"night": {"bpm": 72, "bars": 8, "tracks": [
		{"wave": "triangle", "volume": 0.22, "notes":
			"A4:4 C5:2 E5:2 D5:6 R:2 C5:4 A4:2 G4:2 A4:6 R:2 " +
			"E5:4 D5:2 C5:2 D5:4 A4:4 G4:2 A4:2 C5:2 D5:2 A4:6 R:2"},
		{"wave": "triangle", "volume": 0.26, "notes":
			"A2:8 F2:8 C3:8 G2:8 A2:8 D2:8 F2:4 G2:4 A2:8"},
		{"wave": "square", "duty": 0.125, "volume": 0.04, "notes":
			"R:4 E6:1 R:3 R:4 A5:1 R:3 R:4 G5:1 R:3 R:4 D6:1 R:3 " +
			"R:4 E6:1 R:3 R:4 F5:1 R:3 R:4 C6:1 R:3 R:4 E5:1 R:3"},
	]},
	# Slow and misty, D minor, for Willowmere: | Dm | Dm | Bb | F | Gm | Dm | A | Dm |
	# A soft tune in long notes over a low drone, with a far-off chime off the beat.
	"marsh": {"bpm": 66, "bars": 8, "tracks": [
		{"wave": "triangle", "volume": 0.21, "notes":
			"D5:4 F5:4 A5:6 R:2 G5:2 F5:2 D5:4 C5:6 R:2 " +
			"A#4:4 D5:4 F5:3 E5:1 D5:4 C#5:4 E5:4 D5:6 R:2"},
		{"wave": "triangle", "volume": 0.27, "notes":
			"D2:8 D2:8 A#1:8 F2:8 G2:8 D2:8 A1:8 D2:8"},
		{"wave": "square", "duty": 0.125, "volume": 0.035, "notes":
			"R:3 A5:1 R:4 R:5 F5:1 R:2 R:3 D6:1 R:4 R:5 C6:1 R:2 " +
			"R:3 A#5:1 R:4 R:5 A5:1 R:2 R:3 E6:1 R:4 R:5 D6:1 R:2"},
	]},
	# Slow and hollow, E minor, for the Old Quarry: | Em | Em | C | D | Em | G | Am B | Em |
	# A few long notes with room between them over a low drone, and a far-off tapping.
	"mine": {"bpm": 60, "bars": 8, "tracks": [
		{"wave": "triangle", "volume": 0.20, "notes":
			"E4:4 R:4 G4:2 B4:2 A4:4 G4:4 E4:2 R:2 F#4:4 D4:4 " +
			"E4:2 G4:2 B4:4 D5:4 B4:2 R:2 C5:2 A4:2 B4:4 E4:6 R:2"},
		{"wave": "triangle", "volume": 0.27, "notes":
			"E2:8 E2:8 C2:8 D2:8 E2:8 G2:8 A2:4 B2:4 E2:8"},
		{"wave": "square", "duty": 0.125, "volume": 0.03, "notes":
			"R:2 B5:1 R:5 R:6 E6:1 R:1 R:2 G5:1 R:5 R:6 A5:1 R:1 " +
			"R:2 B5:1 R:5 R:6 D6:1 R:1 R:2 E5:1 R:5 R:6 B5:1 R:1"},
	]},
	# The hero's own land (the Homestead), by day: unhurried and at ease, D major:
	# | D | A | Bm | G | D | G | A | D |. A plain tune over a walking bass and a soft
	# broken chord, with no drums: slower than the village's and a step lower in the voice.
	"homestead": {"bpm": 92, "bars": 8, "tracks": [
		{"wave": "square", "duty": 0.25, "volume": 0.17, "notes":
			"F#4:2 A4:2 D5:3 E5:1 C#5:2 A4:2 E5:4 D5:2 F#5:2 B4:3 D5:1 B4:2 G4:2 D5:2 R:2 " +
			"F#4:2 A4:2 D5:2 F#5:2 G5:3 F#5:1 E5:2 D5:2 E5:2 C#5:2 A4:2 E5:2 D5:6 R:2"},
		{"wave": "triangle", "volume": 0.30, "notes":
			"D2:4 A2:4 A1:4 E2:4 B1:4 F#2:4 G1:4 D2:4 D2:4 A2:4 G1:4 D2:4 A1:4 E2:4 D2:4 D2:4"},
		{"wave": "square", "duty": 0.5, "volume": 0.055, "notes":
			"D4:1 F#4:1 A4:1 F#4:1 D4:1 F#4:1 A4:1 F#4:1 C#4:1 E4:1 A4:1 E4:1 C#4:1 E4:1 A4:1 E4:1 " +
			"B3:1 D4:1 F#4:1 D4:1 B3:1 D4:1 F#4:1 D4:1 B3:1 D4:1 G4:1 D4:1 B3:1 D4:1 G4:1 D4:1 " +
			"D4:1 F#4:1 A4:1 F#4:1 D4:1 F#4:1 A4:1 F#4:1 B3:1 D4:1 G4:1 D4:1 B3:1 D4:1 G4:1 D4:1 " +
			"C#4:1 E4:1 A4:1 E4:1 C#4:1 E4:1 A4:1 E4:1 D4:1 F#4:1 A4:1 F#4:1 D4:4"},
	]},
	# The same land after dark: the day's tune in long notes, quieter than the game's own
	# night tune (every voice is lower in volume), D major: | D | Bm | G | A | D | G | Em A | D |.
	"homestead_night": {"bpm": 66, "bars": 8, "tracks": [
		{"wave": "triangle", "volume": 0.16, "notes":
			"F#4:4 A4:4 D5:6 R:2 B4:4 G4:4 A4:6 R:2 " +
			"F#4:4 D5:4 B4:6 R:2 G4:4 E4:4 D4:6 R:2"},
		{"wave": "triangle", "volume": 0.20, "notes":
			"D2:8 B1:8 G1:8 A1:8 D2:8 G1:8 E2:4 A1:4 D2:8"},
		{"wave": "square", "duty": 0.125, "volume": 0.025, "notes":
			"R:5 A5:1 R:2 R:3 F#5:1 R:4 R:5 D6:1 R:2 R:3 E5:1 R:4 " +
			"R:5 A5:1 R:2 R:3 B5:1 R:4 R:5 G5:1 R:2 R:3 D5:1 R:4"},
	]},
	# Sparse and watchful, A minor: | Am | F | G | Em | Am | F | Dm E | Am |
	"dungeon": {"bpm": 84, "bars": 8, "tracks": [
		{"wave": "triangle", "volume": 0.24, "notes":
			"E4:3 R:1 A4:2 C5:2 B4:4 R:2 A4:2 G4:3 R:1 B4:2 D5:2 E5:6 R:2 " +
			"C5:3 R:1 B4:2 A4:2 F4:4 R:2 A4:2 D5:2 C5:2 B4:2 G#4:2 A4:6 R:2"},
		{"wave": "triangle", "volume": 0.30, "notes":
			"A2:8 F2:8 G2:8 E2:8 A2:8 F2:8 D2:4 E2:4 A2:8"},
		{"wave": "square", "duty": 0.125, "volume": 0.05, "notes":
			"A5:1 R:3 E5:1 R:3 A5:1 R:3 C6:1 R:3 G5:1 R:3 D5:1 R:3 B5:1 R:3 G5:1 R:3 " +
			"A5:1 R:3 E5:1 R:3 F5:1 R:3 A5:1 R:3 D5:1 R:3 F5:1 R:3 E5:1 R:3 B5:1 R:3"},
	]},
	# Fast and driving, E minor: | Em | Em | C | D | Em | Em | C | B |
	"boss": {"bpm": 150, "bars": 8, "tracks": [
		{"wave": "square", "duty": 0.25, "volume": 0.18, "notes":
			"B4:2 E5:2 G5:2 F#5:2 E5:4 B4:4 C5:2 E5:2 G5:2 A5:2 F#5:4 D5:4 " +
			"B4:2 E5:2 G5:2 B5:2 A5:2 G5:2 F#5:2 E5:2 G5:2 F#5:2 E5:2 C5:2 D#5:4 B4:4"},
		{"wave": "saw", "volume": 0.16, "notes":
			"E2:1 E2:1 E3:1 E2:1 E2:1 E2:1 D3:1 E2:1 E2:1 E2:1 E3:1 E2:1 E2:1 E2:1 D3:1 E2:1 " +
			"C2:1 C2:1 C3:1 C2:1 C2:1 C2:1 B2:1 C2:1 D2:1 D2:1 D3:1 D2:1 D2:1 D2:1 C3:1 D2:1 " +
			"E2:1 E2:1 E3:1 E2:1 E2:1 E2:1 D3:1 E2:1 E2:1 E2:1 E3:1 E2:1 E2:1 E2:1 D3:1 E2:1 " +
			"C2:1 C2:1 C3:1 C2:1 C2:1 C2:1 B2:1 C2:1 B1:1 B1:1 B2:1 B1:1 B1:1 B1:1 A2:1 B1:1"},
		{"wave": "drums", "volume": 0.22, "notes":
			"K:2 S:2 K:1 K:1 S:2 K:2 S:2 K:1 K:1 S:2 K:2 S:2 K:1 K:1 S:2 K:2 S:2 K:1 S:1 S:2 " +
			"K:2 S:2 K:1 K:1 S:2 K:2 S:2 K:1 K:1 S:2 K:2 S:2 K:1 K:1 S:2 K:1 S:1 S:1 S:1 S:1 S:1 S:1 S:1"},
	]},
}


func _initialize() -> void:
	var wanted: PackedStringArray = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(SFX_DIR)
	DirAccess.make_dir_recursive_absolute(MUSIC_DIR)
	var failed: bool = false
	for id: String in SFX:
		if wanted.is_empty() or wanted.has(id):
			failed = _save(SFX_DIR.path_join(id + ".wav"), effect(id)) != OK or failed
	for id: String in SONGS:
		if not wanted.is_empty() and not wanted.has(id):
			continue
		var song: Dictionary = SONGS[id]
		for track: Dictionary in song["tracks"]:
			var length: int = Synth.eighths(str(track["notes"]))
			if length != int(song["bars"]) * 8:
				push_error("tools/audio: song '%s' has a %s track of %d eighths, not %d" % [id, track["wave"], length, int(song["bars"]) * 8])
				failed = true
		failed = _save(MUSIC_DIR.path_join(id + ".wav"), Synth.song(song["tracks"], float(song["bpm"]))) != OK or failed
	quit(1 if failed else 0)


## The samples for sound effect `id`.
static func effect(id: String) -> PackedFloat32Array:
	match id:
		"sword":
			return Synth.mix(Synth.tone(&"noise", 7000, 1800, 0.13, 0.35, 0.01, 0.09, 0.5, 11), Synth.tone(&"square", 900, 450, 0.06, 0.08, 0.002, 0.04, 0.25))
		"hit":
			return Synth.mix(Synth.tone(&"square", 520, 170, 0.09, 0.38), Synth.tone(&"noise", 9000, 5000, 0.04, 0.25, 0.001, 0.03, 0.5, 12))
		"enemy_die":
			return Synth.mix(Synth.tone(&"square", 620, 70, 0.28, 0.3, 0.003, 0.12, 0.25), Synth.tone(&"noise", 5000, 600, 0.28, 0.22, 0.003, 0.15, 0.5, 13))
		"hurt":
			return Synth.mix(Synth.tone(&"square", 320, 110, 0.2, 0.36), Synth.tone(&"square", 300, 100, 0.2, 0.2), 0.015)
		"heart":
			return Synth.join([Synth.tone(&"triangle", 659, 659, 0.06, 0.4), Synth.tone(&"triangle", 831, 831, 0.06, 0.4), Synth.tone(&"triangle", 988, 988, 0.12, 0.4, 0.005, 0.08)])
		"coin":
			return Synth.join([Synth.tone(&"square", 988, 988, 0.05, 0.25, 0.002, 0.01, 0.25), Synth.tone(&"square", 1319, 1319, 0.16, 0.25, 0.002, 0.12, 0.25)])
		"item_get":
			var fanfare: PackedFloat32Array = Synth.join([_note("C5", 0.1), _note("E5", 0.1), _note("G5", 0.1), _note("C6", 0.4, 0.3)])
			return Synth.mix(fanfare, Synth.tone(&"triangle", 131, 131, 0.7, 0.3, 0.01, 0.2))
		"heart_get":
			var rise: PackedFloat32Array = Synth.join([_note("G4", 0.09), _note("C5", 0.09), _note("E5", 0.09), _note("G5", 0.09), _note("C6", 0.6, 0.45)])
			return Synth.mix(Synth.mix(rise, Synth.tone(&"triangle", 131, 131, 0.96, 0.3, 0.01, 0.3)), Synth.tone(&"triangle", 196, 196, 0.6, 0.18, 0.01, 0.3), 0.36)
		"door":
			return Synth.mix(Synth.tone(&"noise", 500, 150, 0.25, 0.35, 0.002, 0.15, 0.5, 14), Synth.tone(&"square", 110, 65, 0.2, 0.25))
		"solved":
			return Synth.join([_note("C5", 0.08), _note("E5", 0.08), _note("G5", 0.08), _note("B5", 0.08), _note("D6", 0.3, 0.22)])
		"secret":
			return Synth.join([_note("A4", 0.07), _note("C#5", 0.07), _note("E5", 0.07), _note("A5", 0.07), _note("E5", 0.07), _note("A5", 0.35, 0.25)])
		"arrow":
			return Synth.mix(Synth.tone(&"noise", 12000, 3000, 0.1, 0.22, 0.002, 0.06, 0.5, 15), Synth.tone(&"sine", 1500, 900, 0.09, 0.14))
		"bomb_set":
			return Synth.mix(Synth.tone(&"square", 820, 820, 0.03, 0.2, 0.001, 0.01), Synth.tone(&"square", 620, 620, 0.03, 0.2, 0.001, 0.01), 0.06)
		"bomb":
			return Synth.mix(Synth.tone(&"noise", 2600, 180, 0.8, 0.6, 0.002, 0.55, 0.5, 16), Synth.tone(&"sine", 95, 32, 0.45, 0.6, 0.002, 0.3))
		"crystal":
			return Synth.mix(Synth.tone(&"sine", 1568, 1568, 0.45, 0.3, 0.002, 0.4), Synth.tone(&"sine", 2093, 2093, 0.35, 0.15, 0.002, 0.3))
		"push":
			return Synth.tone(&"noise", 320, 200, 0.3, 0.3, 0.05, 0.12, 0.5, 17)
		"plate":
			return Synth.mix(Synth.tone(&"square", 200, 140, 0.05, 0.28), Synth.tone(&"noise", 1600, 1600, 0.03, 0.15, 0.001, 0.02, 0.5, 18))
		"clink":
			var ring: PackedFloat32Array = Synth.mix(Synth.tone(&"square", 1800, 1700, 0.05, 0.2, 0.001, 0.03, 0.1), Synth.tone(&"sine", 2637, 2637, 0.16, 0.16, 0.001, 0.14))
			return Synth.mix(ring, Synth.tone(&"noise", 10000, 10000, 0.02, 0.2, 0.001, 0.015, 0.5, 19))
		"stomp":
			return Synth.mix(Synth.tone(&"sine", 75, 38, 0.2, 0.55, 0.002, 0.12), Synth.tone(&"noise", 700, 200, 0.1, 0.2, 0.002, 0.07, 0.5, 20))
		"gaze":
			return Synth.mix(Synth.tone(&"triangle", 220, 660, 0.6, 0.3, 0.2, 0.15), Synth.tone(&"square", 223, 664, 0.6, 0.07, 0.2, 0.15))
		"stun":
			return Synth.join([Synth.tone(&"square", 900, 300, 0.13, 0.28, 0.002, 0.04, 0.25), Synth.tone(&"square", 700, 240, 0.16, 0.28, 0.002, 0.08, 0.25)])
		"boss_die":
			return Synth.mix(Synth.tone(&"noise", 3200, 90, 1.6, 0.5, 0.005, 1.0, 0.5, 21), Synth.tone(&"square", 420, 40, 1.3, 0.25, 0.005, 0.8))
		"menu_move":
			return Synth.tone(&"square", 700, 700, 0.03, 0.16, 0.001, 0.015, 0.25)
		"menu_select":
			return Synth.join([Synth.tone(&"square", 880, 880, 0.04, 0.2, 0.001, 0.01, 0.25), Synth.tone(&"square", 1320, 1320, 0.07, 0.2, 0.001, 0.05, 0.25)])
		"pause":
			return Synth.join([Synth.tone(&"sine", 660, 660, 0.05, 0.3, 0.002, 0.02), Synth.tone(&"sine", 990, 990, 0.09, 0.3, 0.002, 0.07)])
		"torch":
			# A torch catching: a rising rush of air and a soft bloom.
			return Synth.mix(Synth.tone(&"noise", 2200, 7500, 0.24, 0.3, 0.02, 0.14, 0.5, 31), Synth.tone(&"triangle", 330, 660, 0.14, 0.2, 0.01, 0.08))
		"snuff":
			# A flame going out: a falling puff.
			return Synth.tone(&"noise", 6000, 400, 0.32, 0.3, 0.005, 0.24, 0.5, 32)
		"fall":
			# Down a pit: a long falling whistle.
			return Synth.tone(&"square", 900, 110, 0.5, 0.26, 0.005, 0.22, 0.25)
		"sink":
			# A block dropping into a pit: a deep thud.
			return Synth.mix(Synth.tone(&"square", 150, 45, 0.32, 0.42, 0.002, 0.22, 0.5), Synth.tone(&"noise", 1600, 250, 0.26, 0.3, 0.002, 0.2, 0.5, 34))
		"wisp_flare":
			# A Bogwisp gathering itself: a thin glassy note swelling upward for half a second.
			return Synth.mix(Synth.tone(&"sine", 880, 1760, 0.5, 0.22, 0.3, 0.1), Synth.tone(&"triangle", 1320, 2640, 0.5, 0.08, 0.3, 0.1))
		"wisp_dart":
			# And letting go: a quick falling rush.
			return Synth.mix(Synth.tone(&"sine", 1900, 500, 0.22, 0.24, 0.002, 0.14), Synth.tone(&"noise", 7000, 1800, 0.2, 0.10, 0.002, 0.12, 0.5, 41))
		"pick":
			# Iron on stone: a bright clink over a short thud.
			return Synth.mix(Synth.tone(&"square", 1500, 900, 0.05, 0.20, 0.001, 0.04, 0.25), Synth.tone(&"noise", 3000, 800, 0.08, 0.24, 0.001, 0.06, 0.5, 61))
		"rock_break":
			# A rock giving way: a crack, and the pieces settling.
			return Synth.join([
				Synth.mix(Synth.tone(&"noise", 1800, 300, 0.18, 0.36, 0.001, 0.12, 0.5, 62), Synth.tone(&"square", 170, 60, 0.12, 0.24, 0.001, 0.08, 0.5)),
				Synth.tone(&"noise", 900, 250, 0.12, 0.16, 0.005, 0.10, 0.5, 63),
			])
		"lift":
			# The old lift going down: a low hum sinking under the rattle of its rope.
			return Synth.mix(Synth.tone(&"triangle", 180, 90, 0.6, 0.20, 0.02, 0.3), Synth.tone(&"noise", 1200, 500, 0.6, 0.09, 0.02, 0.3, 0.5, 64))
		"craft":
			# Something made at the workbench: two knocks of a mallet and a bright tap.
			return Synth.join([
				Synth.mix(Synth.tone(&"square", 220, 150, 0.06, 0.26, 0.001, 0.05, 0.5), Synth.tone(&"noise", 1400, 500, 0.06, 0.18, 0.001, 0.05, 0.5, 71)), Synth.silence(0.05),
				Synth.mix(Synth.tone(&"square", 240, 160, 0.06, 0.24, 0.001, 0.05, 0.5), Synth.tone(&"noise", 1500, 500, 0.06, 0.16, 0.001, 0.05, 0.5, 72)), Synth.silence(0.04),
				Synth.tone(&"sine", 1175, 1175, 0.16, 0.20, 0.002, 0.13),
			])
		"furnace":
			# The furnace catching: a low breath that swells into a roar and settles.
			return Synth.mix(Synth.tone(&"noise", 300, 1100, 0.7, 0.24, 0.25, 0.3, 0.5, 73), Synth.tone(&"triangle", 70, 110, 0.7, 0.16, 0.2, 0.3))
		"whiff":
			# A blow passing through the Shade: thin air.
			return Synth.tone(&"noise", 9000, 2500, 0.12, 0.16, 0.02, 0.08, 0.5, 33)
		"cut":
			return Synth.mix(Synth.tone(&"noise", 11000, 3500, 0.09, 0.3, 0.003, 0.06, 0.5, 22), Synth.tone(&"noise", 16000, 16000, 0.03, 0.15, 0.001, 0.02, 0.5, 23), 0.02)
		"pot":
			var crack: PackedFloat32Array = Synth.mix(Synth.tone(&"noise", 4500, 900, 0.16, 0.4, 0.001, 0.1, 0.5, 24), Synth.tone(&"square", 640, 220, 0.06, 0.18, 0.001, 0.04, 0.25))
			return Synth.mix(crack, Synth.tone(&"noise", 7000, 5000, 0.05, 0.2, 0.001, 0.04, 0.5, 25), 0.09)
		"quest":
			return Synth.join([_note("E5", 0.08), _note("A5", 0.08), _note("C#6", 0.22, 0.16)])
		"friend":
			# A friendship grows: two soft steps up and a held note, lower and rounder than a skill's.
			return Synth.join([Synth.tone(&"sine", 392.0, 392.0, 0.09, 0.26, 0.01, 0.04), Synth.tone(&"sine", 494.0, 494.0, 0.09, 0.26, 0.01, 0.04), Synth.tone(&"sine", 587.0, 587.0, 0.30, 0.28, 0.01, 0.22)])
		"skill":
			# A skill rises: three quick steps up a chord and its top note held.
			return Synth.join([_note("C5", 0.06), _note("E5", 0.06), _note("G5", 0.06), _note("C6", 0.26, 0.18)])
		"nope":
			return Synth.join([Synth.tone(&"square", 185, 185, 0.08, 0.25, 0.002, 0.02), Synth.tone(&"square", 147, 147, 0.13, 0.25, 0.002, 0.08)])
		"eat":
			# Two bites and a swallow.
			return Synth.join([
				Synth.tone(&"noise", 1900, 900, 0.07, 0.30, 0.002, 0.04, 0.5, 41), Synth.silence(0.05),
				Synth.tone(&"noise", 1600, 700, 0.08, 0.28, 0.002, 0.05, 0.5, 42), Synth.silence(0.06),
				Synth.tone(&"sine", 300, 420, 0.09, 0.22, 0.01, 0.05),
			])
		"morning":
			# A cock crowing: three rising calls and a long falling one.
			return Synth.join([
				Synth.tone(&"square", 620, 820, 0.09, 0.20, 0.004, 0.02, 0.25), Synth.silence(0.03),
				Synth.tone(&"square", 820, 900, 0.08, 0.20, 0.004, 0.02, 0.25), Synth.silence(0.03),
				Synth.tone(&"square", 900, 1240, 0.17, 0.22, 0.004, 0.03, 0.25),
				Synth.tone(&"square", 1240, 640, 0.42, 0.22, 0.004, 0.26, 0.25),
			])
		"hoe":
			# The blade bites the soil: a dull thud and a scrape.
			return Synth.join([
				Synth.mix(Synth.tone(&"noise", 520, 160, 0.09, 0.34, 0.002, 0.07, 0.5, 51), Synth.tone(&"square", 130, 70, 0.09, 0.22, 0.002, 0.06)),
				Synth.tone(&"noise", 1400, 600, 0.09, 0.16, 0.01, 0.06, 0.5, 52),
			])
		"pour":
			# Water from the can's rose: a soft hiss, and two drops after.
			return Synth.join([
				Synth.tone(&"noise", 2600, 1700, 0.24, 0.17, 0.04, 0.12, 0.5, 53),
				Synth.tone(&"sine", 880, 620, 0.05, 0.12, 0.004, 0.03), Synth.silence(0.04),
				Synth.tone(&"sine", 760, 540, 0.05, 0.10, 0.004, 0.03),
			])
		"fill":
			# The can goes under: three rising gulps.
			return Synth.join([
				Synth.tone(&"sine", 280, 480, 0.08, 0.22, 0.01, 0.04), Synth.silence(0.03),
				Synth.tone(&"sine", 340, 600, 0.08, 0.22, 0.01, 0.04), Synth.silence(0.03),
				Synth.tone(&"sine", 420, 760, 0.11, 0.22, 0.01, 0.07),
			])
		"plant":
			# A seed pressed into the soil: two soft pats.
			return Synth.join([
				Synth.tone(&"noise", 420, 180, 0.06, 0.26, 0.003, 0.045, 0.5, 54), Synth.silence(0.05),
				Synth.tone(&"noise", 360, 150, 0.07, 0.22, 0.003, 0.05, 0.5, 55),
			])
		"harvest":
			# A crop pulled from the soil: a quick rustle up, and a bright little chime.
			return Synth.join([
				Synth.tone(&"noise", 700, 2200, 0.09, 0.20, 0.004, 0.05, 0.5, 56),
				Synth.tone(&"triangle", 660, 660, 0.07, 0.24, 0.004, 0.03),
				Synth.tone(&"triangle", 990, 990, 0.13, 0.24, 0.004, 0.09),
			])
		"collapse":
			# Out of energy: a long sigh downwards, and a soft fall.
			return Synth.join([
				Synth.tone(&"triangle", 520, 150, 0.55, 0.30, 0.02, 0.2),
				Synth.mix(Synth.tone(&"noise", 500, 120, 0.2, 0.32, 0.002, 0.14, 0.5, 43), Synth.tone(&"square", 110, 55, 0.2, 0.25, 0.002, 0.14)),
			])
	push_error("tools/audio: no recipe for sound '%s'" % id)
	return Synth.silence(0.05)


## A bright square note for the jingles: `seconds` long, faded over `release`.
static func _note(note: String, seconds: float, release: float = 0.03) -> PackedFloat32Array:
	var hz: float = Synth.note_hz(note)
	return Synth.tone(&"square", hz, hz, seconds, 0.22, 0.003, release, 0.25)


func _save(path: String, samples: PackedFloat32Array) -> Error:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = Synth.RATE
	stream.stereo = false
	stream.data = Synth.to_pcm16(Synth.limit(samples, 0.9))
	var error: Error = ERR_CANT_CREATE
	for attempt: int in 10:
		error = stream.save_to_wav(ProjectSettings.globalize_path(path))
		if error == OK:
			break
		OS.delay_msec(200)
	print("tools/audio: %s %.2fs (%s)" % [path, samples.size() / float(Synth.RATE), error_string(error)])
	return error
