@tool
class_name LOptionItemEnumDeltaType
extends LOptionItem


var _internal_enum: Globals.DeltaType = Globals.DeltaType.TYPE_MAX


@onready var _menu: OptionButton = $"MarginContainer/OptionButton"

@export var enum_option: Globals.DeltaType:
	get:
		return _internal_enum
	set(value):
		_internal_enum = value
		if _menu != null:
			_menu.select(value)
		update_configuration_warnings()

func get_item_value() -> Variant:
	return _internal_enum


func set_item_value(value: Variant) -> void:
	enum_option = value as Globals.DeltaType


func _ready() -> void:
	var i: Globals.DeltaType = Globals.DeltaType.DELTA
	while i < Globals.DeltaType.TYPE_MAX:
		_menu.add_item(Globals.delta_type_to_string(i))
		i = ((i as int) + 1) as Globals.DeltaType
	_menu.select(0)

	update_values()
	_menu.item_selected.connect(_on_popup_item_selected)
	super._ready()


func _on_popup_item_selected(id: int) -> void:
	# ID == enum value, just cast and update
	enum_option = id as Globals.DeltaType
	update_values()
