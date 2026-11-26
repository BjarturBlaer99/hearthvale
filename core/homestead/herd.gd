class_name Herd
extends RefCounted
## The animals of the hero's land (the Homestead, phase 4; docs/TECH_DESIGN.md §30; the plan's
## D25 to D28), pure: what a kind of animal is, how a morning feeds the herd and brings each
## animal nearer its next egg, fleece or pail, what petting it gives, and why one can't be
## bought. A kind is data (data/animals/<id>.json):
##   { "id": "chicken", "name": "Chicken", "lives_in": "coop", "gives": "egg", "every": 1,
##     "grazes": 4, "sound": "cluck", "icon": "hen" }
## - `lives_in`: the building it lives in (data/buildings), which has room for so many
##   (Buildings.animals_of: 4, or 8 once it is the big one). Sheep and cows share the barn.
## - `gives`: the item it gives (an egg, wool, milk), every `every` mornings when it is fed and
##   petted; fed and not petted, at half that pace; unfed, not at all that morning (D27).
## - `grazes`: the cells of pasture grass it eats in a morning (Pasture says what is pasture).
## - `sound`: what it says when it is petted (a sound effect's id).
## An animal on the land is a Dictionary that Homestead keeps:
##   { "kind": "chicken", "petted": petted today, "progress": halves of a morning towards its
##     next product, "ready": one waits to be taken, "hungry": it went unfed this morning }
## So a new animal is data and pictures, unless it is a new kind of thing.

## A morning's step towards the next product, in halves of a morning: fed and petted the day
## before, a whole morning; fed only, half of one; unfed, none.
const FULL_STEP: int = 2
const HALF_STEP: int = 1
## Why an animal can't be bought (Shop.NO_COINS for the coins): its kind's name and its
## building's name.
const NO_HOME_WORDS: String = "A %s needs a %s on your farm."
const FULL_WORDS: String = "Your %s has no room for another."
## Where a kind's numbers are read with care: what is wrong with it, in words.
const REQUIRED: Array[String] = ["id", "name", "lives_in", "gives", "every", "grazes"]


## An animal of kind `kind_id`, just bought: not petted, nothing on the way, nothing waiting.
static func new_animal(kind_id: StringName) -> Dictionary:
	return {"kind": String(kind_id), "petted": false, "progress": 0, "ready": false, "hungry": false}


static func lives_in(kind: Dictionary) -> StringName:
	return StringName(str(kind.get("lives_in", "")))


static func gives(kind: Dictionary) -> StringName:
	return StringName(str(kind.get("gives", "")))


## The mornings between one product and the next, fed and petted.
static func every(kind: Dictionary) -> int:
	return maxi(int(kind.get("every", 1)), 1)


## The pasture grass it eats in a morning.
static func grazes(kind: Dictionary) -> int:
	return maxi(int(kind.get("grazes", 1)), 1)


static func sound_of(kind: Dictionary) -> StringName:
	return StringName(str(kind.get("sound", "")))


## Its picture in a list (Farmer Oda's stall): a frame of the item icons (ItemIcons), or "" if
## its data names none.
static func icon_of(kind: Dictionary) -> StringName:
	return StringName(str(kind.get("icon", "")))


static func name_of(kind: Dictionary) -> String:
	return str(kind.get("name", kind.get("id", "")))


## Why one of `kind` can't be bought, in words; "" if it can. Its building (`building`, its
## data entry) must stand (`built`), with room left (`housed` animals in it already; `big`, its
## upgrade finished), and the purse must hold the `price` (`coins`).
static func why_not_buy(kind: Dictionary, building: Dictionary, built: bool, big: bool, housed: int, coins: int, price: int) -> String:
	if building.is_empty() or not built:
		return NO_HOME_WORDS % [name_of(kind).to_lower(), Buildings.name_of(building) if not building.is_empty() else str(lives_in(kind))]
	if housed >= Buildings.animals_of(building, big):
		return FULL_WORDS % Buildings.name_of(building, big)
	if coins < price:
		return Shop.NO_COINS
	return ""


