@tool
@abstract
class_name LOptionItem
extends HSplitContainer


signal value_updated(setting: String, item: Variant)


var _internal_name: String = ""
@onready var _label: Label = $"name"

@export var option_name: String:
    get:
        return _internal_name
    set(value):
        _internal_name = value
        if _label != null:
            _label.text = value
        
        update_configuration_warnings()


@abstract
func get_item_value() -> Variant

@abstract
func set_item_value(value: Variant) -> void


## Quick validation that all our variables are appropriately designated.
func update_values() -> void:
    option_name = _internal_name


func _ready() -> void:
    update_values()
    if !Engine.is_editor_hint():
        _label.text = _internal_name
        if typeof(get_item_value()) == TYPE_NIL:
            push_error("OptionItem " + _internal_name + " of class " + get_class() + " has no override for get_item_value()")
        

