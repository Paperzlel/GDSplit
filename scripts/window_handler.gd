class_name LWindowHandler
extends Window

## The hint for what subwindow is being ran.
enum SubWindowHint {
    ## This is an invalid subwindow
    HINT_NONE,
    ## This is the split editing subwindow
    HINT_SPLIT_MENU,
    ## This is the options menu subwindow
    HINT_OPTION_MENU,
}

## The window hint for the given window.
@export var window_hint: SubWindowHint = SubWindowHint.HINT_NONE


func _init(hint: SubWindowHint) -> void:
    transient = true
    borderless = true
    visible = false
    initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
    window_hint = hint


func _ready() -> void:
    # All window handling is the same bar what content is loaded.
    # The content manages itself instead of the window
    var scene_path: String = ""
    match window_hint:
        SubWindowHint.HINT_SPLIT_MENU:
            scene_path = "res://menus/layout_settings_menu.tscn"
        SubWindowHint.HINT_OPTION_MENU:
            scene_path = "res://menus/option_menu.tscn"
        _:
            pass
    
    var menu: Control = (load(scene_path) as PackedScene).instantiate()
    add_child(menu)
    if Vector2i(menu.size) != size:
        size = menu.size