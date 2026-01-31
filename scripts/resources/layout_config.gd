## Resource class that deals with the configuration of a specific scene object.
##
## This resource is an abstract resource created for the purpose of applying layout
## settings to nodes in the tree and ensuring the settings menu is displaying the 
## correct items in the correct order with the correct options.
class_name LLayoutConfig
extends Resource

## Emitted whenever the variable associated to the setting changes. All objects
## associated with the resource should connect to this signal to avoid sharing
## redundant data.
signal setting_changed(setting: String, value: Variant)

# Internal data for each variable. Saves on serialization and size.
var _dict: Dictionary[String, Variant]

# Internal type enum. Accessed via getter only.
var _type: Globals.ElementType = Globals.ElementType.TYPE_MAX


## Obtains the serialized data for the given config. Serialized data should be able to
## save as valid JSON and can then be stored on-disk to be used by various parts of the
## application.
##
## Do note that all dictionaries are passed by reference and are not copied whenever accessed.
## This is likely to cause problems should you modify the accessed data.
func get_serialized_data() -> Dictionary[String, Variant]:
	if _dict.is_empty():
		return { "error": "Dictionary data is empty." }
	return _dict


## Obtains the type of element that this resource has the settings for. Used in certain places
## for code validation and for simplification of data being passed around.
func get_type() -> Globals.ElementType:
	return _type


func write_setting(setting: String, value: Variant) -> bool:
	if _dict.get(setting) == null:
		return false
	
	_dict[setting] = value
	setting_changed.emit(setting, value)
	return true
