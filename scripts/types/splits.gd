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
# 	"delta": (ColumnType)
# 	"comparison": (Comparison)
# 	"label": (string)

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

static var _default_config: Dictionary = {
	"visible_splits": 5,
	"splits_until_move": 2,
	"show_icons": false,
	"show_column_titles": false,
	"last_split_always_at_bottom": false,
	# Remember to type the columns on initialization!
	"columns": [
		{
			"delta": Globals.ColumnType.DELTA,
			"comparison": Globals.Comparison.CURRENT_COMPARISON,
			"label": "+/-"
		}
	]
}

var _current_config: Dictionary


static var _default_column: Dictionary = {
	"delta": Globals.ColumnType.DELTA,
	"comparison": Globals.Comparison.CURRENT_COMPARISON,
	"label": "",
}

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


## Implementation of the `LType` class function.
func apply_config(cfg: Dictionary) -> bool:
	if cfg.get("visible_splits") == null || cfg.get("splits_until_move") == null || \
			cfg.get("show_icons") == null || cfg.get("last_split_always_at_bottom") == null || \
			cfg.get("columns") == null:
		push_error("Failed to get proper data from LSplit dictionary.")
		printerr("Invalid LSplits dictionary: " + JSON.stringify(cfg, "\t") + "\n")

	# Set variables
	splits_visible = cfg["visible_splits"]
	splits_until_move = cfg["splits_until_move"]
	icons_visible = cfg["show_icons"]
	show_column_titles = cfg["show_column_titles"]
	last_split_always_at_bottom = cfg["last_split_always_at_bottom"]

	# Type array if not typed yet
	if !cfg["columns"].is_typed():
		cfg["columns"] = Array(cfg["columns"], TYPE_DICTIONARY, "", null)
	# Setup columns (TODO: Sanity-check typing)
	column_data = cfg["columns"]
	# Clear data first (TODO: Could use column count instead)
	reset_columns.call_deferred()
	for d: Dictionary in column_data:
		# TODO: Should return a value of sorts, for tracking it.
		# Call function as deferred since it needs to wait until this function's
		# ready to work properly.
		create_column.call_deferred(d)

	# Apply variables
	var tmp: Label = Label.new()
	var h: int = tmp.get_theme_font("font").get_height() as int
	tmp.free()

	# Force-set custom min size to label size.
	custom_minimum_size.y = h
	for i in range(splits_visible):
		# TODO: separation height
		custom_minimum_size.y += h + 4
	

	# Copy reference, so we can change the data more easily.
	_current_config = cfg
	return true


## Implementation of the `LType` class function.
static func get_default_config() -> Dictionary:
	return _default_config


#endregion
#region Virtual Functions


func _ready() -> void:
	Globals.split_incremented.connect(_on_splits_incremented)
	## TODO: setup
	print(_default_config)
	pass


func _on_splits_incremented(_counter: int) -> void:
	# TODO: setup
	pass

#endregion
