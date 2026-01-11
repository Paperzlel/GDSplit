class_name LWindowHandler
extends Window

## The hint for what subwindow is being ran.
enum SubWindowHint {
    ## This is an invalid subwindow
    HINT_NONE,
    ## This is the split editing subwindow
    HINT_SPLIT_MENU,
    ## This is the options menu subwindow
    HINT_OPTIONS_MENU,
}

## The window hint for the given window.
@export var window_hint: SubWindowHint = SubWindowHint.HINT_NONE


func _init() -> void:
    transient = true
    borderless = true
    visible = false
    initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE


func _ready() -> void:
    var menu: Control
    # Hint as to what subwindow we are dealing with.
    # This should be replaced with the window hint ASAP.
    if get_parent() == get_tree().root:
        menu = (load("res://menus/option_menu.tscn") as PackedScene).instantiate()
        add_child(menu)
        if Vector2i(menu.size) != size:
            size = menu.size
    else:
        ## Check window hint
        match window_hint:
            _:
                pass
        pass