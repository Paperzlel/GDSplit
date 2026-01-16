@tool
class_name LOptionItemCheck
extends LOptionItem


var _internal_checked: bool = false

@onready var _box: CheckBox = $"MarginContainer/CheckBox"

@export var checked: bool:
    get:
        return _internal_checked
    set(value):
        _internal_checked = value
        if _box != null:
            _box.button_pressed = value

        update_configuration_warnings()


func get_item_value() -> Variant:
    return _internal_checked


func set_item_value(value: Variant) -> void:
    checked = bool(value)


func update_values() -> void:
    checked = _internal_checked
    value_updated.emit(checked)
    super.update_values()


func _ready() -> void:
    update_values()
    _box.toggled.connect(_on_check_button_toggled)


func _on_check_button_toggled(value: bool) -> void:
    checked = value
