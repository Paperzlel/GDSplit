extends Node

## Emitted whenever the layout has been updated via means other than the
## layout settings menu.
signal layout_updated
## Emitted whenever the layout needs to have all corresponding data removed.
signal layout_cleared


@onready var contents_node: LContentsPanel = $"/root/contents"

## Layout metadata
## - Version number
## - Data type
## - contents[
## - ...
## - ]
## - theme
##  - BG colour
##  - split colours
##  - ...

## Default contents
var _default_contents: Array[Dictionary] = [
	{
		"type": Globals.ElementType.TYPE_TIMER,
		# Note the availability to read information here for the future
		"config": LTimer.get_default_config()
	}
]

## Default settings.
var _default_layout: Dictionary = {
	"version": Globals.version_str,
	"contents": _default_contents, # Needed to get typed arrays working.
	"type": "layout",
}

## Private dictionary containing our metadata for the layout. Contains theme
## information as well as the contents themselves.
var _layout_metadata: Dictionary

## The layout contents, or every node present on-screen (or off-screen) in this
## given layout. Overrides `_layout_metadata` internally.
var layout_contents: Array[Dictionary]:
	get:
		return _layout_metadata["contents"] as Array[Dictionary]
	set(value):
		_layout_metadata["contents"] = value

#region Data modifiers


## Moves a config data dictionary from index A to index B, and moves the
## corresponding `LType` as well.
func move_config_data_to(from: int, to: int) -> void:
	var data_copy: Dictionary = layout_contents.pop_at(from)
	if to >= layout_contents.size():
		layout_contents.push_back(data_copy)
	else:
		if layout_contents.insert(to, data_copy) != OK:
			push_error("Failed to insert data into the layout contents properly.")
	contents_node.move_child(contents_node.get_child(from), to)


## Removes the config data held at the given index, and frees the `LType` associated
## with the given data.
func remove_config_data_at(idx: int) -> void:
	layout_contents.remove_at(idx)
	var child: LType = contents_node.get_child(idx)
	contents_node.remove_child(child)
	child.queue_free()


## Adds config data and a corresponding `LType` at the given position. If the
## position is -1, (indicative of a node-not-found error elsewhere), then the
## content is appended at the end of the dictionary.
func add_config_data_at(idx: int, d: LLayoutConfig) -> void:
	if idx == -1:
		layout_contents.push_back(d.get_serialized_data() as Dictionary)
	else:
		layout_contents.insert(idx, d.get_serialized_data() as Dictionary)
	var new_node: LType = add_new_node_from_item_dictionary(d)
	if idx != -1:
		contents_node.move_child(new_node, idx)


#endregion
#region Layout saving/loading


## Loads the default layout. We know what contents exist already so we can
## skip reading the data safely and It Just Works.
func load_default_layout() -> void:
	layout_cleared.emit()
	_layout_metadata = _default_layout.duplicate(true)
	# Set contents node, order can change sometimes
	if contents_node == null:
		contents_node = $"/root/contents"
	layout_contents[0] = Dictionary(layout_contents[0], TYPE_STRING, "", null, TYPE_NIL, "", null)
	add_new_node_from_item_dictionary(Globals.create_new_layout_config_from_dictionary(layout_contents[0]))
	print_verbose("Default layout loaded.")#
	layout_updated.emit()


## Takes the dictionary created from JSON and attempts to read it back into 
## usable data for us. If a specific section that we need isn't present, it
## tells the user and returns false.
func load_layout_from_dictionary(dict: Dictionary) -> bool:
	Globals.check_and_update_if_needed(dict)

	if dict.has("type") and dict["type"] != "layout":
		OS.alert("Attempted to load an invalid layout file. Layout will not be loaded.")
		return false

	if !dict.has("contents"):
		OS.alert("Invalid JSON. Layout will not be loaded.")
		return false
	
	# Clear current layout
	layout_cleared.emit()

	dict["contents"] = Array(dict["contents"], TYPE_DICTIONARY, "", null)
	var contents: Array[Dictionary] = dict["contents"]

	# Initialize new nodes into the tree from the config
	for d: Dictionary in contents:
		d = Dictionary(d, TYPE_STRING, "", null, TYPE_NIL, "", null)
		add_new_node_from_item_dictionary(Globals.create_new_layout_config_from_dictionary(d))

	# Parsing went well, we can use the layout metadata. All references to sub-data
	# remain constant, 
	_layout_metadata = dict
	layout_updated.emit()
	return true 


## Saves the current layout metadata to a given path.
func save_layout_to_path(path: String) -> void:
	var fa: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		OS.alert("Failed to create file at the given directory \"" + path + "\".")
		return
	
	var data: String = JSON.stringify(_layout_metadata, "\t")
	fa.store_line(data)
	fa.close()

#endregion
#region Misc functions

## Gets the corresponding LType node from a given index. NOTE: We could use
## the contents dictionary for this, which I might end up doing anyways.
## Should also consider making them null upon exporting to prevent JSON
## readback from being messy.
func get_ltype_from_index(idx: int) -> LType:
	var children: Array[Node] = contents_node.get_children()
	if idx < 0 || idx >= children.size():
		push_error("Invalid contents ID of " + str(idx) + ".")
		return null
	
	return children[idx] if children[idx] is LType else null


## Creates a new node and appends it to the tree, setting the configuration
## as defined in `dict`. This does not move the data in any way.
func add_new_node_from_item_dictionary(cfg: LLayoutConfig) -> LType:
	if cfg.get_type() >= Globals.ElementType.TYPE_MAX:
		push_error("Type field is invalid, skipping adding node.")
		return null

	var node: LType = Globals.create_new_ltype(cfg)
	if node != null:
		contents_node.add_child(node)
	return node

#endregion
