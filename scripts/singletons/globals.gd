extends Node

## Signal for when the timer has began running
signal timer_began
## Signal for when the timer has been paused
signal timer_paused
## Signal for when the timer has resumed from pausing
signal timer_resumed
## Signal for when the timer has finished running
signal timer_finished
## Signal for when the timer needs to reset
signal timer_reset
## Signal for when the split ID is incremented
signal split_incremented(counter: int)

## Handle to the root window class
@onready var window: Window = $/root
## Script that is attached to the root window on startup
@onready var main_window_script = preload("res://scripts/main_window.gd")

## Global enumerations

## The type of comparison being ran. The default comparison option
## refers to the type pointed to in this class, which is set via
## the `default_comparison` setting or by cycling hotkeys.
enum Comparison
{
	## The currently running global comparison
	CURRENT_COMPARISON,
	## The current "PB" run, i.e. the fastest time a run has been completed
	PERSONAL_BEST,
	## The best time achieved for the given segment overall
	BEST_TIME,
	## The sum of all times achieved divided by the number of attempts that
	## reached this segment
	AVERAGE_TIME,
	## The worst time achieved on this segment
	WORST_TIME,
}

## The kind of calculation that is ran whenever updating a value that obeys
## these types.
enum ColumnType
{
	## The difference between the overall running time and the segment's time.
	## Multiple segments will accumulate on this value.
	DELTA,
	## The time taken overall to reach the given segment.
	SPLIT_TIME,
	## Before completion, shows the cumulative delta. Once completed, it shows 
	## the split time.
	DELTA_SPLIT_TIME,
	## The difference between the time taken for the segment and the given
	## comparison. Non-cumulative.
	SEGMENT_DELTA,
	## The time taken to complete the individual segment.
	SEGMENT_TIME,
	## Before completion, shows the segment delta. Once completed, shows the
	## split delta.
	SEGMENT_DELTA_SEGMENT_TIME,
}

## The different type of elements we can have. Declaring these and using them
## over class names is preferred for speed and simplicity in code.
enum ElementType
{
	## Timer. Runs a simple clock that can be paused and restarted.
	TYPE_TIMER,
	## Splits. Has a number of displayed segments that are cycled through during
	## a run.
	TYPE_SPLITS,
	## Maximum type, used for invalid elements.
	TYPE_MAX
}


## Global variables

## The version in a string format
var version_str: String = "0.1.0"
## The path used to load the config file.
var config_path: String = "user://config.json"

# var _current_save_path: String = ""
# var _current_save_name: String = ""

#region Version checking


## Check to see if the LinuxSplit API version is out of date. 
## Update when LinuxSplit changes the API, only on major versions past 1.0.0
func version_out_of_sync(_version: String) -> bool:
	return false


## Updates the dictionary from the old version stored in the config
## to the new version stored in the binary.
func update_version(_file: Dictionary) -> void:
	pass


## Checks and runs the update functions if needed. Notifies the user
## that changes will be made.
func check_and_update_if_needed(file: Dictionary) -> void:
	if !version_out_of_sync(file["version"]):
		return
	OS.alert(
		"File version " + file["version"] + " is out-of-date (current version is " + version_str + "). Performing version update...",
		"Upgrade Version?")
	update_version(file)


#endregion
#region Helper functions


## Creates a new `Object` of class `LType`, which is our main class for any
## elements we display in the layout.
func create_new_ltype(type: ElementType) -> LType:
	var ret: LType
	match type:
		ElementType.TYPE_TIMER:
			ret = (load("res://types/timer.tscn") as PackedScene).instantiate()
		ElementType.TYPE_SPLITS:
			ret = (load("res://types/splits.tscn") as PackedScene).instantiate()
		_:
			ret = null
		
	if ret == null:
		push_error("Could not instantiate class of type " + str(ElementType.find_key(type)) + 
		" as it was not present in ClassDB.")
	return ret


## Converts a value from the `ElementType` enum to a String.
func element_type_to_string(type: ElementType) -> String:
	var ret: String = ElementType.keys()[type] as String
	ret = ret.to_lower().right(-5)
	ret[0] = ret[0].to_upper()
	return ret


## Converts a string into the `ElementType`. Used only for conversion reasons
## and is NOT as intelligent as it sounds.
func string_to_element_type(input_str: String) -> ElementType:
	input_str = "TYPE_" + input_str.to_upper()
	return ElementType.get(input_str)


#endregion
#region Virtual functions


func _ready() -> void:
	$"/root".set_script(main_window_script)

	## Create the default config file if this is the
	## first time booting the app.
	if !FileAccess.file_exists(config_path):
		var n_file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
		
		var default: Dictionary
		default["version"] = version_str
		default["last_file"] = ""
		default["last_layout"] = ""

		n_file.store_string(JSON.stringify(default, "\t"))
		n_file.close()
		return
	
	var fa: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	var dict: Dictionary = JSON.parse_string(fa.get_as_text())
	fa.close()
	check_and_update_if_needed(dict)
	
	## No previous layouts have been used, load the default.
	if String(dict["last_file"]).is_empty():
		LayoutMetadata.load_default_layout()
	
	if String(dict["last_layout"]).is_empty():
		return

	if !FileAccess.file_exists(dict["last_file"]):
		OS.alert("File \"" + dict["last_file"] + "\" no longer exists.")
	else:
		fa = FileAccess.open(config_path, FileAccess.READ)
		var data_dict: Dictionary = JSON.parse_string(fa.get_as_text())
		if !SplitMetadata.parse_split_file_metadata(data_dict):
			OS.alert("Invalid metadata in file " + dict["last_file"] + ", unable to continue.", "Split Parse Error")

	if !FileAccess.file_exists(dict["last_layout"]):
		OS.alert("File \"" + dict["last_file"] + "\" no longer exists.")
	else:
		fa = FileAccess.open(config_path, FileAccess.READ)
		var layout_dict: Dictionary = JSON.parse_string(fa.get_as_text())
		if !LayoutMetadata.parse_layout_file_metadata(layout_dict):
			OS.alert("Invalid metadata in file " + dict["last_layout"] + ", unable to continue.", "Layout Parse Error")

#endregion