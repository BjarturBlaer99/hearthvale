class_name AreaHud
extends CanvasLayer
## The HUD: hearts, where you are, what you're carrying, the bar of what can be in hand, the
## prompt for whatever the hero can use, short messages, the dialogue box, the food and pause
## menus, and a screen flash for scene changes. The controls hint shows or hides with the player's setting.

const MESSAGE_TIME: float = 3.0
## How long a notice (quest news) stays at the top of the screen.
const NOTICE_TIME: float = 3.5
const FLASH_TIME: float = 0.35

## The corner's box is as wide as its longest line, but never wider than this (px): a longer
## line ends in an ellipsis.
const BOX_MAX: float = 192.0

## Build mode (the Homestead): the colour of its line of words where the thing fits and where
## it doesn't, and what the controls hint says while it is open.
const BUILD_FITS: Color = Color(0.62, 1.0, 0.66)
const BUILD_REFUSED: Color = Color(1.0, 0.52, 0.45)
const BUILD_HINT: String = "Build mode   Mouse or WASD: point   B or Tab: leave\nLeft click: set down   Right click: take up\nWheel or 1-9: choose what to set down"

## The corners of the screen: how dark they get, and how far from the middle it starts (0-1).
const VIGNETTE_COLOR: Color = Color(0.06, 0.03, 0.12, 0.36)
const VIGNETTE_START: float = 0.58

## The shading of the screen's corners.
var vignette: TextureRect

var _message_left: float = 0.0
var _notice_left: float = 0.0
var _flash_left: float = 0.0
var _flash_time: float = FLASH_TIME
## What the controls hint says in play (the scene's words): put back when build mode closes.
var _play_hint: String = ""

@onready var hearts: HeartsBar = $Panel/Box/Hearts
## The hero's energy, under the hearts. Hidden until the energy rules exist (P2).
@onready var energy: EnergyBar = $Panel/Box/Energy
@onready var _panel: ColorRect = $Panel
@onready var _box: VBoxContainer = $Panel/Box
@onready var dialogue: DialogueBox = $DialogueBox
@onready var item_menu: ItemMenu = $ItemMenu
@onready var shop_menu: ShopMenu = $ShopMenu
@onready var gift_menu: GiftMenu = $GiftMenu
@onready var craft_menu: CraftMenu = $CraftMenu
@onready var store_menu: StoreMenu = $StoreMenu
@onready var pause_menu: PauseMenu = $PauseMenu
## What can be in the hero's hand, along the bottom of the screen.
@onready var item_bar: ItemBar = $ItemBar
## Build mode's bar, in the item bar's place while that mode is open, and its line of words.
@onready var build_bar: BuildBarView = $BuildBar
@onready var _build_words: Label = $BuildWords
@onready var _hint: Label = $Hint
@onready var _hint_panel: ColorRect = $HintPanel
@onready var _equipped: Label = $Panel/Box/Equipped
@onready var _clock: Label = $Panel/Box/Clock
@onready var _area: Label = $Panel/Box/Area
@onready var _items: Label = $Panel/Box/Items
@onready var _prompt: Label = $Prompt
@onready var _message: Label = $Message
@onready var _notice: Label = $Notice
@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	_add_vignette()
	MenuInput.let_clicks_through(self)
	_prompt.text = ""
	_message.text = ""
	_notice.text = ""
	_play_hint = _hint.text
	_show_settings()
	EventBus.settings_changed.connect(_show_settings)
	_box.minimum_size_changed.connect(_fit_panel)
	_fit_panel()


## Darkens the corners of the screen a little, under everything else on the HUD, to draw the
## eye to the middle (art pass 4). Made in code.
func _add_vignette() -> void:
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, VIGNETTE_START, 1.0])
	fade.colors = PackedColorArray([Color(VIGNETTE_COLOR, 0.0), Color(VIGNETTE_COLOR, 0.0), VIGNETTE_COLOR])
	var round: GradientTexture2D = GradientTexture2D.new()
	round.gradient = fade
	round.width = 240
	round.height = 135
	round.fill = GradientTexture2D.FILL_RADIAL
	round.fill_from = Vector2(0.5, 0.5)
	round.fill_to = Vector2(1.08, 1.08)
	vignette = TextureRect.new()
	vignette.name = "Vignette"
	vignette.texture = round
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	move_child(vignette, 0)


## The corner's box is as big as what it holds: as wide as its longest line (or its hearts),
## taller with a second row of hearts, the energy bar or another line showing.
func _fit_panel() -> void:
	var wide: float = 0.0
	for line: Label in _lines():
		if line.visible:
			wide = maxf(wide, line_width(line))
	_box.custom_minimum_size.x = minf(wide, BOX_MAX)
	_box.size = _box.get_combined_minimum_size()
	_panel.size = _box.position * 2.0 + _box.size


