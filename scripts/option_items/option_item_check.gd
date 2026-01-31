@tool
class_name LOptionItemCheck
extends LOptionItem


## Internal storage of whether the box is checked. Don't set this value.
var _internal_checked: bool = false

## The `CheckBox` that determines the value outputted.
@onready var _box: CheckBox = $"MarginContainer/CheckBox"

## Whether the box is checked or not. Is overridden by the default settings on
## launch.
@export var checked: bool:
    get:
        return _internal_checked
    set(value):
        _internal_checked = value
        if _box != null:
            _box.button_pressed = value

        update_configuration_warnings()


## Overrides the `OptionItem` definition.
func get_item_value() -> Variant:
    return _internal_checked


## Overrides the `OptionItem` definition.
func set_item_value(value: Variant) -> void:
    checked = bool(value)


func _ready() -> void:
    update_values()
    _box.toggled.connect(_on_check_button_toggled)
    super._ready()


## Called when the value is updated.
func _on_check_button_toggled(value: bool) -> void:
    checked = value
    update_values()