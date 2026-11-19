class_name ItemIcons
extends RefCounted
## The 16x16 pictures of items and pickups (gameplay/art/items.png, painted by
## tools/art/make_sprites.gd): which frame shows which item, and drawing one.

const SHEET: Texture2D = preload("res://gameplay/art/items.png")
const SIZE: Vector2i = Vector2i(16, 16)
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"sword": 0, &"bow": 1, &"arrows": 2, &"bomb": 3, &"bomb_dim": 4, &"key": 5, &"coin": 6,
	&"heart": 7, &"heart_container": 8, &"heart_piece": 9, &"gem": 10, &"shuttle": 11,
	&"lantern": 12, &"iron_sword": 13,
	&"berries": 14, &"mushroom": 15, &"bread": 16, &"blossom": 17, &"tea": 18,
	&"hoe": 19, &"watering_can": 20, &"water": 21,
	&"turnip": 22, &"carrot": 23, &"wheat": 24, &"potato": 25, &"pumpkin": 26,
	&"turnip_seeds": 27, &"carrot_seeds": 28, &"wheat_seeds": 29, &"potato_seeds": 30, &"pumpkin_seeds": 31,
	&"roast_turnip": 32, &"soup": 33, &"stew": 34, &"pie": 35,
	&"jam": 36, &"cake": 37, &"shepherds_pie": 38,
	&"cattail_root": 39, &"marsh_berries": 40, &"bog_mushroom": 41, &"marsh_stew": 42,
	&"wisp_ember": 43, &"ember_tea": 44,
	&"pickaxe": 45, &"stone": 46, &"copper_ore": 47, &"coal": 48, &"iron_ore": 49, &"gold_ore": 50, &"crystal": 51,
	&"wood": 52, &"copper_bar": 53, &"iron_bar": 54, &"gold_bar": 55, &"sprinkler": 56, &"miners_lantern": 57,
	&"copper_pickaxe": 58, &"iron_pickaxe": 59, &"copper_hoe": 60, &"iron_hoe": 61,
	&"copper_watering_can": 62, &"iron_watering_can": 63,
	&"fibre": 64,
	&"hay": 65, &"kit": 66,
	&"egg": 67, &"wool": 68, &"milk": 69, &"cloth": 70, &"fried_egg": 71, &"omelette": 72, &"custard": 73,
}


## The picture for an item: the one its data names ("icon"), else by its type: a sword, a bow,
## arrows, a bomb, a key, a coin, or a gem for anything else. What is set down on the land
## names its picture on the ground (PlacedArt), which is its icon too.
static func name_for(item_id: StringName) -> StringName:
	var item: Dictionary = DataRegistry.get_item(item_id)
	var named: StringName = StringName(str(item.get("icon", "")))
	if has(named):
		return named
	match str(item.get("type", "")):
		"weapon_melee":
			return &"sword"
		"weapon_ranged":
			return &"bow"
		"ammo":
			return &"arrows"
		"bomb":
			return &"bomb_dim"
		"key":
			return &"key"
		"currency":
			return &"coin"
	return &"gem"


## Whether there is a picture named `icon`: one of the items' own, or one of what is set down.
static func has(icon: StringName) -> bool:
	return FRAMES.has(icon) or PlacedArt.has(icon)


## Draws picture `icon` on `canvas` with its top-left at `origin` (white: a silhouette).
static func draw(canvas: CanvasItem, icon: StringName, origin: Vector2 = Vector2.ZERO, white: bool = false) -> void:
	if not FRAMES.has(icon) and PlacedArt.has(icon):
		PlacedArt.draw(canvas, icon, origin, false, Color.WHITE, white)
		return
	SpriteSheet.draw(canvas, SHEET, int(FRAMES.get(icon, FRAMES[&"gem"])), SIZE, origin, false, white)
