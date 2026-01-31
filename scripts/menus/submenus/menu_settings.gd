class_name LMenuSettings
extends VBoxContainer

## Reference to the current setting that we're editing. Editing the info
## on this panel will update the 
var cfg: LLayoutConfig


func _ready() -> void:
	if cfg == null:
		push_error("LType settings has not been set.")
		return
	
	# Set each setting corresponding to the value held by the shared config.
	# If the setting points incorrectly, then warn about it not existing.
	# May cause issues in the future if update improperly.
	var cfg_dict: Dictionary[String, Variant] = cfg.get_serialized_data()
	for c: LOptionItem in get_children():
		if cfg_dict.get(c.setting) == null:
			push_error("Timer setting \"" + c.setting + "\" does not exist.")
			continue
		c.set_item_value(cfg_dict[c.setting])
		c.value_updated.connect(_on_setting_updated)


func _on_setting_updated(setting: String, value: Variant) -> void:
	# Update the element settings. 
	cfg.write_setting(setting, value)
