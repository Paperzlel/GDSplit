@tool
class_name LOptionItemColor
extends LOptionItem


## Internal storage of what color is used. Don't check.
var _internal_color: Color = Color.WHITE

## Reference to the color picker this class uses.
@onready var _color_picker: ColorPickerButton = $"MarginContainer/ColorPickerButton"

## The color to be used by this setting. Is overridden by the default settings
## on launch.
@export var color: Color:
	get:
		return _internal_color
	set(value):
		_internal_color = value
		if _color_picker != null:
			_color_picker.color = value
		
		update_configuration_warnings()


## Overrides the `OptionItem` definition.
func get_item_value() -> Variant:
	return _internal_color


## Overrides the `OptionItem` definition.
func set_item_value(value: Variant) -> void:
	color = value


## Overrides the `OptionItem` definition.
func update_values() -> void:
	color = _internal_color
	value_updated.emit(setting, color)
	super.update_values()


func _ready() -> void:
	update_values()
	_color_picker.color_changed.connect(_on_color_changed)
	super._ready()


## Called when the color value changes.
func _on_color_changed(in_color: Color) -> void:
	color = in_color
	update_values()
