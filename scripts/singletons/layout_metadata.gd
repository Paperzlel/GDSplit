extends Node


@onready var contents_node: LContentsPanel = $"/root/contents"

## Layout metadata
## - Version number
## - contents[
## - ...
## - ]
## - theme
##  - BG colour
##  - split colours
##  - ...

## Private dictionary containing our metadata for the layout. Contains theme
## information as well as the contents themselves.
var _layout_metadata: Dictionary

## The layout contents, or every node present on-screen (or off-screen) in this
## given layout. Overrides `_layout_metadata` internally.
var layout_contents: Array[Dictionary]:
	get:
		return _layout_metadata["contents"]
	set(value):
		_layout_metadata["contents"] = value


## Updates the contents within the current layout. Clears the contents, then redraws
## it all bigger and better than ever before.
func update_layout_contents(contents: Array[Dictionary]) -> void:
	# Clear contents prior to writing
	contents_node.clear_contents()
	# Check dictionary for what to modify the contents to
	for d: Dictionary in contents:
		if d.get("type") == Globals.ElementType.TYPE_MAX:
			printerr("Type field is null, skipping...")
			continue
		
		var node: LType
		match d["type"]:
			Globals.ElementType.TYPE_TIMER:
				node = (load("res://types/timer.tscn") as PackedScene).instantiate()
			Globals.ElementType.TYPE_SPLITS:
				node = (load("res://types/splits.tscn") as PackedScene).instantiate()
			_:
				node = null


		if node == null:
			push_error("Could not instantiate class " + str(int(d["type"]) as Globals.ElementType) + 
			" as it was not present in ClassDB.")
			continue
		
		if !node.apply_config(d["config"]):
			push_error("Failed to apply node config.")
			node.free()
			continue
		
		contents_node.add_child(node)
	layout_contents = contents
	print_verbose("Layout contents updated.")


## Parses the layout file dictionary into usable metadata.Files that break the
## standard expected (i.e. incorrect keys) will be notified of doing so. If an
## error was caught when unexpected, report this to the development team and 
## it will be added if an API change was done.
func parse_layout_file_metadata(file: Dictionary) -> bool:
	Globals.check_and_update_if_needed(file)

	if contents_node == null:
		# It exists right now but displays null because of _ready() process order.
		contents_node = $"/root/contents"
	
	var contents: Array[Dictionary] = file.get("contents")
	if contents == null:
		push_error("Failed to obtain the split contents, unable
			to load layout.")
		return false

	update_layout_contents(contents)

	# Parsing went well, we can use the layout metadata. Only assign if they're
	# not equal to one another.
	if _layout_metadata != file:
		_layout_metadata = file

	return true 


## Saves the layout metadata to the current file. Does not currently function
## properly.
func save_layout_metadata(cfg: Dictionary) -> void:
	if !DirAccess.dir_exists_absolute(Globals._current_save_path):
		OS.alert("The path to save the file at is invalid.", "Invalid Save Path")
	else:
		var fa: FileAccess = FileAccess.open(Globals._current_save_path + "/" + Globals._current_save_name + ".json", FileAccess.WRITE)
		fa.store_string(JSON.stringify(cfg, "\t"))
