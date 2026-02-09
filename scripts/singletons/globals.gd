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
enum ComparisonType
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
	## Invalid comparison.
	TYPE_MAX
}

## The kind of calculation that is ran whenever updating a value that obeys
## these types.
enum DeltaType
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
	## Invalid delta type.
	TYPE_MAX
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


## Enum describing what we are accessing the filesystem for.
## Since we access for either splits or for layouts, we need this enum
## over the defaults in FileDialog.
enum AccessMode {
	## Invalid option, shouldn't happen. This occuring is indicative of
	## an error in the code.
	FILE_INVALID,
	## Opening a splits file
	FILE_OPEN_SPLITS,
	## Opening a layout file
	FILE_OPEN_LAYOUT,
	## Saving a splits file
	FILE_SAVE_SPLITS,
	## Saving a layout file
	FILE_SAVE_LAYOUT
}


## Global variables

## The version in a string format
var version_str: String = "0.1.1"
## The path used to load the config file.
var config_path: String = "user://config.json"

## The dictionary containing the configuration data.
var config_data: Dictionary

var global_comparison: ComparisonType = ComparisonType.PERSONAL_BEST

## Global private variables

## FileDialog object we interact with here, attached to the root node for simplicity.
var _fd: FileDialog
## The access enum we want to use for our file. Update whenever changing from
## layouts to splits and vice versa. It should NEVER read `FILE_INVALID` when
## a file has been selected.
var _access_mode: AccessMode = AccessMode.FILE_INVALID


#region File Access

## The latest path set by the user when editing files. Is actually config data
## to save on memory usage.
var latest_layout_path: String:
	get:
		return config_data["last_layout"]
	set(value):
		config_data["last_layout"] = value
		flush_config_changes()


## The latest split path set by the user when editing files. Shadows actual config
## data to prevent desyncing bugs
var latest_split_path: String:
	get:
		return config_data["last_splits"]
	set(value):
		config_data["last_splits"] = value
		flush_config_changes()


## Opens the file dialog for a given access mode. The access mode determines
## whether to read or write files, and what kind of file to expect.
func open_fa_with(am: AccessMode) -> void:
	_fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE if am < AccessMode.FILE_SAVE_SPLITS else FileDialog.FILE_MODE_SAVE_FILE
	_access_mode = am
	_fd.show()
	_fd.grab_focus()


## Saves the layout using the latest layout path. If the path is not set, then
## it acts the same as the user pressing "Save As" instead.
func autosave_layout() -> void:
	if latest_layout_path.is_empty():
		open_fa_with(AccessMode.FILE_SAVE_LAYOUT)
	else:
		LayoutMetadata.save_layout_to_path(latest_layout_path)


func autosave_splits() -> void:
	if latest_split_path.is_empty():
		open_fa_with(AccessMode.FILE_SAVE_SPLITS)
	else:
		SplitMetadata.save_splits_to_path(latest_split_path)


## Obtains the data structure from the given file as a `Dictionary` which can
## be used by our parsing mechanisms.
func get_data_from_path(path: String) -> Dictionary:
	var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
	if fa == null or fa.get_as_text().is_empty():
		return { }
	var ret: Dictionary = JSON.parse_string(fa.get_as_text())
	fa.close()
	return ret


## Called whenever the file dialog has had a file selected, and we want to load it.
## `path` can be any valid FS path.
func _on_file_dialog_file_selected(path: String) -> void:
	var data: Dictionary = get_data_from_path(path)
	match _access_mode:
		AccessMode.FILE_OPEN_SPLITS:
			latest_split_path = path
			SplitMetadata.load_splits_from_dictionary(data)
		AccessMode.FILE_OPEN_LAYOUT:
			latest_layout_path = path
			LayoutMetadata.load_layout_from_dictionary(data)
		AccessMode.FILE_SAVE_SPLITS:
			latest_split_path = path
			SplitMetadata.save_splits_to_path(path)
		AccessMode.FILE_SAVE_LAYOUT:
			# Always update layout path here if files have changed
			latest_layout_path = path
			LayoutMetadata.save_layout_to_path(path)
		AccessMode.FILE_INVALID:
			push_error("File access was requested without setting access_mode.")

#endregion
#region Configuration Data


