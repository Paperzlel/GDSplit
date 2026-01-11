extends Node

## Config file contains:
## - Version ID
## - Last used file
## - Last used theme

## Layout metadata
## - Version number
## - contents[
## - ...
## - ]
## - theme
##  - BG colour
##  - split colours
##  - ...

## The path used to load the config file.
var config_path: String = "user://config.json"
## The version in a string format
var version_str: String = "0.1.0"

## Array of split names, stored here for reasons
var splits: Array[String] = []
## Array of split metadata, accessed by finding the ID for the split
## from the split array.
var _splits_metadata: Array[Dictionary] = []

var _current_save_path: String = ""
var _current_save_name: String = ""

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


## Parses the split file metadata, and updates if needed.
func parse_split_file_metadata(file: Dictionary) -> bool:
	check_and_update_if_needed(file)
	
	_splits_metadata = file["splits"]

	for d: Dictionary in _splits_metadata:
		var split_name: String = String(d.get("name"))
		if split_name.is_empty():
			split_name = ""
		splits.push_back(split_name)

	return true


## Parses the layout file dictionary into usable metadata.
## Files that break the standard expected (i.e. incorrect
## keys) will be notified of doing so. If an error was
## caught when unexpected, report this to the development
## team and it will be added if an API change was done.
func parse_layout_file_metadata(file: Dictionary) -> bool:
	check_and_update_if_needed(file)
	
	var contents: Array[Dictionary] = file.get("contents")
	if contents == null:
		push_error("Failed to obtain the split contents, unable
			to load layout.")
		return false

	for d: Dictionary in contents:
		if d.get("type") == null:
			printerr("Type field is null, skipping...")
			continue
		
		var node: LType
		match d["type"]:
			"LTimer":
				node = LTimer.new()
				node.apply_config(d["config"])
			"LSplits":
				node = LSplits.new()
				node.apply_config(d["config"])
			_:
				continue

	return false 


func save_layout_metadata(cfg: Dictionary) -> void:
	if !DirAccess.dir_exists_absolute(_current_save_path):
		OS.alert("The path to save the file at is invalid.", "Invalid Save Path")
	else:
		var fa: FileAccess = FileAccess.open(_current_save_path + "/" + _current_save_name + ".json", FileAccess.WRITE)
		fa.store_string(JSON.stringify(cfg, "\t"))



func _ready() -> void:
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
	
	## No previous layouts or splits have been used
	if String(dict["last_file"]).is_empty() && String(dict["last_layout"]).is_empty():
		return

	if !FileAccess.file_exists(dict["last_file"]):
		OS.alert("File \"" + dict["last_file"] + "\" no longer exists.")
	else:
		fa = FileAccess.open(config_path, FileAccess.READ)
		var data_dict: Dictionary = JSON.parse_string(fa.get_as_text())
		if !parse_split_file_metadata(data_dict):
			OS.alert("Invalid metadata in file " + dict["last_file"] + ", unable to continue.", "Split Parse Error")

	if !FileAccess.file_exists(dict["last_layout"]):
		OS.alert("File \"" + dict["last_file"] + "\" no longer exists.")
	else:
		fa = FileAccess.open(config_path, FileAccess.READ)
		var layout_dict: Dictionary = JSON.parse_string(fa.get_as_text())
		if !parse_layout_file_metadata(layout_dict):
			OS.alert("Invalid metadata in file " + dict["last_layout"] + ", unable to continue.", "Layout Parse Error")
