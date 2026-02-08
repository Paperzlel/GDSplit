class_name LSplits
extends LType


# Type = TYPE_SPLITS (1)
# Config =
# "visible_splits" (int)
# "splits_until_move" (int)
# "show_icons" (bool)
# "show_title" (bool)
# "last_split_always_at_bottom" (bool)
# "columns": (Array of Dictionaries)
# 	"column_delta": (ColumnType)
# 	"column_comparison": (Comparison)
# 	"column_label": (string)

## Number of splits visible at any one time.
var splits_visible: int = 5

## The number of splits between the current split and the total split count that
## can be shown before the menu is moved downwards.
var splits_until_move: int = 2

## Whether icons should be shown or not.
var icons_visible: bool = false

## Whether to show the titles of the columns or not.
var show_column_titles: bool = false

## Whether the final split in the file stays at the bottom of the layout or not.
## This is counted as a split in the layout and will affect the splits shown.
var last_split_always_at_bottom: bool = false

## Array of column data. Each column refers to the data in this array, which
## points to that in the layout metadata.
var column_data: Array[Dictionary] = []

## The left column of the splits, where the names and icons are shown.
@onready var left_column: VBoxContainer = $left_margin/left
## The bottom-left row of the splits, where final splits are shown.
@onready var lb_column: VBoxContainer = $left_margin/bottom
## The right column of the splits, where the different columns are shown.
@onready var right_column: HBoxContainer = $right_margin/right
## The bottom-right row of the splits, where the last times are shown.
@onready var rb_column: HBoxContainer = $right_margin/bottom

## The resource for a right hand side column.
@onready var right_column_res: PackedScene = preload("res://scenes/types/subtypes/split_column.tscn")
## The resource for a left hand column split row.
@onready var split_row_res: PackedScene = preload("res://scenes/types/subtypes/split_left_row.tscn")

## Internal spacer node. Used to align splits with the column headers properly.
var spacer: Control = null

## Default layout config for `LSplits`.
static var _default_config: Dictionary[String, Variant] = {
	"visible_splits": 5,
	"splits_until_move": 2,
	"show_icons": false,
	"show_column_titles": false,
	"last_split_always_at_bottom": false,
	# Remember to type the columns on initialization!
	"columns": [
		{
			# NOTE: This is essentially traits/structs. Use those when they come out.
			"column_delta": Globals.DeltaType.DELTA,
			"column_comparison": Globals.ComparisonType.CURRENT_COMPARISON,
			"column_label": "+/-"
		}
	]
}

## The current layout configuration being used by the splits.
var _current_config: Dictionary

## The counter for which split is currently being ran. Used to calculate how
## splits are shown to the user.
var split_counter: int = 0

#region Splits & Columns


## Converts absolute split ID positions to relative split positions in a valid
## range for accessing children. Returns `-1` if out of range, or in the range
## `[0, splits_visible]` otherwise.
func _abs_to_relative(idx: int) -> int:
	var high: int = (split_counter + splits_until_move)
	var low: int = (split_counter + splits_until_move + 1) - splits_visible
	# Out of range, ignore
	if idx < low or idx > high:
		return -1
	# Convert to (0, splits_visible) by subtracting the low value
	return idx - low


## Adds a split into the row "unsafely". This assumes the index is in absolute
## split IDs (0 to last_split) and thus can append it into local space.
func _add_split_unsafe(idx: int) -> void:
	var cfg: LSplit = SplitMetadata.splits_cfgs[idx if idx != SplitMetadata.last_split else idx - 1]
	var c: SplitsLeftRow = split_row_res.instantiate()
	c.cfg = cfg
	# In the case of the last split being added, append it to the last position.
	# We do not get rid of the current node if it exists because we are doing it
	# unsafely. The node to remove SHOULD be index 0 in any case.
	if idx == SplitMetadata.last_split:
		lb_column.add_child(c)
	else:
		left_column.add_child(c)
		idx = _abs_to_relative(idx)
		# If not in the proper position (item at index 1 is at index 3, for 
		# example) then move it to that position.
		if idx < left_column.get_child_count() and idx != -1:
			left_column.move_child(c, idx)
	# TODO: setup right columns


