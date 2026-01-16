@tool
class_name LOptionItemColor
extends LOptionItem


var _internal_color: Color = Color.WHITE

@onready var _color_picker: ColorPickerButton = $"MarginContainer/ColorPickerButton"

@export var color: Color:
    get:
        return _internal_color
    set(value):
        _internal_color = value
        if _color_picker != null:
            _color_picker.color = value
        
        update_configuration_warnings()


func get_item_value() -> Variant:
    return _internal_color


func set_item_value(value: Variant) -> void:
    color = value


func update_values() -> void:
    color = _internal_color
    value_updated.emit(color)
    super.update_values()


func _ready() -> void:
    _color_picker.color_changed.connect(_on_color_changed)


func _on_color_changed(in_color: Color) -> void:
    color = in_color
