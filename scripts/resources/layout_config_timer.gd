class_name LLayoutConfigTimer
extends LLayoutConfig


func _init() -> void:
	_dict = LTimer.get_default_config()
	_type = Globals.ElementType.TYPE_TIMER
