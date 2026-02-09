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


## Converts a relative, local index to an absolute one by taking the split
## counter index and moving it relative to the first split's index.
func _relative_to_abs(rel: int) -> int:
	var low: int = (split_counter + splits_until_move + 1) - splits_visible
	return low + rel


## Called when an update to the split list has occured and the tree must be
## redrawn. Clears all data and re-adds it back.
func _redraw_on_change() -> void:
	# clear everything
	# update depending on data

	# Clear left column
	while left_column.get_child_count() > 0:
		var s: LSplitsLeftRow = left_column.get_child(0)
		left_column.remove_child(s)
		s.queue_free()
	
	# Clear bottom row if it exists
	if lb_column.get_child_count() > 0:
		var s: LSplitsLeftRow = lb_column.get_child(0)
		lb_column.remove_child(s)
		s.queue_free()
	
	# Clear right columns
	for c: Node in right_column.get_children():
		c = c as LSplitColumn
		if c == null:
			continue
		
		while c.get_child_count() > 1:
			var r: LSplitsRightRow = c.get_child(1)
			c.remove_child(r)
			r.queue_free()
	
	for c: Node in rb_column.get_children():
		c = c as VBoxContainer
		if c == null:
			continue
		
		while c.get_child_count() > 0:
			var r: LSplitsRightRow = c.get_child(0)
			c.remove_child(r)
			r.queue_free()

	for i in range(min(splits_visible, SplitMetadata.split_count)):
		var s: LSplitsLeftRow = split_row_res.instantiate()
		var cfg: LSplit = SplitMetadata.splits_cfgs[_relative_to_abs(i)]
		s.cfg = cfg
		left_column.add_child(s)

		for c: Node in right_column.get_children():
			c = c as LSplitColumn
			if c == null:
				continue
			
			var r: LSplitsRightRow = LSplitsRightRow.new(cfg, c.comparison, c.column_type, i)
			c.add_child(r)
	
	# Move to bottom row if needed
	if last_split_always_at_bottom and SplitMetadata.split_count > 0:
		var l: LSplitsLeftRow = null
		if splits_visible >= SplitMetadata.split_count:
			l = left_column.get_child(SplitMetadata.split_count - 1)
			left_column.remove_child(l)
		else:
			l = split_row_res.instantiate()
			l.cfg = SplitMetadata.splits_cfgs[SplitMetadata.split_count - 1]
		lb_column.add_child(l)

		var idx: int = 0
		for c: Node in rb_column.get_children():
			c = c as VBoxContainer
			if c == null:
				continue
			
			var col: LSplitColumn = right_column.get_child(idx) as LSplitColumn
			var r: LSplitsRightRow = null
			if splits_visible >= SplitMetadata.split_count:
				r = col.get_child(SplitMetadata.split_count)
				col.remove_child(r)
			else:
				r = LSplitsRightRow.new(
					SplitMetadata.splits_cfgs[SplitMetadata.split_count - 1], 
					col.comparison, 
					col.column_type,
					SplitMetadata.split_count - 1
				)
			c.add_child(r)
			idx += 1


## Adds a split into the split row if its index is able to be shown on-screen.
func add_split(idx: int) -> void:
	if idx + 1 > splits_visible and (!last_split_always_at_bottom or idx < SplitMetadata.split_count):
		return
	
	_redraw_on_change()


## Removes a split from the split row if it exists and is being shown on-screen.
func remove_split(idx: int) -> void:
	# Post-removal, split count is the amount we have - 1
	# if the last split is not being rendered and we're more than v,
	# or if the last split is being rendered and we're between v and max,
	# then skip.
	if idx + 1 > splits_visible and (!last_split_always_at_bottom or idx < SplitMetadata.split_count):
		return
	
	_redraw_on_change()


## Moves a split from one position to another if it exists. If it is moved
## offscreen, then it is removed and hidden from the user.
func move_split(_old_idx: int, _new_idx: int) -> void:
	_redraw_on_change()


## Removes all visible splits and subsequently frees them.
func clear_splits() -> void:
	_redraw_on_change()


## Called whenever the range of split values to show has been changed.
func _split_range_changed() -> void:
	# If there's no splits, don't bother doing anything.
	if SplitMetadata.split_count == 0:
		return
	
	_redraw_on_change()


func create_column(cfg: Dictionary) -> void:
	var ret: LSplitColumn = right_column_res.instantiate()
	right_column.add_child(ret)
	ret.setup_column(cfg, self)
	var right: VBoxContainer = VBoxContainer.new()
	right.custom_minimum_size.x = 40
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	rb_column.add_child(right)

	_redraw_on_change()


func reset_columns() -> void:
	for c: Node in right_column.get_children():
		right_column.remove_child(c)
		c.queue_free()
	for c: Node in rb_column.get_children():
		rb_column.remove_child(c)
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


## Implementation of the `LType` class function.
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
