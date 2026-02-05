@tool
class_name LOptionItemDictionaryColumn
extends LOptionItemDictionary


@onready var _column_delta: LOptionItem = $"MarginContainer/config_options/column_delta_option"
@onready var _column_comparison: LOptionItem = $"MarginContainer/config_options/column_comparison_option"
@onready var _column_label: LOptionItem = $"MarginContainer/config_options/column_label_option"

func update_children() -> void:
	# Wait for the node to enter the tree prior to updating the nodes
	if !is_inside_tree():
		await ready
	_column_delta.set_item_value(_internal_dict["column_delta"])
	_column_comparison.set_item_value(_internal_dict["column_comparison"])
	_column_label.set_item_value(_internal_dict["column_label"])


func _ready() -> void:
	_column_delta.setting_updated.connect(_on_column_data_changed)
	_column_comparison.setting_updated.connect(_on_column_data_changed)
	_column_label.setting_updated.connect(_on_column_data_changed)


func _on_move_up_pressed() -> void:
	move_up_requested.emit(self)


func _on_move_down_pressed() -> void:
	move_down_requested.emit(self)


func _on_remove_pressed() -> void:
	remove_requested.emit(self)
