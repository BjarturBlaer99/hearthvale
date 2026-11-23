class_name Enemy
extends Node2D
## An enemy in an area (docs/TECH_DESIGN.md §5), set up from data/enemies/<enemy_id>.json:
## an EnemyBrain moves a GridBody, and this node follows it and draws a placeholder for its
## behaviour. Its HurtBox takes the sword's hits; its HitBox (contact damage) hurts the hero
## on touch. Archers shoot Arrows. Beaten, it rolls its drop table, leaves the drop where it
## fell (at the foot of the ledge, if it stood on raised ground) and vanishes; it's back on the
## next visit (nothing is saved), unless it `stays_beaten` (a boss). Position = its feet: place
## it at a cell's centre. The area calls setup(). Bosses are the Boss subclass.

signal died(enemy: Enemy)

## A monster met at night shows in the dark: it is drawn in this tint whatever the hour's light.
const NIGHT_TINT: Color = Color(0.86, 0.62, 0.92)
const POOF_TIME: float = 0.35
## How long the game freezes when a blow lands on it.
const HIT_STOP: float = 0.05
const FLASH_TIME: float = 0.15
const SHADOW: Color = Color(0, 0, 0, 0.3)
## How long a Bogwisp takes to rise out of the water as night falls, and to fade as it ends.
const RISE_TIME: float = 0.8
## A Bogwisp's own light: how far it glows, its colour, and how see-through it is while it
## has no body.
const WISP_GLOW: float = 20.0
const WISP_COLOR: Color = Color(0.62, 0.95, 0.86)
const WISP_UNLIT: float = 0.62
## Where a Bogwisp hangs, above the spot on the ground it is over.
const WISP_AT: Vector2 = Vector2(0, -10)

@export var enemy_id: StringName
## Set once every enemy in the area with this same flag is beaten (a room cleared: a shutter
## waiting on the flag opens). Empty: none.
@export var clear_flag: StringName
## A boss: once its `clear_flag` is set (saved), it never comes back.
@export var stays_beaten: bool = false

var data: Dictionary = {}
## Whether it is met out of doors at night (the area says so before setup): it is set up from
## its data as the night makes it (NightRules), and tinted so the difference shows.
var night: bool = false
## Where it is met (the area says so before setup: its dungeon's id, or the area's own): a
## place the dungeons' rules name sets it up tougher (DungeonRules).
var place: StringName = &""
## Whether light reaches a point (area px): the area says how (LightRules, the lights that
## count for a Bogwisp). Only a Bogwisp asks; unset, nothing is lit.
var is_lit_at: Callable
## An enemy that is only there by night (its data's "appears") lies low by day: out of sight,
## touching nothing, not yet set up. The area wakes it if night falls while the hero is here.
var lying_low: bool = false
var brain: EnemyBrain
var body: GridBody
var terrain: TerrainQuery
## The hero's node; its position is the hero's feet.
var target: Node2D
## Gives the drop roll (0 to 1). Tests replace it to choose a drop.
var roll_drop: Callable
## What it dropped and the last arrow it shot (null if none).
var dropped: Node2D
var last_arrow: Arrow

var _rng: RandomNumberGenerator
var _flash_left: float = 0.0
var _poof_left: float = 0.0
var _clock: float = 0.0
var _rise_left: float = 0.0
var _fading: bool = false

@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox


## Reads its data and starts its brain. Returns false (and stays inert) for an unknown id, or
## for a boss already beaten (it leaves).
func setup(terrain_query: TerrainQuery, hero: Node2D, rng: RandomNumberGenerator) -> bool:
	if stays_beaten and clear_flag != &"" and GameState.get_flag(clear_flag) == true:
		visible = false
		queue_free()
		return false
	data = DataRegistry.get_enemy(enemy_id)
	if data.is_empty():
		push_warning("%s: no enemy '%s' in data/enemies." % [name, enemy_id])
		return false
	# (One that is only there by night is not made tougher by it: its numbers are its night's.)
	if night and not NightRules.is_of_the_night(data):
		data = NightRules.new(DataRegistry.get_rules(DataRegistry.RULES_NIGHT)).strengthen(data)
		var unshaded: CanvasItemMaterial = CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = unshaded
		modulate = NIGHT_TINT
	# In a dungeon (or a deep floor of the quarry) a monster is tougher, by the place's numbers.
	if place != &"":
		data = DungeonRules.new(DataRegistry.get_rules(DataRegistry.RULES_DUNGEON)).strengthen(data, place)
	terrain = terrain_query
	target = hero
	_rng = rng
	roll_drop = func() -> float: return _rng.randf()
	body = GridBody.new(terrain)
	body.place(GridBody.cell_of(position))
	brain = EnemyBrains.create(data, body, rng)
	if brain == null:
		push_warning("%s: unknown behaviour '%s'." % [name, data.get("behaviour", "")])
		return false
	brain.shot.connect(_on_shot)
	brain.state_changed.connect(_on_state_changed)
	hit_box.damage = int(data.get("contact_damage", 1))
	hit_box.knockback = float(data.get("knockback", 24.0))
	hit_box.energy = float(data.get("energy_drain", 0.0))
	hurt_box.hit_taken.connect(_on_hit_taken)
	position = body.position
	return true