## Flushes any changes in our config data to disk.
func flush_config_changes() -> void:
	var fa: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
	var data: String = JSON.stringify(config_data, "\t")
	fa.store_string(data)
	fa.close()
	print(config_data)


#endregion
#region Version checking


## Check to see if the LinuxSplit API version is out of date. 
## Update when LinuxSplit changes the API, only on major versions past 1.0.0
func version_out_of_sync(version: String) -> bool:
	if version != version_str:
		return true
	
	return false


## Updates the dictionary from the old version stored in the config
## to the new version stored in the binary.
func update_version(file: Dictionary) -> void:
	if !file.has("type"):
		# Version 0.1.0 "config" file
		file["type"] = "config"
	
	match file["type"]:
		"config":
			update_config_dictionary(file)
		"layout":
			update_layout_dictionary(file)
		"splits":
			update_splits_dictionary(file)
		_:
			OS.alert("Type file exists, but no valid type was found.", "Invalid JSON file!")
	file["version"] = version_str


func update_config_dictionary(d: Dictionary) -> void:
	if d.has("last_file"):
		# Version 0.1.0 --> 0.1.1 change from "last_file" to "last_splits"
		var data: String = d.get("last_file")
		d.erase("last_file")
		d["last_splits"] = data


func update_layout_dictionary(_d: Dictionary) -> void:
	pass


func update_splits_dictionary(_d: Dictionary) -> void:
	pass


## Checks and runs the update functions if needed. Notifies the user
## that changes will be made.
func check_and_update_if_needed(file: Dictionary) -> void:
	if !version_out_of_sync(file["version"]):
		return
	OS.alert(
		"File version " + file["version"] + " is out-of-date (current version is " + version_str + "). Performing version update...",
		"Version Upgrade Required")
	update_version(file)


#endregion
#region Enum type conversion


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


## Converts a `DeltaType` to a string
func delta_type_to_string(type: DeltaType) -> String:
	var ret: String = DeltaType.keys()[type] as String
	return _key_to_string(ret)


## Converts a string to a `DeltaType`
func string_to_delta_type(input_str: String) -> DeltaType:
	input_str = input_str.to_upper().replace(" ", "_")
	return DeltaType.get(input_str)


## Converts a `ComparisonType` to a string
func comparison_type_to_string(type: ComparisonType) -> String:
	var ret: String = ComparisonType.keys()[type] as String
	return _key_to_string(ret)


## Converts a string to a `ComparisonType`
func string_to_comparison_type(input_str: String) -> ComparisonType:
	input_str = input_str.to_upper().replace(" ", "_")
	return ComparisonType.get(input_str)


func _key_to_string(key: String) -> String:
	var ret_cpy: String = key
	key = key.to_lower()

	key[0] = key[0].to_upper()
	var i: int = ret_cpy.find("_")
	var total: int = 0
	while i != -1:
		i += 1
		total += i
		key[total] = key[total].to_upper()
		ret_cpy = ret_cpy.right(-i)
		i = ret_cpy.find("_")
	key = key.replace("_", " ")
	return key


#endregion
#region MS to Time Conversion


## Converts an input of milliseconds into a time string, in the form
## `hours:minutes:seconds.milliseconds`. `decimal_count` specifies whether
## to use tenths, hundredths or thousandths to store time.
func ms_to_time(ms: int, decimal_count: int) -> String:
	if ms == -1:
		return "-"
	
	var seconds: int = ms / 1000
	var minutes: int = seconds / 60
	var hrs: int = minutes / 60
	ms %= 1000
	seconds %= 60
	minutes %= 60

	decimal_count = clamp(decimal_count, 1, 3)
	# d.p. = 10 ^ (3 - n)
	var divisor: int = 10 ** (3 - decimal_count)

	var ret: String = ("%0{div}d".format({"div": decimal_count})) % (ms / divisor)
	if minutes > 0 or hrs > 0:
		ret = (":%02d." % seconds) + ret
		if hrs > 0:
			ret = str(hrs) + (":%02d" % minutes) + ret 
		else:
			ret = str(minutes) + ret
	else:
		ret = str(seconds) + "." + ret

	return ret


#endregion
#region Helper functions


