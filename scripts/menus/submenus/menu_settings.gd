class_name LMenuSettings
extends ScrollContainer

## Reference to the current setting that we're editing. Editing the info
## on this panel will update the 
var cfg: LLayoutConfig

@onready var list: VBoxContainer = $"list"

func _ready() -> void:
	if cfg == null:
		push_error("LType settings has not been set.")
		return
	
	# Set each setting corresponding to the value held by the shared config.
	# If the setting points incorrectly, then warn about it not existing.
	# May cause issues in the future if update improperly.
	var cfg_dict: Dictionary[String, Variant] = cfg.get_config()
	for c: LOptionItem in list.get_children():
		if !cfg_dict.has(c.setting):
			push_error("Timer setting \"" + c.setting + "\" does not exist.")
			continue
		c.set_item_value(cfg_dict[c.setting])
		c.config = cfg
