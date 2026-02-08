extends ColorRect

@onready var split_list: VBoxContainer = $"contents/right_margin/right_bg/right_margin/right_elements/split_tabs/item_list/scroll_list/split_list"

var split_item_res: PackedScene = preload("uid://darj26wdyu04b")

var current_focus: LSplitItemListElement = null

#region Utility Functions


func get_current_focus_index() -> int:
	var children: Array[Node] = split_list.get_children()
	return children.find(current_focus)


func move_focus(up: bool) -> void:
	if current_focus == null:
		return

	var old_idx: int = get_current_focus_index()
	if old_idx == -1:
		current_focus = null
		return
	
	SplitMetadata.move_split_to(old_idx, old_idx - 1 if up else old_idx + 1)


#endregion
#region Button Event Handlers

func _on_category_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	
	SplitMetadata.game_category = new_text


func _on_game_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	
	SplitMetadata.game_name = new_text


func _on_add_split_pressed() -> void:
	# Check for focus 
	if current_focus != null:
		# Node has focus
		var idx: int = get_current_focus_index()
		if idx == -1:
			# Focus is stale, clear it just in case.
			current_focus = null
			SplitMetadata.add_split()
		else:
			# Add below current index, moves current node down
			SplitMetadata.add_split_at(idx + 1)
	else:
		# If no focus, append to bottom
		SplitMetadata.add_split()


func _on_move_split_up_pressed() -> void:
	move_focus(true)


func _on_move_split_down_pressed() -> void:
	move_focus(false)


func _on_remove_split_pressed() -> void:
	if current_focus == null:
		return
	
	var idx: int = get_current_focus_index()
	if idx == -1:
		# Don't try to remove an invalid focus, clear it
		current_focus = null
		return

	SplitMetadata.remove_split_at(idx)


func _on_clear_splits_pressed() -> void:
	SplitMetadata.clear_all_splits()


func _on_save_splits_pressed() -> void:
	Globals.autosave_splits()


func _on_save_splits_as_pressed() -> void:
	Globals.open_fa_with(Globals.AccessMode.FILE_SAVE_SPLITS)


func _on_load_splits_pressed() -> void:
	Globals.open_fa_with(Globals.AccessMode.FILE_OPEN_SPLITS)


func _on_exit_pressed() -> void:
	get_window().visible = false


#endregion
#region Callable Event Handlers


func _on_split_added(idx: int) -> void:
	var split_item: LSplitItemListElement = split_item_res.instantiate()
	split_item.cfg = SplitMetadata.splits_cfgs[idx]
	split_item.update_current_focus.connect(_on_split_list_focus_updated)
	split_list.add_child(split_item)
	split_list.move_child(split_item, idx)



func _on_split_removed(idx: int) -> void:
	var split_item: LSplitItemListElement = split_list.get_children()[idx]
	split_list.remove_child(split_item)
	split_item.queue_free()


func _on_split_moved(old_idx: int, new_idx: int) -> void:
	var split_item: LSplitItemListElement = split_list.get_children()[old_idx]
	split_list.move_child(split_item, new_idx)


func _on_splits_cleared() -> void:
	var children: Array[Node] = split_list.get_children()
	for c: Node in children:
		c = c as LSplitItemListElement
		if c == null:
			continue
		
		split_list.remove_child(c)
		c.queue_free()


func _on_split_list_focus_updated(obj: LSplitItemListElement) -> void:
	current_focus = obj
	for n: Node in split_list.get_children():
		n = n as LSplitItemListElement
		# Header is not valid here
		if n == null:
			continue
		
		n.focus_updated(obj)



#endregion
#region Virtual Functions


func _ready() -> void:
	# Connect functions
	SplitMetadata.split_added.connect(_on_split_added)
	SplitMetadata.split_removed.connect(_on_split_removed)
	SplitMetadata.split_moved.connect(_on_split_moved)
	SplitMetadata.splits_cleared.connect(_on_splits_cleared)

	for i in range(SplitMetadata.splits_cfgs.size()):
		_on_split_added(i)


#endregion
