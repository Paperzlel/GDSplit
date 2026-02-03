@tool
@abstract
class_name LOptionItem
extends Control

## Signal that is emitted whenever the setting is updated AND the setting
## is part of a subgroup that cannot have their properties directly
## accessed, hence the signal acts to write the data properly. Since we
## cannot determine what node group a non-root item belongs to in most
## cases, we also require that it emits itself so we can search for it
## and find the appropriate data to change.
signal setting_updated(setting: String, value: Variant, item: LOptionItem)

## The internal setting the child refers to. Set by the user. Don't touch.
var _internal_setting: String = ""

## The shared config that the option is a part of. Updates other nodes that
## reference the data when written to.
var config: LLayoutConfig = null

## Reference to the "name" label that displays the text.
@onready var _label: Label = null

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


## Overridable function that returns the location of the "name" label. Since
## some container types require a layout that doesn't suit our style, we prefer
## to access it this way so as to prevent errors.
func get_option_name_override() -> Label:
	return $"name"


## Quick validation that all our variables are appropriately designated.
func update_values() -> void:
	setting = _internal_setting
	if config != null:
		config.write_setting(setting, get_item_value())
	else:
		# Emit signal if we're non-root and have no config
		setting_updated.emit(setting, get_item_value(), self)


func _ready() -> void:
	if _label == null:
		_label = get_option_name_override()

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
		
