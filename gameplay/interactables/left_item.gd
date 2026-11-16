class_name LeftItem
extends ItemPickup
## What a full pack couldn't take of something the hero was given, laid at his feet (LeftItems).
## It is picked up like any item on the ground: whole, when there is room. `taken_flag` is not a
## yes or no here but the flag that counts how many lie in this cell; taken, the flag is gone,
## and so is this for good. The area makes one for each such flag as it loads, and as things
## are laid down.


func taken() -> bool:
	return LeftItems.count_of(GameState.get_flag(taken_flag, 0)) <= 0


func _mark_taken() -> void:
	GameState.erase_flag(taken_flag)