## How wide `line`'s words are in its own face (px), with room for the shadow under them.
static func line_width(line: Label) -> float:
	var face: Font = line.get_theme_font(&"font")
	return ceilf(face.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, line.get_theme_font_size(&"font_size")).x) + 1.0


## The size of the corner's box (for tests).
func panel_size() -> Vector2:
	return _panel.size


## Shows or hides the energy bar; the box fits itself.
func show_energy(shown: bool) -> void:
	energy.visible = shown
	_fit_panel()


func set_energy(current: float, maximum: float) -> void:
	energy.set_energy(current, maximum)


func message_text() -> String:
	return _message.text


func hint_shown() -> bool:
	return _hint.visible


func _show_settings() -> void:
	_hint.visible = Settings.data.show_controls
	_hint_panel.visible = _hint.visible


func set_health(current: int, maximum: int) -> void:
	hearts.set_health(current, maximum)


## Pieces of heart toward the next heart, shown after the hearts.
func set_pieces(pieces: int) -> void:
	hearts.set_pieces(pieces)


## The day and the hour ("Day 3  14:20"), under the hearts.
func set_clock(text: String) -> void:
	_set_line(_clock, text)


func set_area(text: String) -> void:
	_set_line(_area, text)


## What the hero carries; an empty text hides the line.
func set_items(text: String) -> void:
	_set_line(_items, text)


## The item in hand; an empty text hides the line.
func set_equipped(text: String) -> void:
	_set_line(_equipped, text)


## Shows `text` on `line` (hidden when there is nothing to say), and fits the box again if it
## changed.
func _set_line(line: Label, text: String) -> void:
	if line.text == text and line.visible == (not text.is_empty()):
		return
	line.text = text
	line.visible = not text.is_empty()
	_fit_panel()


## The lines of the corner's box that are showing, top to bottom (for tests).
func shown_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for line: Label in _lines():
		if line.visible:
			lines.append(line.text)
	return lines


## The corner's lines of words, top to bottom.
func _lines() -> Array[Label]:
	return [_clock, _area, _items, _equipped]


func set_prompt(text: String) -> void:
	_prompt.text = text


## Build mode is open: its bar shows `held` (BuildBar.entries) with entry `chosen` lit, in the
## item bar's place; `words` stand over it, in the colour of a thing that `fits` or doesn't;
## and the controls hint says what the buttons do there.
func show_build(held: Array[Dictionary], chosen: int, words: String, fits: bool) -> void:
	item_bar.visible = false
	build_bar.visible = true
	build_bar.show_hand(held, chosen)
	_build_words.visible = true
	_build_words.text = words
	_build_words.add_theme_color_override(&"font_color", BUILD_FITS if fits else BUILD_REFUSED)
	_hint.text = BUILD_HINT


## Build mode has closed: its bar and words go, and the hint says what it said.
func hide_build() -> void:
	build_bar.visible = false
	_build_words.visible = false
	_build_words.text = ""
	_hint.text = _play_hint


## Whether build mode's bar is showing.
func is_building() -> bool:
	return build_bar.visible


## Build mode's line of words ("" when it isn't open), and whether they are a refusal's.
func build_words() -> String:
	return _build_words.text if _build_words.visible else ""


func build_refused() -> bool:
	return _build_words.visible and _build_words.get_theme_color(&"font_color") == BUILD_REFUSED


func hint_text() -> String:
	return _hint.text


## What the prompt says now ("[Right click] Pick the Turnip"), or "" when there is nothing to do
## here.
func prompt_text() -> String:
	return _prompt.text


func show_message(text: String) -> void:
	_message.text = text
	_message_left = MESSAGE_TIME


## News at the top of the screen (a quest started, moved on or finished, a skill risen, a mark
## gained, a recipe learned): it stays clear of the dialogue box, which covers the message
## line. News that comes while other news is still up joins it on a line of its own
## (NoticeLines), so neither takes the other's place, and all of it has its full time again.
func show_notice(text: String) -> void:
	_notice.text = "\n".join(NoticeLines.joined(notice_lines(), text))
	_notice_left = NOTICE_TIME


func notice_text() -> String:
	return _notice.text if _notice_left > 0.0 else ""


## The news showing now, a line each, the oldest first; none once its time is up.
func notice_lines() -> PackedStringArray:
	return _notice.text.split("\n", false) if _notice_left > 0.0 else PackedStringArray()


## Briefly darkens the screen so a scene change (or a new room) doesn't pop.
func flash(duration: float = FLASH_TIME) -> void:
	_flash_time = maxf(duration, 0.01)
	_flash_left = _flash_time


func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		_message.modulate.a = clampf(_message_left, 0.0, 1.0)
	if _notice_left > 0.0:
		_notice_left -= delta
		_notice.modulate.a = clampf(_notice_left, 0.0, 1.0)
	_flash_left = maxf(0.0, _flash_left - delta)
	_fade.color.a = (_flash_left / _flash_time) * 0.85
