class_name LMenuSettings
extends VBoxContainer

## Reference to the current setting that we're editing. Editing the info
## on this panel will update the 
var ltype_ref: LTypeLayoutSettings


func _ready() -> void:
	if ltype_ref == null:
		push_error("LType settings has not been set.")
		return
	
	# Set the settings as expected. Every setting name must correspond to its
	# conjoined value, so ensure the names match properly. Check for spelling
	# mistakes as well.
	for c: LOptionItem in get_children():
		if ltype_ref.config.get(c.setting) == null:
			push_error("Timer setting \"" + c.setting + "\" does not exist.")
			continue
		c.set_item_value(ltype_ref.config[c.setting])
		c.value_updated.connect(_on_setting_updated)


func _on_setting_updated(setting: String, value: Variant) -> void:
	# Update the element settings. 
	ltype_ref.write_to_config(setting, value)
