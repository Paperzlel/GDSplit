extends HBoxContainer

## The node where all our layout items will exist.
@onready var layout_list: VBoxContainer = $right_bg/bg_margin/inner_menu/menu_margin/menu_list
## The resource corresponding to the layout setting "type" scene that is displayed
## whenever an element is added or removed
@onready var layout_type_res: PackedScene = preload("res://types/subtypes/ltype_layout_settings.tscn")

var element_list_popup: PopupMenu

## The node that is currently "in focus". This refers to the element that will
## be updated whenever an action in the left-hand bar is selected.
var current_focus: Control = null

## The cached contents of the layout, saved for future reference. We update
## this first before sending the new version to the metadata holder and forcing
## an update on everybody else that uses it.
var cached_contents: Array[Dictionary]

#region Order Functions


## Updates the element order when an element is moved up or down the tree. Called
## whenever a node is moved up or down in the tree, usually in 1-step increments.
func update_order_from_move(moved_up: bool, old_index: int) -> void:
	if (old_index >= cached_contents.size()) or (old_index < 0): 
		return
	
	LayoutMetadata.move_config_data_to(old_index, old_index - 1 if moved_up else old_index + 1)


## Moves an object up one index in the list.
func move_object_up(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# If the object is at the top of the list, then keep it there
	if idx > 0:
		layout_list.move_child(object, idx - 1)
		update_order_from_move(true, idx)


## Moves an object down one in the list.
func move_object_down(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# Likewise, if the control is at the end of the list then don't move it downwards
	if idx < cached_contents.size():
		layout_list.move_child(object, get_layout_idx(object) + 1)
		update_order_from_move(false, idx)

#endregion
#region Virtual Function


func _ready() -> void:
	# Should have a layout list from the globals by now, create the initial
	# layout list. 
	for d: Dictionary in LayoutMetadata.layout_contents:
		var node: LTypeLayoutSettings = new_ltype_layout_settings(d["type"], d["config"])
		layout_list.add_child(node)
	# We only need to reference it once. Both options get updated whenever
	# a write occurs. It's the joys of Dictionaries!
	cached_contents = LayoutMetadata.layout_contents

	element_list_popup = PopupMenu.new()
	# Add all types
	for i in range(Globals.ElementType.TYPE_MAX):
		var n: String = Globals.ElementType.keys()[i]
		n = n.right(-5).to_lower()
		n[0] = n[0].to_upper()
		element_list_popup.add_item(n)
	add_child(element_list_popup)
	element_list_popup.index_pressed.connect(_on_new_layout_element_selected)

	$"left_context_menu/option_list/move_up".pressed.connect(_on_move_up_pressed)
	$"left_context_menu/option_list/move_down".pressed.connect(_on_move_down_pressed)
	$"left_context_menu/option_list/remove_element".pressed.connect(_on_remove_element_pressed)
	$"left_context_menu/option_list/add_element".pressed.connect(_on_add_element_pressed)


#endregion
#region Callables


func _on_move_up_pressed() -> void:
	move_object_up(current_focus)


func _on_move_down_pressed() -> void:
	move_object_down(current_focus)


func _on_remove_element_pressed() -> void:
	# Do nothing if null
	if current_focus == null:
		return
	# Obtain current focus' index, remove and free, call to remove `LType` as
	# well.
	var idx: int = layout_list.get_children().find(current_focus)
	layout_list.remove_child(current_focus)
	current_focus.queue_free()
	LayoutMetadata.remove_config_data_at(idx)


func _on_add_element_pressed() -> void:
	element_list_popup.position = DisplayServer.mouse_get_position()
	element_list_popup.popup()


func _on_new_layout_element_selected(idx: int) -> void:
	# Convert from string to enum
	var n: String = element_list_popup.get_item_text(idx).to_upper()
	n = "TYPE_" + n
	var type_enum: Globals.ElementType = Globals.ElementType.get(n)
	# Create a new temporary node for the type
	var tmp: LType = Globals.create_new_ltype(type_enum)
	var d: Dictionary
	d["config"] = tmp.get_default_config()
	d["type"] = type_enum
	tmp.queue_free()
	# Append data and update cache (new elements are inserted after the current
	# focus or at the end if none is selected)
	var lidx: int = get_layout_idx(current_focus) if current_focus != null else -1
	var node: LTypeLayoutSettings = new_ltype_layout_settings(type_enum, d["config"])
	layout_list.add_child(node)
	if lidx != -1 and lidx < cached_contents.size():
		layout_list.move_child(node, lidx + 1)
	LayoutMetadata.add_config_data_at(lidx, d)


func _on_current_object_list_focused(obj: Control) -> void:
	current_focus = obj
	for n: LTypeLayoutSettings in layout_list.get_children():
		if n == null:
			continue
		
		n.focus_updated(obj)


## Called whenever an element type has its corresponding settings configuration
## change. Since changing settings doesn't change node order, we can safely
## access the type directly and apply its settings from here. NOTE: Assumes
## child order for the layout list and contents are the same.
func _on_layout_setting_config_changed(obj: LTypeLayoutSettings) -> void:
	var idx: int = layout_list.get_children().find(obj)
	if idx == -1:
		push_error("Child object " + obj.type_name + " could not be found in parent.")
		return

	var lt: LType = LayoutMetadata.get_ltype_from_index(idx)

	if !lt.apply_config(obj.config):
		push_error("Could not apply config for node " + lt.name + " (type was from " + obj.type_name + ")")

#endregion
#region Utility functions

## Creates a new class of type `LTypeLayoutSettings` and sets the defaults we
## expect to be used. 
func new_ltype_layout_settings(type: Globals.ElementType, config: Dictionary) -> LTypeLayoutSettings:
	var ret: LTypeLayoutSettings = layout_type_res.instantiate()
	var type_str: String =  str(Globals.ElementType.keys()[type]).right(-5).to_lower()
	type_str[0] = type_str[0].to_upper()
	ret.type_name = type_str
	ret.type = type
	ret.config = config
	ret.update_current_focus.connect(_on_current_object_list_focused)
	ret.config_changed.connect(_on_layout_setting_config_changed)
	return ret


## Obtains the index in the layout for the selected `Control` node. Used for the
## layout cache and for updating child order when needed.
func get_layout_idx(object: Control) -> int:
	if object not in layout_list.get_children():
		push_error("Object " + object.name + " not found in child list.")
	
	var idx: int = layout_list.get_children().find(object)
	return idx


#endregion
