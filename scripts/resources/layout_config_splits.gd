class_name LLayoutConfigSplits
extends LLayoutConfig


func _init() -> void:
    _dict = LSplits.get_default_config()
    _type = Globals.ElementType.TYPE_SPLITS