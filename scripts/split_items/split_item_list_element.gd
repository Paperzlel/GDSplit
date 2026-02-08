class_name LSplitItemListElement
extends MarginContainer

signal update_current_focus(obj: LSplitItemListElement)

## Reference to the background color for the object. Is hidden by default.
@onready var bg: ColorRect = $"bg"
@onready var split_edit: LineEdit = $"HBoxContainer/split_name"
@onready var best_time: LineEdit = $"HBoxContainer/best_time"
@onready var seg_time: LineEdit = $"HBoxContainer/seg_time"

## Whether to display the full visibility or not.
var show_alpha: bool = false

var cfg: LSplit = null


## Called whenever the current focus of the list is updated. Clears selection
## highlight if the in object is currently selected and is a layout type (as
## other `Control`s like buttons and so forth can also be focused)
func focus_updated(obj: Control) -> void:
	if obj != self and (obj is LSplitItemListElement):
		show_alpha = false
		bg.color.a = 0


func toggle_alpha() -> void:
	show_alpha = !show_alpha
	bg.color.a = 255 if show_alpha else 0
	update_current_focus.emit(self if show_alpha else null)


#region Builtin Event Handlers


func _on_best_time_text_submitted(_new_text: String) -> void:
	OS.alert("GDSplit currently lacks the functionality for editing best split times. We apologise for the inconvenience.", "Sorry!")


func _on_seg_time_text_submitted(_new_text: String) -> void:
	OS.alert("GDSplit currently lacks the functionality for editing segment times. We apologise for the inconvenience.", "Sorry!")


func _on_split_name_text_submitted(new_text: String) -> void:
	cfg.split_name = new_text


func _on_set_icon_pressed() -> void:
	OS.alert("GDSplit currently lacks the functionality for icons. We apologise for the inconvenience.", "Sorry!")


#endregion
#region Virtual Functions


func _ready() -> void:
	bg.color.a = 0
	split_edit.text = cfg.split_name
	best_time.text = Globals.ms_to_time(cfg.best_time, 0)

# Input from child nodes needs to be handled as otherwise it's ignored

func _on_best_time_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		toggle_alpha()


func _on_seg_time_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		toggle_alpha()


func _on_split_name_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		toggle_alpha()


func _on_set_icon_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		toggle_alpha()

#endregions
