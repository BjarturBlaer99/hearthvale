class_name MineRolls
extends RefCounted
## The day's roll for one floor of the mine (2026-11-17, docs/TECH_DESIGN.md §27), pure: a
## floor's rocks are always in the same cells, and each day a shuffle decides which of them
## hold ore and which plain rock hides the ladder down. The shuffle comes from three numbers:
## the save's own (so no two games are alike), the day, and the floor. So it is the same all
## day, and after a save and a load, and another one tomorrow.

## No cell: a floor with no ladder down.
const NO_CELL: Vector2i = Vector2i(-1, -1)


## Today's rocks for a floor: { "kinds": { cell: kind }, "ladder": cell }.
## `cells` are where the floor's rocks stand; `ores` how many of them hold each kind of ore
## (kind -> count, MineRules.ores_of); the rest are `plain`. With `has_ladder`, one of the
## plain rocks hides the ladder down (NO_CELL if there is none, or no plain rock to hide it).
## With more ore than rocks, the kinds listed first get theirs.
static func roll(number: int, day: int, floor: int, cells: Array[Vector2i], ores: Dictionary, has_ladder: bool, plain: StringName = MineRules.STONE) -> Dictionary:
	var order: Array[Vector2i] = shuffled(number, day, floor, cells)
	var kinds: Dictionary = {}
	var next: int = 0
	for kind: Variant in ores:
		for _n: int in int(ores[kind]):
			if next >= order.size():
				break
			kinds[order[next]] = StringName(str(kind))
			next += 1
	var ladder: Vector2i = NO_CELL
	if has_ladder and next < order.size():
		ladder = order[next]
	for index: int in range(next, order.size()):
		kinds[order[index]] = plain
	return {"kinds": kinds, "ladder": ladder}


## `cells` in the day's order for a floor: the same cells in any order give the same answer.
static func shuffled(number: int, day: int, floor: int, cells: Array[Vector2i]) -> Array[Vector2i]:
	var order: Array[Vector2i] = cells.duplicate()
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_for(number, day, floor)
	for index: int in range(order.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var held: Vector2i = order[index]
		order[index] = order[other]
		order[other] = held
	return order


## The number a floor's shuffle starts from on a day.
static func seed_for(number: int, day: int, floor: int) -> int:
	return hash([number, day, floor])
