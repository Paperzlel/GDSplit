## Class that is implemented by all layout "types".
## Requires the implementation of a save and load for the
## layout configuration, as classes often have custom info.
@abstract
class_name LType
extends Control

## The configuration used by the given layout. Editing a config changes settings
## elsewhere, so ensure that configs are preserved prior to doing so.
var config: LLayoutConfig = null

@abstract 
func save_config() -> Dictionary[String, Variant]

@abstract
func apply_setting(setting: String, value: Variant) -> void

func post_creation() -> void:
	var settings: Dictionary[String, Variant] = config.get_config()
	for c: String in settings:
		apply_setting(c, settings[c])


static func get_default_config() -> Dictionary[String, Variant]:
	return {}


func _ready() -> void:
	if config != null:
		config.setting_changed.connect(apply_setting)
