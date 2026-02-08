extends Node

## Split metadata
## Version ID
## Game Name
## Category Name
## Additional options {
##  ...
## }
## Attempt count
## Attempts {
## 		"<id>": { "start", "end", "pause_time" }
## }
## Personal best run number
## Icon storage path
## Splits [
## {
## 	name
## 	times {
## 		"0": 232432,
## 	}
## }
## ]

signal split_added(idx: int)
signal split_removed(idx: int)
signal split_moved(old_idx: int, new_idx: int)
signal splits_cleared

var splits_cfgs: Array[LSplit] = []

var split_count: int:
	get:
		return splits_cfgs.size()

var splits: Array[Dictionary]:
	get:
		return _get_metadata_safe("splits")
	set(value):
		_split_metadata["splits"] = value

var game_name: String:
	get:
		return _get_metadata_safe("game")
	set(value):
		_split_metadata["game"] = value

var game_category: String:
	get:
		return _get_metadata_safe("category")
	set(value):
		_split_metadata["category"] = value

var _split_metadata: Dictionary[String, Variant]


var _default_split_metadata: Dictionary[String, Variant] = {
	"version": Globals.version_str,
	"type": "splits",
	"game": "",
	"category": "",
	"metadata": {},
	"attempt_count": 0,
	"attempts": {},
	"personal_best_id": "",
	"icon_dir": "",
	"splits": [],
}


var _default_split: Dictionary[String, Variant] = {
	"name": "",
	"best_time": -1,
	"times": {},
}


func _get_metadata_safe(key: String) -> Variant:
	if _split_metadata == null or _split_metadata.is_empty():
		return null
	
	if !_split_metadata.has(key):
		push_error("Attempted to access split metadata with key \"" + key + "\" but nothing was found.")
		return null
	
	return _split_metadata.get(key)

#region Moving Splits Around


func add_split() -> void:
	add_split_at(splits_cfgs.size() if splits_cfgs.size() > 0 else 0)


func add_split_at(idx: int) -> void:
	var split_dict: Dictionary[String, Variant] = _default_split.duplicate()
	if splits.size() > 0 and idx != -1 and idx < splits.size():
		splits.insert(idx, split_dict)
	else:
		splits.push_back(split_dict)

	var ls: LSplit = LSplit.new()
	ls.set_config(split_dict)
	if splits_cfgs.size() and idx != -1 and idx < splits_cfgs.size():
		splits_cfgs.insert(idx, ls)
	else:
		splits_cfgs.push_back(ls)

	split_added.emit(idx)


func add_split_with_dictionary(dict: Dictionary[String, Variant]) -> void:
	add_split()
	var ls: LSplit = splits_cfgs[splits_cfgs.size() - 1]
	ls.set_config(dict)
	ls.name_updated.emit()
	ls.times_updated.emit()
	ls.best_time_updated.emit()


func remove_split_at(idx: int) -> void:
	if idx <= -1:
		push_error("Split index was out of range.")
		return
	
	splits_cfgs.remove_at(idx)
	splits.remove_at(idx)
	print("Removing split " + str(idx))
	split_removed.emit(idx)


func move_split_to(old_idx: int, new_idx: int) -> void:
	if new_idx < 0 or new_idx >= splits_cfgs.size():
		return
	var data: Dictionary[String, Variant] = splits.pop_at(old_idx)
	var s: LSplit = splits_cfgs.pop_at(old_idx)
	if new_idx < splits.size():
		splits.insert(new_idx, data)
		splits_cfgs.insert(new_idx, s)
	else:
		splits.push_back(data)
		splits_cfgs.push_back(s)
	
	split_moved.emit(old_idx, new_idx)


func clear_all_splits() -> void:
	splits_cfgs.clear()
	splits.clear()
	splits_cleared.emit()
	add_split()


#endregion
#region Saving/loading splits


func load_default_splits() -> void:
	splits_cleared.emit()
	_split_metadata = _default_split_metadata.duplicate()
	_split_metadata["splits"] = Array(_split_metadata["splits"], TYPE_DICTIONARY, "", null)
	add_split()



## Parses the split file metadata, and updates if needed.
func load_splits_from_dictionary(dict: Dictionary) -> bool:
	Globals.check_and_update_if_needed(dict)

	if dict.has("type") and dict["type"] != "splits":
		OS.alert("Attempted to load an invalid splits file. Splits will not be loaded.")
		return false

	splits_cleared.emit()

	if !dict.has("splits"):
		push_error("File loaded has no splits section.")
		return false

	dict["splits"] = Array(dict["splits"], TYPE_DICTIONARY, "", null)
	# Dictionary is now safe to use, apply metadata
	_split_metadata = dict

	for d: Dictionary in dict["splits"]:
		d = Dictionary(d, TYPE_STRING, "", null, TYPE_NIL, "", null)
		add_split_with_dictionary(d)

	return true


func save_splits_to_path(_path: String) -> void:
	pass

#endregion
