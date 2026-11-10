class_name ArenaBoss
extends Enemy
## What every dungeon boss shares (docs/TECH_DESIGN.md §5): it keeps to `arena`, its room's
## floor in cells, fights only while the hero is in it, and starts the fight over (full health,
## back home) the moment they leave. Its fight has its own tune, and what it shoots are glowing
## bolts. Give it a `clear_flag` and `stays_beaten`: the flag records it beaten (a heart
## container and the way on wait on it), and it never returns. Subclasses bring the brain's
## particulars: Boss (the Iron Warden) and ShadeBoss (the Crypt Shade).

## Kept clear of the arena's edges (px), for its bulk.
const ARENA_MARGIN: float = 14.0

## Its room's floor, in cells: where it may go and where the hero must be for it to fight.
@export var arena: Rect2i
## The tune for its fight, and the one to go back to when it calms or falls (the area sets it).
@export var fight_music: StringName = &"boss"
var calm_music: StringName = &""

var _awake: bool = false


## The arena in area pixels, less its bulk.
func arena_pixels() -> Rect2:
	return Rect2(Vector2(arena.position) * GridBody.TILE, Vector2(arena.size) * GridBody.TILE).grow(-ARENA_MARGIN)


func hero_in_arena() -> bool:
	return target != null and arena.has_point(GridBody.cell_of(target.position))


## Fights while the hero is in its room; the moment they leave, it starts over.
func step(delta: float) -> void:
	if brain == null or brain.is_dead():
		return
	if hero_in_arena():
		super(delta)
		_fight(delta)
		return
	if brain.state != EnemyBrain.IDLE or brain.health < brain.max_health or body.position != brain.home:
		_start_over()
		position = body.position
		queue_redraw()
	if _awake:
		_awake = false
		EventBus.music_requested.emit(calm_music)


## The fight has begun: its tune starts (once).
func wake() -> void:
	if _awake:
		return
	_awake = true
	EventBus.music_requested.emit(fight_music)


func death_sound() -> StringName:
	return &"boss_die"


## One more frame of the fight, after the brain's (subclasses: stomps, checking the lights).
func _fight(_delta: float) -> void:
	pass


## Puts the brain, and anything of the room's it changed, back to the start (subclasses).
func _start_over() -> void:
	pass


func _die() -> void:
	super()
	EventBus.hit_stop.emit(0.3)
	EventBus.shake.emit(4.0, 0.8)
	_awake = false
	EventBus.music_requested.emit(calm_music)


## Its shots are bolts: glowing orbs.
func _on_shot(direction: Vector2) -> void:
	var shot: Dictionary = data.get("shot", {})
	var bolt: Arrow = Arrow.new()
	bolt.setup(terrain, direction, int(shot.get("damage", 2)), float(shot.get("speed", 110.0)))
	bolt.bolt = true
	bolt.position = body.position + direction * 10.0
	get_parent().add_child(bolt)
	last_arrow = bolt
