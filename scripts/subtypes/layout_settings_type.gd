class_name LLayoutSettingsType
extends Control

signal update_current_focus(obj: Control)

@onready var _label: Label = $Label
@onready var _rect: ColorRect = $ColorRect

var type: Globals.ElementType = Globals.ElementType.TYPE_MAX

var config: Dictionary

var show_alpha: bool = false

var tmp_type_proxy: String

var type_name: String:
	set(value):
		if is_inside_tree():
			_label.text = value
		else:
			tmp_type_proxy = value


## Called whenever the current focus of the list is updated. Clears selection
## highlight if the in object is currently selected and is a layout type (as
## other `Control`s like buttons and so forth can also be focused)
func focus_updated(obj: Control) -> void:
	if obj != self and (obj is LLayoutSettingsType):
		show_alpha = false
		_rect.color.a = 0


func _ready() -> void:
	_rect.color.a = 0
	if !tmp_type_proxy.is_empty():
		_label.text = tmp_type_proxy


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		show_alpha = !show_alpha
		_rect.color.a = 255 if show_alpha else 0
		update_current_focus.emit(self if show_alpha else null)