func is_dead() -> bool:
	return brain != null and brain.is_dead()


## Whether this enemy is only there by night (its data's "appears").
func waits_for_night() -> bool:
	return NightRules.is_of_the_night(DataRegistry.get_enemy(enemy_id))


## By day: out of sight and touching nothing, until rise().
func lie_low() -> void:
	lying_low = true
	visible = false
	hit_box.deactivate()
	hurt_box.enabled = false


## Night has fallen: it rises where it was put, set up like any enemy as an area loads.
## Returns whether it did.
func rise(terrain_query: TerrainQuery, hero: Node2D, rng: RandomNumberGenerator) -> bool:
	if not lying_low:
		return false
	lying_low = false
	visible = true
	hit_box.active = true
	hurt_box.enabled = true
	if not setup(terrain_query, hero, rng):
		return false
	_rise_left = RISE_TIME
	queue_redraw()
	return true


## The night is over: a Bogwisp fades where it hangs and is gone, leaving nothing. Any other
## enemy stays as it is.
func fade() -> void:
	if brain is WispBrain and not brain.is_dead():
		(brain as WispBrain).fade()
		_fade_out()


## Whether it is fading away (not beaten: it leaves no drop).
func is_fading() -> bool:
	return brain is WispBrain and (brain as WispBrain).is_gone()


## What it gives off as light right now (an Ambience.glow), or {} for an enemy that gives none.
func glow_now() -> Dictionary:
	if not brain is WispBrain or brain.is_dead() or is_fading() or lying_low:
		return {}
	var wisp: WispBrain = brain
	var strength: float = 0.55 if wisp.is_flaring() or wisp.is_darting() else 0.30
	return Ambience.glow(position + WISP_AT, WISP_GLOW * (1.5 if wisp.is_flaring() else 1.0), WISP_COLOR, strength, true)


func _fade_out() -> void:
	if _poof_left > 0.0:
		return
	hit_box.deactivate()
	hurt_box.enabled = false
	_poof_left = RISE_TIME
	_fading = true
	queue_redraw()


func _physics_process(delta: float) -> void:
	if brain == null:
		return
	_clock += delta
	if _poof_left > 0.0:
		_poof_left -= delta
		queue_redraw()
		if _poof_left <= 0.0:
			queue_free()
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	_rise_left = maxf(0.0, _rise_left - delta)
	step(delta)


## One frame of thinking and moving (the engine calls it through _physics_process; tests can
## call it directly).
func step(delta: float) -> void:
	if brain == null or brain.is_dead():
		return
	if brain is WispBrain:
		# A light with no body until light reaches it: the area's lights decide (LightRules).
		(brain as WispBrain).lit = is_lit_at.is_valid() and bool(is_lit_at.call(body.position + WISP_AT))
	brain.step(target.position if target != null else position, delta)
	position = body.position
	queue_redraw()


func _on_hit_taken(hit: Hit) -> void:
	if not brain.take_hit(hit.damage, hit.push, hit.kind):
		# A blow through a Bogwisp with no body: thin air, as with the Shade.
		if brain is WispBrain and not brain.is_dead() and not (brain as WispBrain).is_solid() and hit.kind != &"contact":
			EventBus.sound.emit(&"whiff")
		return
	_flash_left = FLASH_TIME
	Burst.spawn(get_parent(), position + Vector2(0, -6), &"spark")
	EventBus.hit_stop.emit(HIT_STOP)
	if brain.is_dead():
		_die()
	else:
		EventBus.sound.emit(&"hit")
	queue_redraw()


