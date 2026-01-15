extends HBoxContainer

## The node where all our layout items will exist.
@onready var layout_list: VBoxContainer = $right_bg/bg_margin/inner_menu/menu_margin/menu_list
## The resource corresponding to the layout setting "type" scene that is displayed
## whenever an element is added or removed
@onready var layout_type_res: PackedScene = preload("res://types/subtypes/layout_settings_type.tscn")

var element_list_popup: PopupMenu

## The node that is currently "in focus". This refers to the element that will
## be updated whenever an action in the left-hand bar is selected.
var current_focus: Control = null

## The cached contents of the layout, saved for future reference. We update
## this first before sending the new version to the metadata holder and forcing
## an update on everybody else that uses it.
var cached_contents: Array[Dictionary]


func new_llayout_settings_type(type: Globals.ElementType, config: Dictionary) -> LLayoutSettingsType:
	var ret: LLayoutSettingsType = layout_type_res.instantiate()
	var type_str: String =  str(Globals.ElementType.keys()[type]).right(-5).to_lower()
	type_str[0] = type_str[0].to_upper()
	ret.type_name = type_str
	ret.type = type
	ret.config = config
	ret.update_current_focus.connect(_on_current_object_list_focused)
	return ret


## Re-generates the current layout from the layout stored by the metadata.
## Used whenever the layout file is updated from its previous state.
func regenerate_layout_list_from_metadata() -> void:
	var contents: Array[Dictionary] = LayoutMetadata.layout_contents
	for d: Dictionary in contents:
		# Trim "L" suffix from string
		var node: LLayoutSettingsType = new_llayout_settings_type(d["type"], d["config"])
		layout_list.add_child(node)


## Updates the cache when an element is moved up or down the tree. Used for when
## the user wants to reorder the nodes in their tree, and said tree needs to be
## redrawn.
func update_cache_order_from_move(moved_up: bool, old_index: int) -> void:
	if (old_index >= cached_contents.size()) or (old_index < 0): 
		return
	
	var copy: Dictionary = cached_contents[old_index]
	cached_contents.remove_at(old_index)
	# Yes this looks to be the best possible method of doing this. Please feel
	# free to prove me wrong.
	if moved_up:
		if old_index - 1 < 0:
			cached_contents.push_front(copy)
		else:
			cached_contents.insert(old_index - 1, copy)
	else:
		if old_index + 1 >= cached_contents.size():
			cached_contents.push_back(copy)
		else:
			cached_contents.insert(old_index + 1, copy)
	LayoutMetadata.update_layout_contents(cached_contents)


## Obtains the index in the layout for the selected `Control` node. Used for the
## layout cache and for updating child order when needed.
func get_layout_idx(object: Control) -> int:
	if object not in layout_list.get_children():
		push_error("Object " + object.name + " not found in child list.")
	
	var idx: int = layout_list.get_children().find(object)
	return idx


## Moves an object up one index in the list.
func move_object_up(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# If the object is at the top of the list, then keep it there
	if idx > 0:
		layout_list.move_child(object, idx - 1)
		update_cache_order_from_move(true, idx)


## Moves an object down one in the list.
func move_object_down(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# Likewise, if the control is at the end of the list then don't move it downwards
	if idx < layout_list.get_children().size():
		layout_list.move_child(object, get_layout_idx(object) + 1)
		update_cache_order_from_move(false, idx)


func _ready() -> void:
	## Should have a layout list from the globals by now
	regenerate_layout_list_from_metadata()
	cached_contents = LayoutMetadata.layout_contents

	element_list_popup = PopupMenu.new()
	# Add all types
	for i in range(Globals.ElementType.TYPE_MAX):
		var n: String = Globals.ElementType.keys()[i]
		n = n.right(-5).to_lower()
		n[0] = n[0].to_upper()
		element_list_popup.add_item(n)
	add_child(element_list_popup)
	element_list_popup.index_pressed.connect(_on_element_selected)

	$"left_context_menu/option_list/move_up".pressed.connect(_on_move_up_pressed)
	$"left_context_menu/option_list/move_down".pressed.connect(_on_move_down_pressed)
	$"left_context_menu/option_list/remove_element".pressed.connect(_on_remove_element_pressed)
	$"left_context_menu/option_list/add_element".pressed.connect(_on_add_element_pressed)


func _on_move_up_pressed() -> void:
	move_object_up(current_focus)


func _on_move_down_pressed() -> void:
	move_object_down(current_focus)


func _on_remove_element_pressed() -> void:
	pass


func _on_add_element_pressed() -> void:
	element_list_popup.position = Globals.get_global_cursor_position()
	element_list_popup.popup()


func _on_element_selected(idx: int) -> void:
	# Convert from string to enum
	var n: String = element_list_popup.get_item_text(idx).to_upper()
	n = "TYPE_" + n
	var type_enum: Globals.ElementType = Globals.ElementType.get(n)
	# Create a new node for the type (TODO: Make static and get via global)
	var tmp: LType = Globals.create_new_ltype(type_enum)
	var d: Dictionary
	d["config"] = tmp.get_default_config()
	d["type"] = type_enum
	# Append data and update cache (new elements are inserted after the current
	# focus or at the end if none is selected)
	var lidx: int = get_layout_idx(current_focus) if current_focus != null else -1
	var node: LLayoutSettingsType = new_llayout_settings_type(type_enum, tmp.get_default_config())
	layout_list.add_child(node)
	if lidx != -1 and lidx < cached_contents.size():
		cached_contents.insert(lidx + 1, d)
		layout_list.move_child(node, lidx + 1)
	else:
		cached_contents.push_back(d)
	LayoutMetadata.update_layout_contents(cached_contents)


func _on_current_object_list_focused(obj: Control) -> void:
	current_focus = obj
	for n: LLayoutSettingsType in layout_list.get_children():
		if n == null:
			continue
		
		n.focus_updated(obj)