@tool
class_name LOptionItemNumber
extends LOptionItem


## Internal storage of what the number is. Don't set.
var _internal_number: int = 0

## Reference to the `SpinBox` used to set the values. 
@onready var _sbox: SpinBox = $"MarginContainer/SpinBox"

## The number to use for this value. Overriden by the defaults.
@export var number: int:
    get:
        return _internal_number
    set(value):
        _internal_number = value
        if _sbox != null:
            _sbox.value = value


## Overrides the `OptionItem` definition.
func get_item_value() -> Variant:
    return _internal_number


## Overrides the `OptionItem` definition.
func set_item_value(value: Variant) -> void:
    number = value


func _ready() -> void:
    update_values()
    _sbox.value_changed.connect(_on_number_changed)
    super._ready()


## Called when the number changes. Does so every time, which may be expensive
## and possibly buggy at some point. May need a timer to reduce this.
func _on_number_changed(in_num: float) -> void:
    number = int(in_num)
    update_values()
