class_name NoticeLines
extends RefCounted
## The news at the top of the screen (a quest's, a skill's, a friendship's, a recipe's), pure:
## what shows when more news comes while other news is still up. It joins it on a line of its
## own, so neither takes the other's place (a skill rising as a quest moves on). News that is
## showing already isn't said twice, and past what fits the oldest line gives way. The HUD
## keeps the lines and their time (AreaHud.show_notice).

## How many lines of news show at once.
const MOST: int = 3


## `showing` (oldest first) with `text` joined to it: as its last line unless it is there
## already, and with the oldest lines dropped past `most` (there is always room for the
## latest). `showing` is left as it was.
static func joined(showing: PackedStringArray, text: String, most: int = MOST) -> PackedStringArray:
	var out: PackedStringArray = showing.duplicate()
	if text.is_empty() or out.has(text):
		return out
	out.append(text)
	while out.size() > maxi(most, 1):
		out.remove_at(0)
	return out