## Removes a split unsafely. Assumes the index is in absolute split IDs (0 to
## last_split) and converts it to local space on removal. Does not output
## errors on failure.
func _remove_split_unsafe(idx: int) -> void:
	var s: SplitsLeftRow = null
	if idx == SplitMetadata.last_split:
		s = lb_column.get_child(0)
		lb_column.remove_child(s)
	else:
		var rel: int = _abs_to_relative(idx)
		if rel != -1:
			s = left_column.get_child(rel)
			left_column.remove_child(s)
	
	if s != null:
		s.queue_free()


## Adds a split into the split row if its index is able to be shown on-screen.
func add_split(idx: int) -> void:
	if idx + 1 > splits_visible and (!last_split_always_at_bottom or idx < SplitMetadata.last_split):
		return

	# Prior to adding the new node, remove the last node if it exists
	if left_column.get_child_count() == splits_visible:
		_remove_split_unsafe(splits_visible - 1)
	
	# Remove last node if needed.
	if idx == SplitMetadata.last_split:
		_remove_split_unsafe(SplitMetadata.last_split)

	# Add split unsafely.
	_add_split_unsafe(idx)

	# TODO: setup right columns


## Removes a split from the split row if it exists and is being shown on-screen.
func remove_split(idx: int) -> void:
	# Post-removal, split count is the amount we have - 1
	# if the last split is not being rendered and we're more than v,
	# or if the last split is being rendered and we're between v and max,
	# then skip.
	if idx + 1 > splits_visible and (!last_split_always_at_bottom or idx < SplitMetadata.last_split):
		return
	
	# Remove split unsafely.
	_remove_split_unsafe(idx)
	# TODO: remove right column(s)

	# If there's a split to add now we've removed one, then add it now.
	if splits_visible <= SplitMetadata.last_split:
		if idx == SplitMetadata.last_split:
			_add_split_unsafe(SplitMetadata.last_split)
		else:
			_add_split_unsafe(splits_visible - 1)


## Moves a split from one position to another if it exists. If it is moved
## offscreen, then it is removed and hidden from the user.
func move_split(old_idx: int, new_idx: int) -> void:
	var rel_old: int = _abs_to_relative(old_idx)
	var rel_new: int = _abs_to_relative(new_idx)
	# if old and new are invalid, do nothing. if old is invalid but new isn't,
	# add a node (safely). if old is valid but new isn't, remove (safely).
	# if both are valid, just move it normally.
	# If either of the absolute indicies are at the max, add at the end.
	if new_idx == SplitMetadata.last_split - 1 or old_idx == SplitMetadata.last_split - 1:
		add_split(SplitMetadata.last_split)
	
	if rel_old == -1 and rel_new == -1:
		return
	
	var lobj: SplitsLeftRow = null
	if rel_new == -1:
		remove_split(rel_old)
	elif rel_old == -1:
		add_split(rel_new)
	else:
		lobj = left_column.get_child(rel_old)
		left_column.move_child(lobj, rel_new)
	# TODO: move right column(s)


## Removes all visible splits and subsequently frees them.
func clear_splits() -> void:
	var arr: Array[Node] = left_column.get_children()
	for c: Node in arr:
		c = c as SplitsLeftRow
		if c == null:
			continue
		
		left_column.remove_child(c)
		c.queue_free()
	# TODO: Clear right column(s)


