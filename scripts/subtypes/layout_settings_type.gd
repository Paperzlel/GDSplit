class_name LLayoutSettingsType
extends Control

signal update_current_focus(obj: Control)

@onready var _label: Label = $Label
@onready var _rect: ColorRect = $ColorRect
var show_alpha: bool = false

var type_name: String:
	set(value):
		_label.text = value


func _ready() -> void:
	# focus_entered.connect(_on_focus_entered)
	# focus_exited.connect(_on_focus_exited)
	update_current_focus.connect(_on_focus_updated)
	_rect.color.a = 0


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		show_alpha = !show_alpha
		_rect.color.a = 255 if show_alpha else 0
	
	if show_alpha:
		update_current_focus.emit(self)
	else:
		update_current_focus.emit(null)

func _on_focus_entered() -> void:
	_rect.color.a = 255


func _on_focus_exited() -> void:
	# Clear colour on exit and reset show_alpha so clicks work
	# _rect.color.a = 0
	show_alpha = false


func _on_focus_updated(obj: Control) -> void:
	if obj != self:
		show_alpha = false
		_rect.color.a = 0
