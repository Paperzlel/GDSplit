@tool
## Class that contains a series of [Dictionaries] with the same data that can
## be moved around in a customizable manner.
##
## This class implements the ability for movable data within an [LType]. Unlike
## other option classes, this takes some pretty heavy assumptions. Firstly, all 
## data is the same size when added. No mixing of types is allowed, for the sake
## of parsing. Secondly, said data is **always** stored in a [Dictionary] (the
## class is essentially `Array<Dictionary>` under the hood). 
class_name LOptionItemArray
extends LOptionItem

## Enumeration of different types of data that could be stored by an array. Since we
## still need to load a custom sub-item when updating our own contents, it's better
## to add hints here to prevent overcomplications with inheritance. If we're required
## to make a cleaner system, then so be it.
enum ArrayHint {
	HINT_INVALID = -1,
	HINT_COLUMN,
}


var _internal_array: Array[Dictionary] = []

@onready var _child_array: VBoxContainer = $"all_contents/items"

@export var array_hint: ArrayHint = ArrayHint.HINT_INVALID
@export var array: Array[Dictionary]:
	get:
		return _internal_array
	set(value):
		if !check_modifications_against(value as Array[Dictionary]):
			push_error("Data passed to LOptionItemArray was invalid, item \"" + str(value) + \
			"\" could not be parsed.")
			return
		
		_internal_array = value
		rebuild_list()
		update_configuration_warnings()



func check_modifications_against(input: Array[Dictionary]) -> bool:
	if input == null:
		push_error("Input passed to LOptionItemArray is null.")
		return false

	# Allow assignment when no data is present.
	if _internal_array.size() == 0:
		return true

	if input.size() > 0 and input[0].size() != _internal_array[0].size():
		push_error("Input passed to LOptionItemArray has an invalid size compared to the current array.")
		return false

	return true


## Clears the current item list and rebuilds it entirely. This is done only
## when the entire list has been potentially re-written and therefore any data
## could be invalid and needs to be cleared.
func rebuild_list() -> void:
	# Clear out list first if there are children to clear
	if _child_array.get_child_count() > 0:
		var child: Node = _child_array.get_child(0)
		while child != null:
			_child_array.remove_child(child)
			child.queue_free()
			if _child_array.get_child_count() > 0:
				child = _child_array.get_child(0)
			else:
				child = null
	
	# Re-build from data
	for d: Dictionary in _internal_array:
		create_new_child(d)


func create_new_child(data: Dictionary) -> void:
	var new_options: LOptionItemDictionary
	match array_hint:
		ArrayHint.HINT_COLUMN:
			new_options = (load("uid://ylen5u2j8bdw") as PackedScene).instantiate()
		ArrayHint.HINT_INVALID:
			new_options = null

	if new_options == null:
		push_error("Could not load LOptionItemArray's data as the array hint was invalid.")
		return
	
	new_options.config = null
	new_options.setting_updated.connect(_on_sub_setting_value_updated)
	new_options.move_up_requested.connect(_on_child_move_up_requested)
	new_options.move_down_requested.connect(_on_child_move_down_requested)
	new_options.remove_requested.connect(_on_child_remove_requested)
	new_options.set_item_value(data)
	_child_array.add_child(new_options)


func get_item_value() -> Variant:
	return _internal_array


func set_item_value(value: Variant) -> void:
	# Forcibly type the array. Can make it lose typed-ness
	value = Array(value, TYPE_DICTIONARY, "", null)
	array = value


func get_option_name_override() -> Label:
	return $"all_contents/header/name"


func _on_sub_setting_value_updated(opt_setting: String, value: Variant, item: LOptionItem) -> void:
	var idx: int = _child_array.get_children().find(item)
	if idx == -1:
		push_error("Could not find child option item in array.")
		return
	
	var d: Dictionary = array[idx]
	if !d.has(opt_setting):
		push_error("Setting \"" + opt_setting + "\" not found in option item array.")
		return

	d[opt_setting] = value
	update_values()


func _move_child_around(child: LOptionItemDictionary, up: bool) -> void:
	# Move data from position N to position N - 1
	# if child count = 1, do nothing
	# if pos = 0, do nothing
	# else, get data reference, remove from array, insert at N - 1, move visual node as well, done.
	if _child_array.get_child_count() == 1:
		return

	if child not in _child_array.get_children():
		return # NOTE: Possibly an error, silent about it for now
	
	var pos: int = _child_array.get_children().find(child)
	if pos == 0:
		return

	var data: Dictionary = _internal_array.pop_at(pos)
	pos = pos - 1 if up else pos + 1
	_internal_array.insert(pos, data)
	_child_array.move_child(child, pos)


func _on_child_move_up_requested(child: LOptionItemDictionary) -> void:
	_move_child_around(child, true)


func _on_child_move_down_requested(child: LOptionItemDictionary) -> void:
	_move_child_around(child, false)


func _on_child_remove_requested(child: LOptionItemDictionary) -> void:
	if child not in _child_array.get_children(): return

	var pos: int = _child_array.get_children().find(child)
	_internal_array.remove_at(pos)
	_child_array.remove_child(child)
	# TODO: Notify column removal (they don't render right now)
	child.queue_free()
	update_values()


func _on_child_add_requested() -> void:
	var d: Dictionary
	match array_hint:
		ArrayHint.HINT_COLUMN:
			d = LSplitColumn._default_column
		ArrayHint.HINT_INVALID:
			d = {}
	
	if d.is_empty():
		return
	
	create_new_child(d)
	array.append(d)
	update_values()
