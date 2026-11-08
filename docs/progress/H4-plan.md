# H4 — Items & weapons (plan)

Goal (ROADMAP H4): an inventory with one item on the item button and an item menu; the bow with arrows as ammo;
bombs (fuse, blast); coins and the village shop.

## Design
- **Items in data** (`data/items/items.json`):
  - Bow (`weapon_ranged`: damage 2, cooldown, ammo `arrow`, arrow speed)
  - Arrows (`ammo`, up to 30)
  - Bombs (`bomb`, up to 10: damage 4, fuse 2 s, blast radius 24 px, knockback)
  - DataRegistry checks that a ranged weapon's ammo is a real item.
- **Inventory rules** (`core/inventory/Inventory`, pure):
  - Stack capacity: `max_stack`, or 1 for single items; items without data have no limit.
  - Room left in a stack, which items can go on the item button (`weapon_ranged`, `bomb`), the ones held, and
    each one's ammo.
  - `GameState.add_item` now respects capacity: a full quiver takes no more.
- **Equipment:** `GameState.equipped` (the item on the item button) is saved with the game.
  - The first equippable item picked up is equipped automatically.
  - `EventBus.equipped_changed` announces changes.
- **Using the item** (Q or K, gamepad Y), handled by the area:
  - **Bow:** stands still for its cooldown and shoots an arrow (one ammo) the way the hero faces. The arrow is the
    H3 `Arrow`, on the hero team: it hurts enemies (and the dummy) and stops at solid tiles.
  - **Bombs:** sets one down at the hero's feet. The fuse blinks faster as it burns, then a blast HitBox hurts
    every enemy in range once. The hero's own bombs don't hurt them.
  - Nothing happens, with a message, when out of ammo.
- **Item menu** (Tab / I, gamepad Back), in the HUD: the equippable items held, with ammo counts. Move the
  cursor and press E to equip; Tab closes it. The hero stands still while it's open. The HUD shows the equipped
  item and its ammo.
- **The shop:** the red house beside the training yard gets a door and an interior with a shopkeeper. The
  shop is a conversation in data (no new code):
  - "Ten arrows (5 coins)" and "Three bombs (8 coins)" take coins and give items.
  - An option shows only when you can afford it and have room (existing conditions: `has_item`, `not`, `all`).
  - Otherwise a "can't" answer explains.
- **The Bow's place:** lying in the South Field ruin with a bundle of ten arrows, until the first dungeon (H7)
  takes it over. That means moving one pickup.

## Acceptance criteria (from ROADMAP)
- [x] arrows and bombs hurt enemies and run out
- [x] the shop sells them for coins
- [x] the equipped item survives a save

## Deliberately not in H4
Cracked walls and switches for arrows and bombs (H6), the bow as the dungeon's item (H7), heart pieces, a shop
UI beyond dialogue, hero damage from their own bombs, the iron sword, selling items.