## Called whenever the range of split values to show has been changed.
func _split_range_changed() -> void:
	# If there's no splits, don't bother doing anything.
	if SplitMetadata.last_split == 0:
		return
	
	# If the layout now allows bottom splits and there isn't one already, addd
	# one in.
	if last_split_always_at_bottom and lb_column.get_child_count() == 0:
		# Remove split in main row if it exists and the row is non-empty
		if splits_visible > SplitMetadata.last_split:
			_remove_split_unsafe(SplitMetadata.last_split - 1)
		_add_split_unsafe(SplitMetadata.last_split)
	elif !last_split_always_at_bottom and lb_column.get_child_count() > 0:
		# Otherwise, remove if there's something there
		_remove_split_unsafe(SplitMetadata.last_split)
		# Add split to main row it there isn't one yet.
		if splits_visible > SplitMetadata.last_split:
			_add_split_unsafe(SplitMetadata.last_split - 1)
	
	# If there's less than splits_visible splits here, do nothing since we're
	# working under the guise that there's more data yet to be read.
	if splits_visible > SplitMetadata.last_split:
		return

	var diff: int = splits_visible - left_column.get_child_count()
	# Add more nodes from where we left off.
	while diff > 0:
		_add_split_unsafe(left_column.get_child_count())
		diff -= 1
	
	# Remove nodes if none are found
	while diff < 0:
		_remove_split_unsafe(left_column.get_child_count() - 1)
		diff += 1
	# Done


func create_column(cfg: Dictionary) -> void:
	var ret: LSplitColumn = right_column_res.instantiate()
	right_column.add_child(ret)
	ret.setup_column(cfg, self)


func reset_columns() -> void:
	for c: Node in right_column.get_children():
		right_column.remove_child(c)
		c.queue_free()


## If the visibility of the columns changes, update all columns with the new
## visibility.
func update_column_visibility() -> void:
	for s: LSplitColumn in right_column.get_children():
		s.set_show_title(show_column_titles)


#endregion
#region Config


func update_container_size() -> void:
	var h: int = get_theme_font("font").get_height() as int
	var rn: int = splits_visible - (0 if last_split_always_at_bottom else 1) + (1 if show_column_titles else 0)
	var separation: int = theme.get_constant("separation", "") if theme != null else 4
	custom_minimum_size.y = h
	for i in range(rn):
		custom_minimum_size.y += h + separation
	
	split_counter = splits_visible - splits_until_move - 1
	# Sanity check in case of access occuring prior to entering the tree
	if is_inside_tree() and spacer != null:
		spacer.visible = show_column_titles
	else:
		var t: Callable = func(): spacer.visible = show_column_titles
		t.call_deferred()
	
	_split_range_changed.call_deferred()


## Implementation of the `LType` class function.
func save_config() -> Dictionary:
	return _current_config


func apply_setting(setting: String, value: Variant) -> void:
	match setting:
		"visible_splits":
			splits_visible = value
			update_container_size()
		"splits_until_move":
			splits_until_move = value
			update_container_size()
		"show_icons":
			icons_visible = value
		"show_column_titles":
			show_column_titles = value
			update_column_visibility.call_deferred()
			update_container_size()
		"last_split_always_at_bottom":
			last_split_always_at_bottom = value
			update_container_size()
		"columns":
			if !(value as Array[Dictionary]).is_typed():
				value = Array(value, TYPE_DICTIONARY, "", null)
			column_data = value
			reset_columns.call_deferred()
			for d: Dictionary in column_data:
				# Call function as deferred since it needs to wait until this function's
				# ready to work properly.
				create_column.call_deferred(d)
		_:
			push_error("Setting %s not found in class LSplits." % setting)


## Implementation of the `LType` class function.
static func get_default_config() -> Dictionary[String, Variant]:
	return _default_config.duplicate()
	

#endregion
#region Split Event Handlers


func _on_splits_incremented(_counter: int) -> void:
	# TODO: setup
	pass


#endregion
#region Virtual Functions


func _ready() -> void:
	spacer = Control.new()
	spacer.custom_minimum_size.y = get_theme_font("font").get_height() as int
	left_column.add_child(spacer, false, InternalMode.INTERNAL_MODE_FRONT)

	Globals.split_incremented.connect(_on_splits_incremented)
	SplitMetadata.split_added.connect(add_split)
	SplitMetadata.split_removed.connect(remove_split)
	SplitMetadata.split_moved.connect(move_split)
	SplitMetadata.splits_cleared.connect(clear_splits)
	super._ready()


#endregion