## Which animals a morning feeds (D25): each in turn, first from its building's pasture while
## the grass holds out, then one hay from the silo, else none. `animals` are Homestead's,
## `kinds` the kinds' data by id (String), `pastures` the pastures that stand this morning, each
## { "buildings": the ids (String) of the buildings whose door opens on it, "grass": its cells
## of grass } (a pasture two buildings share feeds both), and `hay` what the silo holds.
## Returns { "fed": Array[bool] (by animal), "grazed": how many grazed, "hay": the hay left }.
static func feed(animals: Array, kinds: Dictionary, pastures: Array, hay: int) -> Dictionary:
	var grass_left: Array[int] = []
	var pasture_of: Dictionary = {}
	for i: int in pastures.size():
		var pasture: Dictionary = pastures[i]
		grass_left.append(maxi(int(pasture.get("grass", 0)), 0))
		for building: Variant in pasture.get("buildings", []):
			if not pasture_of.has(str(building)):
				pasture_of[str(building)] = i
	var fed: Array[bool] = []
	var grazed: int = 0
	var hay_left: int = maxi(hay, 0)
	for animal: Variant in animals:
		var kind: Dictionary = kinds.get(str((animal as Dictionary).get("kind", "")), {})
		var home: String = String(lives_in(kind))
		var eats: int = grazes(kind)
		if not kind.is_empty() and pasture_of.has(home) and grass_left[pasture_of[home]] >= eats:
			grass_left[pasture_of[home]] -= eats
			grazed += 1
			fed.append(true)
		elif not kind.is_empty() and hay_left > 0:
			hay_left -= 1
			fed.append(true)
		else:
			fed.append(false)
	return {"fed": fed, "grazed": grazed, "hay": hay_left}


## A morning comes to `animal` (of `kind`), which was fed this morning or not (D27): fed, it is
## a whole morning nearer its next product if it was petted the day before, half a morning if
## not; unfed, no nearer, and it looks unhappy today. One that has a product waiting comes no
## nearer the next. Its petting is the day before's: today it is not petted yet. Returns
## whether a product is ready this morning that wasn't before.
static func morning(animal: Dictionary, kind: Dictionary, fed: bool) -> bool:
	var was_petted: bool = bool(animal.get("petted", false))
	animal["petted"] = false
	animal["hungry"] = not fed
	if not fed or bool(animal.get("ready", false)):
		return false
	var progress: int = maxi(int(animal.get("progress", 0)), 0) + (FULL_STEP if was_petted else HALF_STEP)
	var due: int = every(kind) * FULL_STEP
	if progress >= due:
		animal["ready"] = true
		animal["progress"] = progress - due
		return true
	animal["progress"] = progress
	return false


## What is wrong with `kind` as an animal, in words: nothing, if it can be used. `item_of` gives
## an item's data by its id ({} if there is none); `building_of` a building's data ({} if none).
static func problems(kind: Dictionary, item_of: Callable, building_of: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	for field: String in REQUIRED:
		if not kind.has(field):
			out.append("an animal needs '%s'." % field)
	if not out.is_empty():
		return out
	var building: Dictionary = building_of.call(str(kind["lives_in"]))
	if building.is_empty():
		out.append("it lives in '%s', which is no building." % kind["lives_in"])
	elif Buildings.animals_of(building) <= 0:
		out.append("it lives in '%s', which has no room for animals." % kind["lives_in"])
	if (item_of.call(str(kind["gives"])) as Dictionary).is_empty():
		out.append("it gives '%s', which is no item." % kind["gives"])
	for number: String in ["every", "grazes"]:
		var value: Variant = kind[number]
		if not (typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floorf(float(value)))) or int(value) < 1:
			out.append("'%s' must be a whole number of 1 or more." % number)
	return out
