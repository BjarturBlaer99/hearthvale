extends GdUnitTestSuite
## Synth: tones last as long as asked and stay within their volume, fading in and out; notes
## have the right pitch; sequences and songs last their written length and never clip; noise
## is the same every time; PCM16 holds two bytes a sample.

const RATE: int = Synth.RATE


func test_a_tone_lasts_its_length_stays_within_its_volume_and_fades_at_both_ends() -> void:
	for wave: StringName in Synth.WAVES:
		var samples: PackedFloat32Array = Synth.tone(wave, 440.0, 440.0, 0.5, 0.4, 0.01, 0.05)
		assert_int(samples.size()).is_equal(RATE / 2)
		assert_float(Synth.loudest(samples)).override_failure_message("%s within its volume" % wave).is_less_equal(0.4001)
		assert_float(absf(samples[0])).override_failure_message("%s fades in" % wave).is_less(0.01)
		assert_float(absf(samples[samples.size() - 1])).override_failure_message("%s fades out" % wave).is_less(0.01)
	assert_float(Synth.loudest(Synth.tone(&"square", 440.0, 440.0, 0.2, 0.4))).override_failure_message("a square reaches its volume").is_equal_approx(0.4, 0.001)


func test_noise_is_the_same_every_time_for_a_seed() -> void:
	var a: PackedFloat32Array = Synth.tone(&"noise", 9000.0, 9000.0, 0.1, 0.5, 0.0, 0.0, 0.5, 7)
	var b: PackedFloat32Array = Synth.tone(&"noise", 9000.0, 9000.0, 0.1, 0.5, 0.0, 0.0, 0.5, 7)
	var c: PackedFloat32Array = Synth.tone(&"noise", 9000.0, 9000.0, 0.1, 0.5, 0.0, 0.0, 0.5, 8)
	assert_bool(a == b).is_true()
	assert_bool(a == c).override_failure_message("another seed, another noise").is_false()


func test_notes_have_their_pitch() -> void:
	assert_float(Synth.note_hz("A4")).is_equal_approx(440.0, 0.001)
	assert_float(Synth.note_hz("C4")).is_equal_approx(261.626, 0.01)
	assert_float(Synth.note_hz("F#5")).is_equal_approx(739.989, 0.01)
	assert_float(Synth.note_hz("Bb1")).is_equal_approx(Synth.note_hz("A#1"), 0.0001)
	assert_float(Synth.note_hz("R")).is_equal(0.0)
	assert_float(Synth.note_hz("H9")).is_equal(0.0)


func test_a_sequence_lasts_its_written_length() -> void:
	var notes: String = "C4:2 E4:2 R:2 G4:2 K:0"
	assert_int(Synth.eighths(notes)).is_equal(8)
	# At 120 bpm an eighth is a quarter of a second: eight of them, two seconds.
	assert_int(Synth.sequence("C4:2 E4:2 R:2 G4:2", 120.0, &"square", 0.3).size()).is_equal(RATE * 2)
	assert_int(Synth.sequence("K:2 S:2 H:2 S:2", 120.0, Synth.DRUMS, 0.3).size()).is_equal(RATE * 2)


func test_a_song_mixes_its_tracks_and_never_clips() -> void:
	var tracks: Array = [
		{"wave": "square", "volume": 0.9, "notes": "C4:4 G4:4"},
		{"wave": "triangle", "volume": 0.9, "notes": "C3:8"},
		{"wave": "drums", "volume": 0.9, "notes": "K:2 S:2 K:2 S:2"},
	]
	var samples: PackedFloat32Array = Synth.song(tracks, 120.0)
	assert_int(samples.size()).is_equal(RATE * 2)
	assert_float(Synth.loudest(samples)).override_failure_message("kept under the peak").is_less_equal(0.9001)


func test_mixing_lines_up_and_grows() -> void:
	var base: PackedFloat32Array = Synth.silence(0.1)
	var part: PackedFloat32Array = PackedFloat32Array([0.5, 0.5])
	var out: PackedFloat32Array = Synth.mix(base, part, 0.2)
	assert_int(out.size()).is_equal(int(0.2 * RATE) + 2)
	assert_float(out[int(0.2 * RATE)]).is_equal(0.5)
	assert_int(Synth.join([part, part]).size()).is_equal(4)


func test_pcm16_holds_two_bytes_a_sample_at_full_scale() -> void:
	var pcm: PackedByteArray = Synth.to_pcm16(PackedFloat32Array([1.0, -1.0, 0.0, 2.0]))
	assert_int(pcm.size()).is_equal(8)
	assert_int(pcm.decode_s16(0)).is_equal(32767)
	assert_int(pcm.decode_s16(2)).is_equal(-32767)
	assert_int(pcm.decode_s16(4)).is_equal(0)
	assert_int(pcm.decode_s16(6)).override_failure_message("clipped, not wrapped").is_equal(32767)
