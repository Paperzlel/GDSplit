@tool
@abstract
## Base implementation of a dictionary container. These are created normally to
## be contained within an `OptionItemArray` and hence have several signals they
## must connect to allow their data to be properly transferred. This is a 
## consequence of how the system was designed and may be changed in the future.
class_name LOptionItemDictionary
extends LOptionItem

signal move_up_requested(obj: LOptionItemDictionary)
signal move_down_requested(obj: LOptionItemDictionary)
signal remove_requested(obj: LOptionItemDictionary)

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


@abstract
func update_children() -> void

func _on_column_data_changed(opt_setting: String, value: Variant, _item: LOptionItem) -> void:
    emit_signal("setting_updated", opt_setting, value, self)