## Creates a new `Object` of class `LType`, which is our main class for any
## elements we display in the layout.
func create_new_ltype(cfg: LLayoutConfig) -> LType:
	var ret: LType
	match cfg.get_type():
		ElementType.TYPE_TIMER:
			ret = (load("res://scenes/types/timer.tscn") as PackedScene).instantiate()
		ElementType.TYPE_SPLITS:
			ret = (load("res://scenes/types/splits.tscn") as PackedScene).instantiate()
		_:
			ret = null
		
	if ret == null:
		push_error("Could not instantiate class of type " + str(ElementType.find_key(cfg.get_type())) + 
		" as it was not present in ClassDB.")
	ret.config = cfg
	# Apply all settings from the config
	ret.post_creation()
	return ret


## Creates a new layout config from the given type.
func create_new_layout_config(type: ElementType) -> LLayoutConfig:
	var ret: LLayoutConfig
	match type:
		ElementType.TYPE_TIMER:
			ret = LLayoutConfigTimer.new()
		ElementType.TYPE_SPLITS:
			ret = LLayoutConfigSplits.new()
		_:
			ret = null
	if ret == null:
		push_error("Failed to instantiate class \"" + str(ElementType.find_key(type)) + "\".")
	return ret


## Creates a new layout configuration based on the given dictionary.
func create_new_layout_config_from_dictionary(d: Dictionary[String, Variant]) -> LLayoutConfig:
	var ret: LLayoutConfig = create_new_layout_config(d["type"])
	# Force typing if it's not occured yet
	if !(d["config"] as Dictionary).is_typed():
		d["config"] = Dictionary(d["config"], TYPE_STRING, "", null, TYPE_NIL, "", null)
	ret._dict = d["config"]
	return ret


## Converts a string to a Color, because the JSON stored isn't using a proper format
## in Godot and conversion messes up.
func string_to_color(s: String) -> Color:
	s = s.right(-1)
	s = s.left(-1)
	var arr: PackedStringArray = s.split(", ")
	var col: Color
	for i in range(arr.size()):
		col[i] = arr[i].to_float()
	return col


#endregion
#region Virtual functions


func _ready() -> void:
	$"/root".set_script(main_window_script)
	await get_tree().root.ready

	# Create FileDialog and enabled filtering
	_fd = FileDialog.new()
	_fd.name = "linuxsplit_fd"
	_fd.add_filter("*.json")
	_fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	_fd.access = FileDialog.ACCESS_FILESYSTEM
	_fd.size = Vector2i(800, 600)
	_fd.file_selected.connect(_on_file_dialog_file_selected)
	$"/root".add_child.call_deferred(_fd)

	# Create the default config file if this is the first time booting the app.
	if !FileAccess.file_exists(config_path):
		var n_file: FileAccess = FileAccess.open(config_path, FileAccess.WRITE)
		
		var default: Dictionary
		default["version"] = version_str
		default["last_splits"] = ""
		default["last_layout"] = ""
		default["type"] = "config"

		n_file.store_string(JSON.stringify(default, "\t"))
		n_file.close()
		return
	
	# Read the config from the path if it does in fact exist.
	var fa: FileAccess = FileAccess.open(config_path, FileAccess.READ)
	config_data = JSON.parse_string(fa.get_as_text())
	fa.close()
	check_and_update_if_needed(config_data)
	
	# No previous layouts have been used, load the default.
	if latest_layout_path.is_empty():
		LayoutMetadata.load_default_layout()
	else:
		var data: Dictionary = get_data_from_path(latest_layout_path)
		if data.is_empty():
			push_error("Failed to get data from path. Loading default instead.")
			LayoutMetadata.load_default_layout()
		else:
			LayoutMetadata.load_layout_from_dictionary(data)
	
	# No previous splits have been used, 
	if String(config_data["last_splits"]).is_empty():
		SplitMetadata.load_default_splits()
	else:
		var data: Dictionary = get_data_from_path(latest_split_path)
		if data.is_empty():
			push_error("Failed to get data from path. Loading default instead.")
			SplitMetadata.load_default_splits()
		else:
			SplitMetadata.load_splits_from_dictionary(data)


func _exit_tree() -> void:
	flush_config_changes()

#endregion
