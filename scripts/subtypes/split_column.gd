class_name LSplitColumn
extends VBoxContainer

## Current comparison in the given column
var comparison: Globals.Comparison = Globals.Comparison.CURRENT_COMPARISON
## Current delta type used by the column
var column_type: Globals.ColumnType = Globals.ColumnType.DELTA
## Show the top of the column
var show_title: bool = false

## The title label displayed
@onready var title_label: Label = $title


func setup_column(cfg: Dictionary, parent: LSplits) -> void:
	column_type = cfg["delta"]
	comparison = cfg["comparison"]
	# Set title only if it's not empty to avoid false positive
	if !(cfg["label"] as String).is_empty():
		title_label.name = cfg["label"]
	else:
		title_label.name = ""

	title_label.visible = parent.show_column_titles