## The sound it makes when beaten.
func death_sound() -> StringName:
	return &"enemy_die"


func _die() -> void:
	EventBus.sound.emit(death_sound())
	hit_box.deactivate()
	hurt_box.enabled = false
	_poof_left = POOF_TIME
	dropped = _drop()
	died.emit(self)


## Rolls the drop table and leaves the drop in its cell. Returns it (null for nothing).
func _drop() -> Node2D:
	var drop: Dictionary = DropTable.roll(data.get("drops", []), roll_drop.call())
	var node: Node2D = null
	match str(drop.get("type", "")):
		"heart":
			node = HeartPickup.new()
		"item":
			var item: ItemDrop = ItemDrop.new()
			item.item_id = StringName(str(drop.get("item", "coin")))
			item.count = int(drop.get("count", 1))
			node = item
	if node != null:
		node.position = Vector2(drop_cell()) * GridBody.TILE
		get_parent().add_child(node)
	return node


## Where its drop lands: its cell, or, when it stands on raised ground (an archer on a
## walkway), the first lower open cell straight below it on screen: the drop falls off the
## ledge to where the hero can reach it. Over a pit (a bat), or over water or reeds (a
## Bogwisp), the nearest open floor beside it; with none near, where the hero stands.
func drop_cell() -> Vector2i:
	var at: Vector2i = body.cell
	if terrain.is_pit(at) or terrain.grid.is_solid(at):
		for reach: int in range(1, 4):
			for side: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
				var beside: Vector2i = at + side * reach
				if terrain.grid.in_bounds(beside) and not terrain.grid.is_solid(beside) \
						and not terrain.is_pit(beside) and not terrain.is_occupied(beside):
					return beside
		if terrain.grid.is_solid(at) and target != null:
			return GridBody.cell_of(target.position)
		return at
	var level: int = terrain.standing_level(at)
	for i: int in range(1, 5):
		var below: Vector2i = at + Vector2i(0, i)
		if not terrain.grid.in_bounds(below) or terrain.grid.is_solid(below):
			break
		if terrain.standing_level(below) < level:
			return below
	return at


## A Bogwisp's flare and dart are heard: the half second of warning, then the rush.
func _on_state_changed(state: StringName) -> void:
	if state == WispBrain.FLARE:
		EventBus.sound.emit(&"wisp_flare")
	elif state == WispBrain.DART:
		EventBus.sound.emit(&"wisp_dart")


func _on_shot(direction: Vector2) -> void:
	var shot: Dictionary = data.get("shot", {})
	var arrow: Arrow = Arrow.new()
	arrow.setup(terrain, direction, int(shot.get("damage", 1)), float(shot.get("speed", 120.0)))
	arrow.position = body.position + direction * 6.0
	get_parent().add_child(arrow)
	last_arrow = arrow
	EventBus.sound.emit(&"arrow")


# --- Drawing (pixel art in gameplay/art/) ---------------------------------------

const SLIME_SHEET: Texture2D = preload("res://gameplay/art/slime.png")
const BAT_SHEET: Texture2D = preload("res://gameplay/art/bat.png")
const GOBLIN_SHEET: Texture2D = preload("res://gameplay/art/goblin.png")
const WISP_SHEET: Texture2D = preload("res://gameplay/art/wisp.png")
## Frames in each sheet, in the order the tool paints them (a test checks).
const SLIME_FRAMES: Dictionary = {&"rest": 0, &"wide": 1, &"hop": 2}
const BAT_FRAMES: Dictionary = {&"rest": 0, &"up": 1, &"down": 2}
const GOBLIN_FRAMES: Dictionary = {&"front": 0, &"front_draw": 1, &"back": 2, &"side": 3, &"side_draw": 4}
const WISP_FRAMES: Dictionary = {&"a": 0, &"b": 1, &"flare": 2}
const SMALL: Vector2i = Vector2i(16, 16)
const TALL: Vector2i = Vector2i(16, 24)
const TELL: Color = Color(1.0, 0.85, 0.2)


