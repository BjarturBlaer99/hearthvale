class_name DistrictHud
extends CanvasLayer
## Greybox HUD: water level, what the player is doing, stamina, the prompt for whatever is
## underfoot, short messages, and the screen flash that covers a water redraw.

const MESSAGE_TIME: float = 3.0
const FLASH_TIME: float = 0.35
const STAMINA_OK: Color = Color(0.45, 0.80, 0.45)
const STAMINA_EXHAUSTED: Color = Color(0.85, 0.35, 0.30)

var _message_left: float = 0.0
var _flash_left: float = 0.0
var _stamina_width: float = 0.0

@onready var _water: Label = $Panel/Water
@onready var _status: Label = $Panel/Status
@onready var _items: Label = $Panel/Items
@onready var _stamina_fill: ColorRect = $Panel/StaminaBack/StaminaFill
@onready var _prompt: Label = $Prompt
@onready var _message: Label = $Message
@onready var _fade: ColorRect = $Fade


func _ready() -> void:
	_stamina_width = _stamina_fill.size.x
	_prompt.text = ""
	_message.text = ""


func set_water(text: String) -> void:
	_water.text = text


func set_status(text: String) -> void:
	_status.text = text


func set_items(text: String) -> void:
	_items.text = text


func set_stamina(fraction: float, exhausted: bool) -> void:
	_stamina_fill.size.x = _stamina_width * clampf(fraction, 0.0, 1.0)
	_stamina_fill.color = STAMINA_EXHAUSTED if exhausted else STAMINA_OK


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_message(text: String) -> void:
	_message.text = text
	_message_left = MESSAGE_TIME


## Briefly darkens the screen so an instant redraw doesn't pop (TECH_DESIGN §3.3).
func flash() -> void:
	_flash_left = FLASH_TIME


func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		_message.modulate.a = clampf(_message_left, 0.0, 1.0)
	_flash_left = maxf(0.0, _flash_left - delta)
	_fade.color.a = (_flash_left / FLASH_TIME) * 0.85
