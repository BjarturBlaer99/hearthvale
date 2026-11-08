class_name Enemy
extends Node2D
## An enemy in an area (docs/TECH_DESIGN.md §5), set up from data/enemies/<enemy_id>.json:
## an EnemyBrain moves a GridBody, and this node follows it and draws a placeholder for its
## behaviour. Its HurtBox takes the sword's hits; its HitBox (contact damage) hurts the hero
## on touch. Archers shoot Arrows. Beaten, it rolls its drop table, leaves the drop where it
## fell and vanishes; it's back on the next visit (nothing is saved). Position = its feet:
## place it at a cell's centre. The area calls setup().

signal died(enemy: Enemy)

const POOF_TIME: float = 0.35
const FLASH_TIME: float = 0.15
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const SHADOW: Color = Color(0, 0, 0, 0.3)

@export var enemy_id: StringName
## Set once every enemy in the area with this same flag is beaten (a room cleared: a shutter
## waiting on the flag opens). Empty: none.
@export var clear_flag: StringName

var data: Dictionary = {}
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

@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox


## Reads its data and starts its brain. Returns false (and stays inert) for an unknown id.
func setup(terrain_query: TerrainQuery, hero: Node2D, rng: RandomNumberGenerator) -> bool:
	data = DataRegistry.get_enemy(enemy_id)
	if data.is_empty():
		push_warning("%s: no enemy '%s' in data/enemies." % [name, enemy_id])
		return false
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
	hit_box.damage = int(data.get("contact_damage", 1))
	hit_box.knockback = float(data.get("knockback", 24.0))
	hurt_box.hit_taken.connect(_on_hit_taken)
	position = body.position
	return true


func is_dead() -> bool:
	return brain != null and brain.is_dead()


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
	step(delta)


## One frame of thinking and moving (the engine calls it through _physics_process; tests can
## call it directly).
func step(delta: float) -> void:
	if brain == null or brain.is_dead():
		return
	brain.step(target.position if target != null else position, delta)
	position = body.position
	queue_redraw()


func _on_hit_taken(hit: Hit) -> void:
	if not brain.take_hit(hit.damage, hit.push):
		return
	_flash_left = FLASH_TIME
	if brain.is_dead():
		_die()
	queue_redraw()


func _die() -> void:
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
		node.position = Vector2(body.cell) * GridBody.TILE
		get_parent().add_child(node)
	return node


func _on_shot(direction: Vector2) -> void:
	var shot: Dictionary = data.get("shot", {})
	var arrow: Arrow = Arrow.new()
	arrow.setup(terrain, direction, int(shot.get("damage", 1)), float(shot.get("speed", 120.0)))
	arrow.position = body.position + direction * 6.0
	get_parent().add_child(arrow)
	last_arrow = arrow


# --- Drawing (placeholder art) ----------------------------------------------

func _draw() -> void:
	if brain == null:
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


func _tint(color: Color) -> Color:
	return Color.WHITE if _flash_left > 0.0 else color


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 16:
		var angle: float = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _draw_slime() -> void:
	var phase: float = (brain as HopperBrain).hop_phase()
	var lift: float = sin(phase * PI) * 5.0 if phase >= 0.0 else 0.0
	var squash: float = 1.0 if phase >= 0.0 else 1.0 + 0.12 * sin(_clock * 6.0)
	_ellipse(Vector2(0, 0), Vector2(5, 2), SHADOW)
	var center: Vector2 = Vector2(0, -4.0 - lift)
	var size: Vector2 = Vector2(6.5 * squash, 5.0 / squash) if phase < 0.0 else Vector2(5.5, 6.0)
	_ellipse(center, size + Vector2(1, 1), OUTLINE)
	_ellipse(center, size, _tint(Color(0.36, 0.72, 0.30)))
	_ellipse(center + Vector2(-2, -2), size * 0.3, _tint(Color(0.62, 0.90, 0.52)))
	var look: Vector2 = brain.facing * 1.5
	draw_rect(Rect2(center + look + Vector2(-2.5, -1), Vector2(1, 2)), OUTLINE)
	draw_rect(Rect2(center + look + Vector2(1.5, -1), Vector2(1, 2)), OUTLINE)


