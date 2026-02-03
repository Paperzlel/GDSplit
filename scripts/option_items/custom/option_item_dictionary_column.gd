@tool
class_name LOptionItemDictionaryColumn
extends LOptionItem


@onready var _column_delta: LOptionItem = $"MarginContainer/config_options/column_delta_option"
@onready var _column_comparison: LOptionItem = $"MarginContainer/config_options/column_comparison_option"


var _internal_dict: Dictionary = {}

@export var column_data: Dictionary:
	get:
		return _internal_dict
	set(value):
		# Don't really care about type safety here, but should still check
		_internal_dict = value
		update_children()
		update_configuration_warnings()


func get_item_value() -> Variant:
	return _internal_dict


func set_item_value(value: Variant) -> void:
	column_data = value


func update_children() -> void:
	# Wait for the node to enter the tree prior to updating the nodes
	await ready
	_column_delta.set_item_value(_internal_dict["column_delta"])
	_column_comparison.set_item_value(_internal_dict["column_comparison"])
	# TODO: Add label


func _ready() -> void:
	_column_delta.setting_updated.connect(_on_column_data_changed)
	_column_comparison.setting_updated.connect(_on_column_data_changed)
	#TODO: Add label as well


func _on_column_data_changed(opt_setting: String, value: Variant, _item: LOptionItem) -> void:
	emit_signal("setting_updated", opt_setting, value, self)
