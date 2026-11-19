class_name SceneryAtlas
extends RefCounted
## Layout of the tall scenery atlas (P1c): trees that stand up from the ground, taller and
## wider than a cell, so the hero can walk behind them. Read by Scenery. Each picture sits in its own cell with clear padding round it, so a
## picture swaying in the wind never shows its neighbour.

const TEXTURE_PATH: String = "res://world/tiles/scenery.png"
## The pictures, in atlas order.
const KINDS: Array[String] = ["broadleaf", "oak", "pine", "cherry", "cherry_b", "willow", "willow_b"]
## An atlas cell, the padding round the picture in it, and the picture's size.
const CELL: Vector2i = Vector2i(40, 48)
const PAD: Vector2i = Vector2i(4, 4)
const SIZE: Vector2i = Vector2i(32, 40)
## Where the trunk meets the ground, in the picture.
const FOOT: Vector2 = Vector2(16, 37)
## The Decor layer's tree tiles (GreyboxTiles kinds) and the tall picture each becomes. The
## closed canopy of thick woods stays a tile.
const FROM_DECOR: Dictionary = {
	"prop_tree": "broadleaf",
	"prop_tree_b": "pine",
	"prop_tree_c": "oak",
	"prop_cherry": "cherry",
	"prop_willow": "willow",
}
## Pictures of the same tree, picked by cell so a grove isn't one tree repeated.
const VARIANTS: Dictionary = {"cherry": ["cherry", "cherry_b"], "willow": ["willow", "willow_b"]}


## Where `kind`'s picture is in the atlas.
static func region(kind: String) -> Rect2:
	var index: int = maxi(KINDS.find(kind), 0)
	return Rect2(index * CELL.x + PAD.x, PAD.y, SIZE.x, SIZE.y)


static func is_cherry(kind: String) -> bool:
	return kind.begins_with("cherry")


## The picture for a tree of `kind` standing in `cell`: one of its variants, always the same
## for the same cell.
static func variant(kind: String, cell: Vector2i) -> String:
	var choices: Array = VARIANTS.get(kind, [kind])
	return choices[absi(cell.x * 7 + cell.y * 13) % choices.size()]
