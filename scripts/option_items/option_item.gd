@tool
@abstract
class_name LOptionItem
extends HSplitContainer


signal value_updated(setting: String, item: Variant)

## The internal setting the child refers to. Set by the user. Don't touch.
var _internal_setting: String = ""

## Reference to the "name" label that displays the text.
@onready var _label: Label = $"name"

@export var setting: String:
	get:
		return _internal_setting
	set(value):
		_internal_setting = value
		if _label != null:
			_label.text = OptionRemaps.option_dict[_internal_setting]
		
		update_configuration_warnings()


@abstract
func get_item_value() -> Variant

@abstract
func set_item_value(value: Variant) -> void


## Quick validation that all our variables are appropriately designated.
func update_values() -> void:
	setting = _internal_setting


func _ready() -> void:
	# Convert setting to name
	if !Engine.is_editor_hint():
		_label.text = OptionRemaps.option_dict[_internal_setting]
		if typeof(get_item_value()) == TYPE_NIL:
			push_error("OptionItem " + _internal_setting + " of class " + get_class() + " has no override for get_item_value()")
		
