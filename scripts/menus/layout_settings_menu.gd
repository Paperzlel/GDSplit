extends HBoxContainer

## The node where all our layout items will exist.
@onready var layout_list: VBoxContainer = $right_bg/bg_margin/inner_menu/menu_margin/menu_list
@onready var layout_type_res: PackedScene = preload("res://types/subtypes/layout_settings_type.tscn")

var current_focus: Control = null

## Re-generates the currently used layout. When adding/removing nodes from this
## list, it first updates the split metadata order, then pulls from that list
## to re-add all of the items. For a long list, this may pose problems so watch
## closely for performance issues.
func regenerate_layout_list() -> void:
	var contents: Array[Dictionary] = LayoutMetadata.layout_contents
	for d: Dictionary in contents:
		# Trim "L" suffix from string
		var node: LLayoutSettingsType = layout_type_res.instantiate()
		var type: String = str(d["type"]).right(-1)
		layout_list.add_child(node)
		node.type_name = type
		node.update_current_focus.connect(_on_current_object_list_focused)
	

func get_layout_idx(object: Control) -> int:
	if object not in layout_list.get_children():
		push_error("Object " + object.name + " not found in child list.")
	
	var idx: int = layout_list.get_children().find(object)
	return idx


func move_object_up(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# If the object is at the top of the list, then keep it there
	if idx == 0:
		idx = 1
	layout_list.move_child(object, idx - 1)


func move_object_down(object : Control) -> void:
	if object == null:
		return
	var idx: int = get_layout_idx(object)
	# Likewise, if the control is at the end of the list then don't move it downwards
	if idx == layout_list.get_children().size():
		idx = layout_list.get_children().size() - 1
	layout_list.move_child(object, get_layout_idx(object) + 1)


func _ready() -> void:
	## Should have a layout list from the globals by now
	regenerate_layout_list()

	$"left_context_menu/option_list/move_up".pressed.connect(_on_move_up_pressed)
	$"left_context_menu/option_list/move_down".pressed.connect(_on_move_down_pressed)


func _on_move_up_pressed() -> void:
	move_object_up(current_focus)


func _on_move_down_pressed() -> void:
	move_object_down(current_focus)


func _on_current_object_list_focused(obj: Control) -> void:
	current_focus = obj
	if obj:
		print(obj.name)
