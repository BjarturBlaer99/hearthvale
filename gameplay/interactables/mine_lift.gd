class_name MineLift
extends Talkable
## The lift in the Old Quarry's entrance hall (2026-11-17): face it and interact, and it offers
## the floors it has reached (MineRules.lift_dialogue). Arriving on one of the lift's floors on
## foot is what opens it, for good. Its words aren't a file in data/dialogue: the list is built
## from the mine's rules and the flags. Position = its cell's top-left corner.

## The entry point of a floor that the lift (like the ladder) sets him down at.
@export var arrives_at: StringName = &"ladder"


func prompt() -> String:
	return "Ride the lift"


func dialogue() -> Dictionary:
	var rules: MineRules = GameState.mine_rules()
	return rules.lift_dialogue(rules.reached(GameState.flags), arrives_at)


func _draw() -> void:
	SoftShadow.draw(self, Vector2(8, 15), Vector2(7, 1.8), 0.8)
	SpriteSheet.draw(self, Rock.SHEET, int(Rock.FRAMES[&"lift"]), Rock.SIZE, Vector2.ZERO)