func _draw() -> void:
	if brain == null:
		return
	if _fading:
		# Fading with the night: the light thins out where it hangs, and nothing is left.
		_draw_wisp(clampf(_poof_left / RISE_TIME, 0.0, 1.0))
		return
	if _poof_left > 0.0:
		var spread: float = 1.0 - _poof_left / POOF_TIME
		draw_arc(Vector2(0, -5), 3.0 + spread * 8.0, 0.0, TAU, 16, Color(1, 1, 1, 1.0 - spread), 2.0)
		return
	match str(data.get("behaviour", "")):
		"hopper":
			_draw_slime()
		"archer":
			_draw_goblin()
		"flier":
			_draw_bat()
		"wisp":
			_draw_wisp(1.0 - _rise_left / RISE_TIME)


## White while a blow's flash lasts.
func _flashing() -> bool:
	return _flash_left > 0.0


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 16:
		var angle: float = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_slime() -> void:
	var phase: float = (brain as HopperBrain).hop_phase()
	var lift: float = roundf(sin(phase * PI) * 5.0) if phase >= 0.0 else 0.0
	SoftShadow.draw(self, Vector2.ZERO, Vector2(5, 2))
	var frame: StringName = &"hop" if phase >= 0.0 else (&"wide" if sin(_clock * 6.0) > 0.3 else &"rest")
	SpriteSheet.draw(self, SLIME_SHEET, SLIME_FRAMES[frame], SMALL, Vector2(-8, -15 - lift), false, _flashing())


func _draw_goblin() -> void:
	var drawing: bool = (brain as ArcherBrain).is_drawing()
	SoftShadow.draw(self, Vector2.ZERO, Vector2(5, 2))
	var side: bool = absf(brain.facing.x) > absf(brain.facing.y)
	var frame: StringName = &"front_draw" if drawing else &"front"
	if side:
		frame = &"side_draw" if drawing else &"side"
	elif brain.facing.y < 0.0:
		frame = &"back"
	# The side frames face left; facing right is the mirror image.
	SpriteSheet.draw(self, GOBLIN_SHEET, GOBLIN_FRAMES[frame], TALL, Vector2(-8, -23), side and brain.facing.x > 0.0, _flashing())
	if drawing:
		# The tell: a "!" over its head while it draws its bow.
		draw_rect(Rect2(-1, -27, 2, 4), TELL)
		draw_rect(Rect2(-1, -22, 2, 2), TELL)


## A Bogwisp: a light hanging over the ground, bobbing, its two frames flickering; the flare
## frame for the half second before a dart. `shown` (0 to 1) is how far it has risen or how
## much of it is left as it fades. With no body it is see-through and casts no shadow; where
## light reaches it, it is whole and has one.
func _draw_wisp(shown: float) -> void:
	var wisp: WispBrain = brain
	var solid: bool = wisp.is_solid()
	var bob: float = roundf(sin(_clock * 2.6) * 2.0)
	var frame: StringName = &"flare" if wisp.is_flaring() or wisp.is_darting() else (&"a" if sin(_clock * 9.0) > 0.0 else &"b")
	var alpha: float = (1.0 if solid or wisp.is_flaring() or wisp.is_darting() else WISP_UNLIT) * clampf(shown, 0.0, 1.0)
	if solid and not _fading:
		SoftShadow.draw(self, Vector2.ZERO, Vector2(4, 1.6), 0.7)
	if _flashing():
		SpriteSheet.draw(self, WISP_SHEET, WISP_FRAMES[frame], SMALL, Vector2(-8, -18 + bob), false, true)
		return
	var sheet_region: Rect2 = Rect2(Vector2(WISP_FRAMES[frame] * SMALL.x, 0), Vector2(SMALL))
	draw_texture_rect_region(WISP_SHEET, Rect2(Vector2(-8, -18 + bob), Vector2(SMALL)), sheet_region, Color(1, 1, 1, alpha))


func _draw_bat() -> void:
	var resting: bool = (brain as FlierBrain).is_resting()
	var height: float = 4.0 if resting else roundf(10.0 + sin(_clock * 5.0) * 1.5)
	SoftShadow.draw(self, Vector2.ZERO, Vector2(3.5, 1.5), 0.8)
	var frame: StringName = &"rest" if resting else (&"up" if sin(_clock * 22.0) > 0.0 else &"down")
	SpriteSheet.draw(self, BAT_SHEET, BAT_FRAMES[frame], SMALL, Vector2(-8, -8 - height), false, _flashing())