func _draw_goblin() -> void:
	var archer: ArcherBrain = brain as ArcherBrain
	var skin: Color = _tint(Color(0.46, 0.60, 0.26))
	var tunic: Color = _tint(Color(0.50, 0.32, 0.18))
	_ellipse(Vector2(0, 0), Vector2(5, 2), SHADOW)
	draw_rect(Rect2(-3, -4, 2, 4), OUTLINE)
	draw_rect(Rect2(1, -4, 2, 4), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(5, -3), Vector2(4, -11), Vector2(-4, -11)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(3, -10), Vector2(-3, -10)]), tunic)
	draw_circle(Vector2(0, -14), 5.0, OUTLINE)
	draw_circle(Vector2(0, -14), 4.0, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -15), Vector2(-8, -17), Vector2(-4, -13)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(4, -15), Vector2(8, -17), Vector2(4, -13)]), skin)
	var eyes: Vector2 = brain.facing * 1.5
	draw_rect(Rect2(Vector2(-2, -15) + eyes, Vector2(1, 1)), Color(0.9, 0.2, 0.1))
	draw_rect(Rect2(Vector2(1, -15) + eyes, Vector2(1, 1)), Color(0.9, 0.2, 0.1))
	# The bow, held out the way it faces; drawn back with an arrow nocked while it aims (the tell).
	var hand: Vector2 = Vector2(0, -8) + brain.facing * 6.0
	var across: Vector2 = brain.facing.orthogonal() * 5.0
	var wood: Color = Color(0.55, 0.36, 0.18)
	draw_line(hand - across, hand + brain.facing * 2.0, wood, 1.5)
	draw_line(hand + brain.facing * 2.0, hand + across, wood, 1.5)
	var pull: float = 3.0 if archer.is_drawing() else 0.0
	draw_line(hand - across, hand - brain.facing * pull, Color(0.9, 0.9, 0.85), 1.0)
	draw_line(hand - brain.facing * pull, hand + across, Color(0.9, 0.9, 0.85), 1.0)
	if archer.is_drawing():
		draw_line(hand - brain.facing * pull, hand + brain.facing * 6.0, Color(0.85, 0.80, 0.70), 1.0)
		draw_rect(Rect2(-0.5, -25, 1.5, 4), Color(1.0, 0.85, 0.2))
		draw_rect(Rect2(-0.5, -20, 1.5, 1.5), Color(1.0, 0.85, 0.2))


func _draw_bat() -> void:
	var flier: FlierBrain = brain as FlierBrain
	var resting: bool = flier.is_resting()
	var height: float = 4.0 if resting else 10.0 + sin(_clock * 5.0) * 1.5
	var wing_color: Color = _tint(Color(0.30, 0.18, 0.36))
	_ellipse(Vector2(0, 0), Vector2(3.5, 1.5), SHADOW)
	var center: Vector2 = Vector2(0, -height)
	if resting:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-5, 1), center + Vector2(0, -3), center + Vector2(5, 1), center + Vector2(0, 3)]), wing_color)
	else:
		var flap: float = sin(_clock * 22.0) * 4.0
		for side: float in [-1.0, 1.0]:
			var wing: PackedVector2Array = [center + Vector2(side * 2, -1), center + Vector2(side * 9, -2 - flap), center + Vector2(side * 7, 2), center + Vector2(side * 4, 1)]
			draw_colored_polygon(wing, wing_color)
	draw_circle(center, 3.5, OUTLINE)
	draw_circle(center, 2.5, _tint(Color(0.42, 0.26, 0.48)))
	draw_rect(Rect2(center + Vector2(-1.5, -1), Vector2(1, 1)), Color(1.0, 0.3, 0.3))
	draw_rect(Rect2(center + Vector2(0.5, -1), Vector2(1, 1)), Color(1.0, 0.3, 0.3))
