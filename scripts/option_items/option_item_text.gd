@tool
class_name LOptionItemText
extends LOptionItem


var _internal_text: String
@onready var _line: LineEdit = $"MarginContainer/LineEdit"

@export var text: String:
    get:
        return _internal_text
    set(value):
        _internal_text = value
        if _line != null:
            _line.text = value


func get_item_value() -> Variant:
    return _internal_text


func set_item_value(value: Variant) -> void:
    text = value


func _ready() -> void:
    update_values()
    super._ready()


## Called whenever text is submitted. Must press enter. Change if it's confusing
## for users.
func _on_text_submitted(new_text: String) -> void:
    text = new_text
    update_values()