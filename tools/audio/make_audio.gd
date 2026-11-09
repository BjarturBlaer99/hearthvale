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
	"boss_die", "menu_move", "menu_select", "pause", "nope", "cut", "pot",
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
		"cut":
			return Synth.mix(Synth.tone(&"noise", 11000, 3500, 0.09, 0.3, 0.003, 0.06, 0.5, 22), Synth.tone(&"noise", 16000, 16000, 0.03, 0.15, 0.001, 0.02, 0.5, 23), 0.02)
		"pot":
			var crack: PackedFloat32Array = Synth.mix(Synth.tone(&"noise", 4500, 900, 0.16, 0.4, 0.001, 0.1, 0.5, 24), Synth.tone(&"square", 640, 220, 0.06, 0.18, 0.001, 0.04, 0.25))
			return Synth.mix(crack, Synth.tone(&"noise", 7000, 5000, 0.05, 0.2, 0.001, 0.04, 0.5, 25), 0.09)
		"nope":
			return Synth.join([Synth.tone(&"square", 185, 185, 0.08, 0.25, 0.002, 0.02), Synth.tone(&"square", 147, 147, 0.13, 0.25, 0.002, 0.08)])
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
