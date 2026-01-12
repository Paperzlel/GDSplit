extends Node


## Layout metadata
## - Version number
## - contents[
## - ...
## - ]
## - theme
##  - BG colour
##  - split colours
##  - ...


## Parses the layout file dictionary into usable metadata.
## Files that break the standard expected (i.e. incorrect
## keys) will be notified of doing so. If an error was
## caught when unexpected, report this to the development
## team and it will be added if an API change was done.
func parse_layout_file_metadata(file: Dictionary) -> bool:
	Globals.check_and_update_if_needed(file)
	
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
				node = (load("res://types/timer.tscn") as PackedScene).instantiate()
			"LSplits":
				node = (load("res://types/splits.tscn") as PackedScene).instantiate()
			_:
				node = null
	
		if node == null:
			push_error("Could not instantiate class " + str(d["type"]) + 
			" as it was not present in ClassDB.")
			continue
		
		if !node.apply_config(d["config"]):
			push_error("Failed to apply node config.")
			node.free()
			continue
		
		$"/root/contents".add_child(node)

	return false 


func save_layout_metadata(cfg: Dictionary) -> void:
	if !DirAccess.dir_exists_absolute(Globals._current_save_path):
		OS.alert("The path to save the file at is invalid.", "Invalid Save Path")
	else:
		var fa: FileAccess = FileAccess.open(Globals._current_save_path + "/" + Globals._current_save_name + ".json", FileAccess.WRITE)
		fa.store_string(JSON.stringify(cfg, "\t"))