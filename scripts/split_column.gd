extends VBoxContainer

## Current comparison in the given column
@export var comparison: Globals.Comparison = Globals.Comparison.CURRENT_COMPARISON
## Current delta type used by the column
@export var column_type: Globals.ColumnType = Globals.ColumnType.DELTA
## Show the top of the column
@export var show_title: bool = false

## The title label displayed
@onready var title_label: Label = $title

func _ready() -> void:
	title_label.visible = show_title
