class_name LSplits
extends LType


## Number of splits visible at any one time.
@export var splits_visible: int = 5
## The number of splits between the current split
## and the total split count that can be shown before
## the menu is moved downwards.
@export var splits_until_move: int = 2

## The left column of the splits, where the names and
## icons are shown.
@onready var left_column: VBoxContainer = $left
## The right column of the splits, where columns are
## shown.
@onready var right_column: HBoxContainer =$right

## The resource for a right hand side column.
@onready var right_column_res: PackedScene = preload("res://types/subtypes/split_column.tscn")
## The resource for a left hand column split row.
@onready var split_row_res: PackedScene = preload("res://types/subtypes/split_left_row.tscn")

## Whether icons should be shown or not.
var icons_visible: bool = false


## Adds a split into the split row.
func add_split(split_name: String, icon: ImageTexture) -> void:
	var child: SplitsLeftRow = split_row_res.instantiate()
	child.split_name.text = split_name
	if icons_visible:
		child.set_icon(icon)
	
	left_column.add_child(child)
	# TODO: setup right columns


## Implementation of the `LType` class function.
func save_config() -> Dictionary:
	return { "splits_visible": splits_visible, "splits_until_move": splits_until_move }


## Implementation of the `LType` class function.
func apply_config(cfg: Dictionary) -> bool:
	if !cfg.get("splits_visible"):
		push_error("Failed to get the visible split count from 
			the dictionary")
		return false
	splits_visible = cfg["splits_visible"]

	if !cfg.get("splits_until_end"):
		push_error("Failed to get the number of splits until end
			from the dictionary")
		return false
	splits_until_move = cfg["splits_until_move"]
	
	return true


## Implementation of the `LType` class function.
static func get_default_config() -> Dictionary:
	return { "splits_visible": 5, "splits_until_end": 2 }


func _ready() -> void:
	Globals.split_incremented.connect(_on_splits_incremented)
	## TODO: setup
	pass


func _on_splits_incremented(_counter: int) -> void:
	# TODO: setup
	pass
