## The control point for a given `LType`'s layout settings. In other words,
## the class that governs how our layout settings are applied by the user
## onto the displayed tree.
class_name LTypeLayoutSettings
extends Control

signal update_current_focus(obj: Control)
signal config_changed(obj: LTypeLayoutSettings)

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


func write_to_config(key: String, value: Variant) -> void:
	config[key] = value
	config_changed.emit(self)


## Called whenever the current focus of the list is updated. Clears selection
## highlight if the in object is currently selected and is a layout type (as
## other `Control`s like buttons and so forth can also be focused)
func focus_updated(obj: Control) -> void:
	if obj != self and (obj is LTypeLayoutSettings):
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
