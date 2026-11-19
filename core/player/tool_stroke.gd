class_name ToolStroke
extends RefCounted
## What a stroke of work looks like (tool polish, 2026-11-19), pure: given the kind of stroke
## and how far through it the hero is (the motor's own progress, 0 to 1), it says which pose he
## shows and the tool in his hands. It only picks pictures: how long a stroke lasts is the
## tool's (ToolUse.time_of()), and the work is done the moment it begins, as it always was.
## - the hoe and the pickaxe: raised until the blow (BLOW), then struck
## - the can: tipped (pouring) all through, or dipped (filling)
## - a seed and the sprinkler: a reach down before him (the sprinkler leaves his hands at the
##   blow, holds())

## The kinds of stroke.
const HOE: StringName = &"hoe"
const PICK: StringName = &"pick"
const POUR: StringName = &"pour"
const FILL: StringName = &"fill"
const SOW: StringName = &"sow"
const PLACE: StringName = &"place"
const KINDS: Array[StringName] = [HOE, PICK, POUR, FILL, SOW, PLACE]
## The poses of a tool in his hands (HeldTools names its pictures by them).
const RAISE: StringName = &"raise"
const STRIKE: StringName = &"strike"
const TIP: StringName = &"pour"
const DIP: StringName = &"dip"
const REACH: StringName = &"reach"
## How far through a stroke the blow comes: the hoe and the pickaxe come down, the water
## reaches the soil, the seed leaves the hand.
const BLOW: float = 0.35


## The kind of stroke of a use that ToolUse decided (ToolUse.TILL and the rest), or "".
static func of_use(does: StringName) -> StringName:
	match does:
		ToolUse.TILL:
			return HOE
		ToolUse.WATER:
			return POUR
		ToolUse.FILL:
			return FILL
		ToolUse.PLANT:
			return SOW
		ToolUse.PLACE:
			return PLACE
		ToolUse.MINE:
			return PICK
	return &""


## The pose of the tool `progress` (0 to 1) through a stroke of `kind`, or "" for none.
static func pose(kind: StringName, progress: float) -> StringName:
	match kind:
		HOE, PICK:
			return RAISE if progress < BLOW else STRIKE
		POUR:
			return TIP
		FILL:
			return DIP
		SOW, PLACE:
			return REACH
	return &""


## The hero's own pose (a column of his sheet: PlayerAnimator.work_pose) for a tool's pose: a
## can dipped is held in a reach.
static func hero_pose(tool_pose: StringName) -> StringName:
	return REACH if tool_pose == DIP else tool_pose


## Whether the tool is still in his hands `progress` through a stroke of `kind`: a sprinkler
## leaves them at the blow, set down on the soil; every tool stays in them to the end.
static func holds(kind: StringName, progress: float) -> bool:
	return progress < BLOW if kind == PLACE else KINDS.has(kind)


## Whether the blow of a stroke of `kind` came between progress `before` and `after` (the
## first frame of a stroke is `before` < 0).
static func blow_between(kind: StringName, before: float, after: float) -> bool:
	return KINDS.has(kind) and before < BLOW and after >= BLOW
