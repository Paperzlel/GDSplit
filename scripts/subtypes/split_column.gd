class_name LSplitColumn
extends VBoxContainer

## Current comparison in the given column
var comparison: Globals.ComparisonType = Globals.ComparisonType.CURRENT_COMPARISON
## Current delta type used by the column
var column_type: Globals.DeltaType = Globals.DeltaType.DELTA
## Show the top of the column
var show_title: bool = false

## The title label displayed
@onready var title_label: Label = $title


## The default column layout. Slightly different from the default splits
## in that it has no initial label.
static var _default_column: Dictionary = {
	"column_delta": Globals.DeltaType.DELTA,
	"column_comparison": Globals.ComparisonType.CURRENT_COMPARISON,
	"column_label": "",
}


func setup_column(cfg: Dictionary, parent: LSplits) -> void:
	column_type = cfg["column_delta"]
	comparison = cfg["column_comparison"]
	# Set title only if it's not empty to avoid false positive
	if !(cfg["column_label"] as String).is_empty():
		title_label.name = cfg["column_label"]
	else:
		title_label.name = ""

	title_label.visible = parent.show_column_titles
