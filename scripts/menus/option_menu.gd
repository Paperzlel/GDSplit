class_name LOptionMenu
extends MarginContainer


## Called whenever the "Edit Layout" button is pressed. Opens the split editor
## for running.
func _on_edit_splits_pressed() -> void:
	(get_parent() as LWindowHandler).open_subwindow_requested.emit("split_settings")


## Called whenever the "Open Splits File" button is pressed.
func _on_open_split_file_pressed() -> void:
	Globals.open_fa_with(Globals.AccessMode.FILE_OPEN_SPLITS)


## Called whenever the "Edit Layout" button is pressed. Opens the layout editor
## for running.
func _on_edit_layout_pressed() -> void:
	# We know the parent is of type LWindowHandler, so call its signal to request
	# opening a window. Technically breaks signal up/call down but in this instance
	# it's okay.
	(get_parent() as LWindowHandler).open_subwindow_requested.emit("layout_settings")


## Called whenever the "Open Layout File" button is pressed
func _on_open_layout_file_pressed() -> void:
	Globals.open_fa_with(Globals.AccessMode.FILE_OPEN_LAYOUT)


## Sends a quit notification up and down the tree, then actually quits the engine.
## Required in cases where nodes need to perform shutdown actions.
func _on_exit_pressed() -> void:
	get_tree().root.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit(0)
