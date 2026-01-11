class_name LOptionMenu
extends MarginContainer

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

## FileDialog object we interact with here, attached to the root node for simplicity.
var fd: FileDialog
## The access enum we want to use for our file. Update whenever changing from
## layouts to splits and vice versa. It should NEVER read `FILE_INVALID` when
## a file has been selected.
var access_mode: AccessMode = AccessMode.FILE_INVALID


func _ready() -> void:
	$"list/exit".pressed.connect(_on_exit_pressed)
	$"list/open_split_file".pressed.connect(_on_open_split_file_pressed)
	$"list/open_layout_file".pressed.connect(_on_open_layout_file_pressed)

	fd = FileDialog.new()
	fd.name = "linuxsplit_fd"
	fd.add_filter("*.json")
	fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.size = Vector2i(800, 600)
	fd.file_selected.connect(_on_file_dialog_file_selected)
	$"/root".add_child(fd)


## Called whenever the "Open Splits File" button is pressed.
func _on_open_split_file_pressed() -> void:
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	access_mode = AccessMode.FILE_OPEN_SPLITS
	fd.show()
	fd.grab_focus()


## Called whenever the "Open Layout File" button is pressed
func _on_open_layout_file_pressed() -> void:
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	access_mode = AccessMode.FILE_OPEN_LAYOUT
	fd.show()
	fd.grab_focus()


## Sends a quit notification up and down the tree, then actually quits the engine.
## Required in cases where nodes need to perform shutdown actions.
func _on_exit_pressed() -> void:
	get_tree().root.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit(0)


## Called whenever the file dialog has had a file selected, and we want to load it.
## `path` can be any valid FS path.
func _on_file_dialog_file_selected(path: String) -> void:
	var fa: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	match access_mode:
		AccessMode.FILE_OPEN_SPLITS:
			SplitMetadata.parse_file_metadata(JSON.parse_string(fa.get_as_text()))
		AccessMode.FILE_OPEN_LAYOUT:
			SplitMetadata.parse_layout_metadata(JSON.parse_string(fa.get_as_text()))
		AccessMode.FILE_SAVE_SPLITS:
			pass
		AccessMode.FILE_SAVE_LAYOUT:
			pass
		AccessMode.FILE_INVALID:
			push_error("File access was requested without setting access_mode.")
