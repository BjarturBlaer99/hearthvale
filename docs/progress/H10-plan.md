# H10 — Feel & sound (plan)

Goal (ROADMAP H10): sound effects for every action, a looping tune for each kind of place and the boss, hit-stop,
screen shake and particles, and volume settings. The game should feel better, not noisier.

## Design
- **Made in code, baked to files** (no external assets), like the tiles:
  - `Synth` (`core/audio/`, pure): oscillators (square with duty, triangle, sine, saw), noise, envelopes,
    pitch sweeps, mixing, a note sequencer (`C4:2` = C4 for two eighths, `R` a rest), and PCM16 conversion.
  - `tools/audio/make_audio.gd` holds every sound recipe and the four songs, and bakes them to
    `audio/sfx/<id>.wav` and `audio/music/<id>.wav` (22050 Hz, mono). Edit the sounds in the tool, never the
    WAVs.
- **The songs are original:** short loops of about 16–20 s.
  - village: warm, F major
  - countryside: brisk, G major, with drums
  - dungeon: sparse, A minor
  - boss: fast and driving, E minor

  The title screen plays the village tune.
- **`Audio` autoload:**
  - a pool of effect players on an `SFX` bus, and one looping music player on a `Music` bus (the buses are made
    at start)
  - It listens for `EventBus.sound(id)` and `EventBus.music_requested(id)`. Asking for the tune that's already
    playing doesn't restart it.
- **Who asks for what:** gameplay emits `EventBus.sound(id)` where the action happens:
  - **Combat:** sword, hit, enemy beaten, hero hurt, arrow, bomb set and blast.
  - **Pickups:** coin, heart, item fanfare, heart container or piece.
  - **Doors and puzzles:** door unlocked; a jingle when a puzzle shutter opens; a secret jingle when a cracked
    wall breaks; crystal, block push and plate click.
  - **The Warden:** clink, stomp, gaze, stun and fall.
  - **Menus:** move, select, pause, and a "nope" when something can't be done (no ammo, locked).

  Each area names its `music`. The Warden asks for the boss tune when it wakes, and gives the area's tune back
  when it resets or falls.
- **Juice:**
  - **Hit-stop:** a moment's freeze (`EventBus.hit_stop(seconds)` → the area sets `Engine.time_scale` low, ended
    on real time). It's 0.05 s on a landed hit, longer when the hero is hurt or the Warden is stunned or falls.
  - **Screen shake:** `EventBus.shake(strength, seconds)` → the hero's camera. For bombs, the Warden's stomp and
    fall, and the hero getting hurt.
  - **Bursts:** small drawn particles. Sparks on hits, dust on blasts, pushes and sprinting, sparkle on pickups.
- **Settings:** music volume and effects volume (0–10, default 7), kept with the others.

## Acceptance criteria (from ROADMAP)
- [x] every action above makes its sound (tests listen to `EventBus.sound` while doing each one)
- [x] each area plays its tune and the boss fight its own
- [x] volume settings work and persist
- [x] a playtest says the game feels better, not noisier

## Deliberately not in H10
Positional (stereo) sound, footsteps, voice blips in dialogue, adaptive music, a sound test menu.
