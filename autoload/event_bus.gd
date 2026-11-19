extends Node
## Global signal hub: signals only, never state (docs/TECH_DESIGN.md §2).
##
## Systems talk through these signals instead of holding references across scenes.
## Anything that must survive a save belongs in GameState, which is the only emitter
## of the state signals below.

## A quest moved to a new stage.
signal quest_updated(quest_id: StringName)

## News of a quest for the player (Quests announces it): `what` is &"started", &"updated" or
## &"completed".
signal quest_announced(quest_id: StringName, what: StringName)

## Items entered the inventory. A negative `count` means items were removed.
signal item_added(item_id: StringName, count: int)

## A world flag was written.
signal flag_set(flag: StringName, value: Variant)

## The hero's health changed. Both values are in half hearts.
signal health_changed(current: int, maximum: int)

## A piece of heart was found; `pieces` are now held toward the next heart (0: one was just made).
signal heart_piece_found(pieces: int)

## The player changed a setting (Settings has the new values).
signal settings_changed

## A sound effect should play: `id` names audio/sfx/<id>.wav (Audio plays it).
signal sound(id: StringName)

## The music should become `id` (audio/music/<id>.wav), or stop for empty. Asking for the tune
## already playing doesn't restart it.
signal music_requested(id: StringName)

## A moment's freeze, for weight: `seconds` of near-stillness (the area applies it).
signal hit_stop(seconds: float)

## The camera shakes up to `strength` pixels for `seconds`.
signal shake(strength: float, seconds: float)

## The hero's energy changed.
signal energy_changed(current: float, maximum: float)

## The day's clock reached a new minute (`minute` counts from the midnight the day began on).
signal time_changed(day: int, minute: int)

## A new day began.
signal day_started(day: int)

## The hero slept in his bed and woke on `day` (after day_started), rested.
signal slept(day: int)

## The item on the item button changed (empty: nothing equipped).
signal equipped_changed(item_id: StringName)

## The hero's plot changed (a cell tilled or watered, or a new morning): whoever draws it redraws.
signal farm_changed

## A conversation asked for a shop's buy-and-sell list (the `shop` effect): `mode` is the list
## to open on (Shop.BUY or Shop.SELL). The area opens it when the conversation is over.
signal shop_requested(shop_id: StringName, mode: StringName)

## One of the hero's skills rose to `level` (P4b; Skills): said once, as it happens.
signal skill_rose(skill: StringName, level: int)

## The hero's friendship with `villager` reached another mark (P4c; Friendship): said once.
signal friend_mark_gained(villager: StringName, marks: int)

## A conversation asks for the list of what the hero can give `villager` (the `gift` effect):
## whoever runs the area opens it when the conversation is over.
signal gift_requested(villager: StringName)

## The hero learned the recipe `recipe_id` (P4d; the `teach_recipe` effect): said once.
signal recipe_learned(recipe_id: StringName)

## Something given to the hero didn't all fit in his pack (GameState.give_item): what is owed
## is in the flags (LeftItems), and whoever runs the area lays it at his feet.
signal items_owed

## A conversation asks to be taken somewhere (the `travel` effect: the mine's lift): whoever
## runs the area goes there when the conversation closes.
signal travel_requested(area_id: StringName, entry: StringName)

## Something was made at the workbench (GameState.craft): a thing for the pack, or a
## furnishing that now stands in the hero's home.
signal crafted(recipe_id: StringName)

## The furnace was lit, or what it made was taken out: whoever draws it shows it so.
signal furnace_changed

## Something on the hero's land was cleared for good (GameState.clear_debris; the Homestead).
signal homestead_changed

## A morning finished a building on the hero's land: a site set down the day before stands, or
## (`big`) an upgrade bought the day before is done (GameState.start_next_day).
signal building_finished(building_id: StringName, big: bool)


## An animal of the hero's land was petted (the Homestead, phase 4): its place in the herd.
signal animal_petted(index: int)
