class_name LMenuTimerSettings
extends VBoxContainer


## Reference to the current setting that we're editing. Editing the info
## on this panel will update the 
var timer_ref: LTypeLayoutSettings


func _ready() -> void:
    if timer_ref == null:
        push_error("Reference to layout timer setting was null, this should be
        set prior to entering the scene tree.")
        return
    for c: LOptionItem in get_children():
        var child_setting: String = c.option_name.to_lower().replace(" ", "_")
        if timer_ref.config.get(child_setting) == null:
            push_error("Timer setting \"" + child_setting + "\" did not exist.")
        c.set_item_value(timer_ref.config[child_setting])
        c.value_updated.connect(_on_setting_updated)


func _on_setting_updated(setting: String, value: Variant) -> void:
    # Update the timer settings. 
    timer_ref.write_to_config(setting, value)
