class_name BuildBarView
extends ItemBar
## The build bar (the Homestead, phase 2; docs/TECH_DESIGN.md §30): in build mode it takes the
## item bar's place at the bottom of the screen, and looks like it: a slot for each placeable
## the hero carries, with how many, the one chosen lit. BuildBar (pure) says what is on it and
## BuildMode which is chosen; the HUD tells this what to show (AreaHud.show_build). For show
## only: it takes no clicks. The wheel steps along it and the keys 1 to 9 choose a slot.


## Every slot says how many of its thing he carries.
func count_of(entry: Dictionary) -> String:
	return BuildBar.count_text(entry, GameState.item_count)
