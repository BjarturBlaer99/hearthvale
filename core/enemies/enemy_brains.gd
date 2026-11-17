class_name EnemyBrains
extends RefCounted
## Makes the brain for an enemy's behaviour id (the "behaviour" in data/enemies/*.json).
## A new behaviour is a new EnemyBrain subclass listed here and in DataRegistry.ENEMY_BEHAVIOURS.

const BEHAVIOURS: Array[String] = ["hopper", "archer", "flier", "warden", "shade", "wisp"]


## The brain script for `behaviour`, or null if there's none.
static func script_for(behaviour: String) -> GDScript:
	match behaviour:
		"hopper":
			return HopperBrain
		"archer":
			return ArcherBrain
		"flier":
			return FlierBrain
		"warden":
			return WardenBrain
		"shade":
			return ShadeBrain
		"wisp":
			return WispBrain
	return null


static func has(behaviour: String) -> bool:
	return script_for(behaviour) != null


## A started brain for `data` moving `body`, or null for an unknown behaviour.
static func create(data: Dictionary, body: GridBody, rng: RandomNumberGenerator) -> EnemyBrain:
	var script: GDScript = script_for(str(data.get("behaviour", "")))
	if script == null:
		return null
	var brain: EnemyBrain = script.new(body, data, rng)
	brain.start()
	return brain
