@tool
@abstract
class_name LOptionItem
extends Control

## The internal setting the child refers to. Set by the user. Don't touch.
var _internal_setting: String = ""

## The shared config that the option is a part of. Updates other nodes that
## reference the data when written to.
var config: LLayoutConfig = null

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
	if config != null:
		config.write_setting(setting, get_item_value())


func _ready() -> void:
	# Convert setting to name if not in editor and name isn't empty
	if !Engine.is_editor_hint() and !_internal_setting.is_empty():
		var value = OptionRemaps.option_dict.get(_internal_setting)
		if value == null:
			_label.text = ""
			_label.hide()
			return
		else:
			_label.show()		# Show, if not explicitly hidden.
		
		_label.text = value
		if typeof(get_item_value()) == TYPE_NIL:
			push_error("OptionItem " + _internal_setting + " of class " + get_class() + " has no override for get_item_value()")
		
