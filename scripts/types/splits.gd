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
@onready var left_column: VBoxContainer = $left
## The right column of the splits, where the differnet columns are shown.
@onready var right_column: HBoxContainer =$right

## The resource for a right hand side column.
@onready var right_column_res: PackedScene = preload("res://scenes/types/subtypes/split_column.tscn")
## The resource for a left hand column split row.
@onready var split_row_res: PackedScene = preload("res://scenes/types/subtypes/split_left_row.tscn")

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

var _current_config: Dictionary

#region Splits & Columns


## Adds a split into the split row.
func add_split(split_name: String, icon: ImageTexture) -> void:
	var child: SplitsLeftRow = split_row_res.instantiate()
	child.split_name.text = split_name
	if icons_visible:
		child.set_icon(icon)
	
	left_column.add_child(child)
	# TODO: setup right columns


func create_column(cfg: Dictionary) -> void:
	var ret: LSplitColumn = right_column_res.instantiate()
	right_column.add_child(ret)
	ret.setup_column(cfg, self)


func reset_columns() -> void:
	for c: Node in right_column.get_children():
		right_column.remove_child(c)
		c.queue_free()


#endregion
#region Config


## Implementation of the `LType` class function.
func save_config() -> Dictionary:
	return _current_config


func apply_setting(setting: String, value: Variant) -> void:
	match setting:
		"visible_splits":
			splits_visible = value
		"splits_until_move":
			splits_until_move = value
		"show_icons":
			icons_visible = value
		"show_column_titles":
			show_column_titles = value
		"last_split_always_at_bottom":
			last_split_always_at_bottom = value
		"columns":
			if !(value as Array[Dictionary]).is_typed():
				value = Array(value, TYPE_DICTIONARY, "", null)
			column_data = value
			reset_columns.call_deferred()
			for d: Dictionary in column_data:
				# TODO: Should return a value of sorts, for tracking it.
				# Call function as deferred since it needs to wait until this function's
				# ready to work properly.
				create_column.call_deferred(d)
		_:
			push_error("Setting %s not found in class LSplits." % setting)
	
	# Apply variables

	# Force-set custom min size to label size.
	var h: int = get_theme_font("font").get_height() as int
	custom_minimum_size.y = h
	for i in range(splits_visible):
		# TODO: separation height
		custom_minimum_size.y += h + 4


## Implementation of the `LType` class function.
static func get_default_config() -> Dictionary[String, Variant]:
	return _default_config.duplicate()
	

#endregion
#region Virtual Functions


func _ready() -> void:
	Globals.split_incremented.connect(_on_splits_incremented)
	super._ready()


func _on_splits_incremented(_counter: int) -> void:
	# TODO: setup
	pass

#endregion
