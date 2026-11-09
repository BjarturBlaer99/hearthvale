class_name Synth
extends RefCounted
## Makes sounds from numbers (docs/TECH_DESIGN.md §13): oscillators, noise, envelopes, mixing
## and a note sequencer. Pure. Samples are floats from -1 to 1, RATE per second, mono.
## tools/audio/make_audio.gd uses it to bake the game's sound effects and music to WAV files.
##
## Notes are written "C4:2": a note name (C, C#, Db ... B), an octave, and a length in eighth
## notes; "R:2" is a rest. Drum tracks use K (kick), S (snare) and H (hi-hat) instead of notes.

const RATE: int = 22050
const WAVES: Array[StringName] = [&"square", &"triangle", &"sine", &"saw", &"noise"]
## Semitones above C for each note name.
const SEMITONES: Dictionary = {
	"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
	"G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11,
}
## A track whose notes are drum hits.
const DRUMS: StringName = &"drums"


## One sound: `wave` sliding from `from_hz` to `to_hz` over `seconds`, at `volume`, faded in over
## `attack` and out over `release` seconds. `duty` is how much of a square wave is high. Noise
## picks a new random level each time its phase wraps, so its pitch sets how bright it sounds;
## `seed` makes it the same every time.
static func tone(wave: StringName, from_hz: float, to_hz: float, seconds: float, volume: float = 0.5,
		attack: float = 0.005, release: float = 0.05, duty: float = 0.5, seed: int = 1) -> PackedFloat32Array:
	var count: int = maxi(int(seconds * RATE), 0)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var phase: float = 0.0
	var held: float = rng.randf_range(-1.0, 1.0)
	for i: int in count:
		var hz: float = lerpf(from_hz, to_hz, float(i) / maxf(count, 1))
		var next: float = phase + hz / RATE
		if next >= 1.0:
			next -= floorf(next)
			held = rng.randf_range(-1.0, 1.0)
		phase = next
		var sample: float
		match wave:
			&"square":
				sample = 1.0 if phase < duty else -1.0
			&"triangle":
				sample = 1.0 - 4.0 * absf(phase - 0.5)
			&"sine":
				sample = sin(phase * TAU)
			&"saw":
				sample = 2.0 * phase - 1.0
			_:
				sample = held
		out[i] = sample * volume * envelope(i, count, attack, release)
	return out


## The gain of sample `index` of `count`: rising over `attack` seconds, falling over `release`.
static func envelope(index: int, count: int, attack: float, release: float) -> float:
	var rise: float = minf(1.0, index / maxf(attack * RATE, 1.0))
	var fall: float = minf(1.0, (count - index) / maxf(release * RATE, 1.0))
	return clampf(minf(rise, fall), 0.0, 1.0)


static func silence(seconds: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(maxi(int(seconds * RATE), 0))
	return out


## `base` with `part` added in, starting `at` seconds in (it grows to fit).
static func mix(base: PackedFloat32Array, part: PackedFloat32Array, at: float = 0.0) -> PackedFloat32Array:
	var out: PackedFloat32Array = base.duplicate()
	var start: int = int(at * RATE)
	if out.size() < start + part.size():
		out.resize(start + part.size())
	for i: int in part.size():
		out[start + i] += part[i]
	return out


## Pieces one after another.
static func join(parts: Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	for part: PackedFloat32Array in parts:
		out.append_array(part)
	return out


## The pitch of a note name like "A4" (440 Hz) or "F#5"; 0 for a rest or anything unreadable.
static func note_hz(note: String) -> float:
	if note.length() < 2:
		return 0.0
	var name: String = note.substr(0, note.length() - 1)
	var octave: String = note.substr(note.length() - 1)
	if not SEMITONES.has(name) or not octave.is_valid_int():
		return 0.0
	var midi: int = 12 * (int(octave) + 1) + int(SEMITONES[name])
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## How long `notes` lasts, in eighth notes.
static func eighths(notes: String) -> int:
	var total: int = 0
	for token: String in notes.split(" ", false):
		total += int(token.get_slice(":", 1))
	return total


## A line of notes ("C4:2 E4:2 R:4") at `bpm`, played on `wave` (or DRUMS). Each note sounds for
## `legato` of its length.
static func sequence(notes: String, bpm: float, wave: StringName, volume: float, duty: float = 0.5,
		legato: float = 0.9) -> PackedFloat32Array:
	var eighth: float = 60.0 / bpm / 2.0
	var out: PackedFloat32Array = PackedFloat32Array()
	var hit: int = 0
	for token: String in notes.split(" ", false):
		var length: float = int(token.get_slice(":", 1)) * eighth
		var name: String = token.get_slice(":", 0)
		var sound: PackedFloat32Array
		if wave == DRUMS:
			hit += 1
			sound = _drum(name, volume, hit)
		else:
			var hz: float = note_hz(name)
			sound = tone(wave, hz, hz, length * legato, volume, 0.006, minf(0.06, length * 0.4), duty) if hz > 0.0 else PackedFloat32Array()
		var slot: PackedFloat32Array = silence(length)
		for i: int in mini(sound.size(), slot.size()):
			slot[i] = sound[i]
		out.append_array(slot)
	return out


## A song: each track {"wave", "volume", "duty"?, "notes"} played together at `bpm`, then kept
## under `peak`.
static func song(tracks: Array, bpm: float, peak: float = 0.9) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	for track: Dictionary in tracks:
		out = mix(out, sequence(str(track["notes"]), bpm, StringName(str(track["wave"])),
			float(track.get("volume", 0.25)), float(track.get("duty", 0.5))))
	return limit(out, peak)


## The loudest sample's level.
static func loudest(samples: PackedFloat32Array) -> float:
	var top: float = 0.0
	for sample: float in samples:
		top = maxf(top, absf(sample))
	return top


## `samples` scaled down, if need be, so nothing is louder than `peak`.
static func limit(samples: PackedFloat32Array, peak: float = 0.9) -> PackedFloat32Array:
	var top: float = loudest(samples)
	if top <= peak or top == 0.0:
		return samples
	var out: PackedFloat32Array = samples.duplicate()
	var scale: float = peak / top
	for i: int in out.size():
		out[i] *= scale
	return out


## 16-bit little-endian PCM, as a WAV file holds it.
static func to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(samples.size() * 2)
	for i: int in samples.size():
		out.encode_s16(i * 2, int(round(clampf(samples[i], -1.0, 1.0) * 32767.0)))
	return out


static func _drum(name: String, volume: float, hit: int) -> PackedFloat32Array:
	match name:
		"K":
			return tone(&"sine", 150.0, 45.0, 0.14, volume * 1.6, 0.002, 0.08)
		"S":
			return tone(&"noise", 9000.0, 6000.0, 0.11, volume, 0.002, 0.08, 0.5, hit)
		"H":
			return tone(&"noise", 20000.0, 20000.0, 0.035, volume * 0.5, 0.001, 0.03, 0.5, hit)
	return PackedFloat32Array()
