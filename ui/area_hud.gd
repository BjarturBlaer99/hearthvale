class_name AreaHud
extends CanvasLayer
## The HUD: hearts, where you are, what you're carrying, the prompt for whatever the hero
## can use, short messages, the dialogue box, the item and pause menus, and a screen flash for
## scene changes. The controls hint shows or hides with the player's setting.

const MESSAGE_TIME: float = 3.0
const FLASH_TIME: float = 0.35

var _message_left: float = 0.0
var _flash_left: float = 0.0
var _flash_time: float = FLASH_TIME

@onready var hearts: HeartsBar = $Panel/Hearts
@onready var dialogue: DialogueBox = $DialogueBox
@onready var item_menu: ItemMenu = $ItemMenu
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var _hint: Label = $Hint
@onready var _equipped: Label = $Panel/Equipped
@onready var _area: Label = $Panel/Area
@onready var _items: Label = $Panel/Items
@onready var _prompt: Label = $Prompt
@onready var _message: Label = $Message
@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	_prompt.text = ""
	_message.text = ""
	_show_settings()
	EventBus.settings_changed.connect(_show_settings)


func message_text() -> String:
	return _message.text


func hint_shown() -> bool:
	return _hint.visible


func _show_settings() -> void:
	_hint.visible = Settings.data.show_controls


func set_health(current: int, maximum: int) -> void:
	hearts.set_health(current, maximum)


## Pieces of heart toward the next heart, shown after the hearts.
func set_pieces(pieces: int) -> void:
	hearts.set_pieces(pieces)


func set_area(text: String) -> void:
	_area.text = text


func set_items(text: String) -> void:
	_items.text = text


func set_equipped(text: String) -> void:
	_equipped.text = text


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_message(text: String) -> void:
	_message.text = text
	_message_left = MESSAGE_TIME


## Briefly darkens the screen so a scene change (or a new room) doesn't pop.
func flash(duration: float = FLASH_TIME) -> void:
	_flash_time = maxf(duration, 0.01)
	_flash_left = _flash_time


func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		_message.modulate.a = clampf(_message_left, 0.0, 1.0)
	_flash_left = maxf(0.0, _flash_left - delta)
	_fade.color.a = (_flash_left / _flash_time) * 0.85
