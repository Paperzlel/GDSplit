## The control point for a given `LType`'s layout settings. In other words,
## the class that governs how our layout settings are applied by the user
## onto the displayed tree.
class_name LTypeLayoutSettings
extends Control

## Update what node is currently "focused" i.e. which is highlighted.
signal update_current_focus(obj: Control)
## Notifies that the config for the node has changed and needs to be
## updated elsewhere.
signal config_changed(obj: LTypeLayoutSettings)

## Reference to the label that the node is rendered upon
@onready var _label: Label = $Label
## Reference to the "ColorRect" that shows what node is highlighted.
@onready var _rect: ColorRect = $ColorRect

## The type of the node. Used to find the corresponding type in the tree.
var type: Globals.ElementType = Globals.ElementType.TYPE_MAX
## The config dictionary used for the given node. References the data up
## in the `LayoutMetadata`, so re-writing the two isn't needed.
var config: Dictionary
## Whether to show the alpha channel, or in other words, whether to show the
## background of the element or not.
var show_alpha: bool = false
## The temporary type name that is set prior to `_ready()` whilst the element
## is still being set up.
var tmp_type_proxy: String

## The name of the type being used. Converted from the `ElementType` when
## created.
var type_name: String:
	set(value):
		if is_inside_tree():
			_label.text = value
		else:
			tmp_type_proxy = value


## Writes data to the config and notifies that it's changed. Intented so that
## corresponding `LTypes` can update their own values.
func write_to_config(key: String, value: Variant) -> void:
	config[key] = value
	config_changed.emit(self)


## Called whenever the current focus of the list is updated. Clears selection
## highlight if the in object is currently selected and is a layout type (as
## other `Control`s like buttons and so forth can also be focused)
func focus_updated(obj: Control) -> void:
	if obj != self and (obj is LTypeLayoutSettings):
		show_alpha = false
		_rect.color.a = 0


func _ready() -> void:
	_rect.color.a = 0
	if !tmp_type_proxy.is_empty():
		_label.text = tmp_type_proxy


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("window_select"):
		show_alpha = !show_alpha
		_rect.color.a = 255 if show_alpha else 0
		update_current_focus.emit(self if show_alpha else null)
