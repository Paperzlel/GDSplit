class_name LTimer
extends LType

## The displayed time
@onready var time_label: Label = $time
## The default colour for the timer when it is
## unpaused and not counting up.
var _default_color: Color = Color.WHITE

func set_timer_colour(colour: Color) -> void:
	time_label.modulate = colour

func _on_time_updated(time_ms: int) -> void:
	var time_s: int = time_ms / 1000
	time_ms %= 1000
	time_label.text = str(time_s) + (".%02d" % (time_ms / 10))

func _on_time_began() -> void:
	set_timer_colour(Color.SEA_GREEN)
	pass

func _on_time_paused() -> void:
	set_timer_colour(Color.DARK_GRAY)
	pass

func _on_time_finished() -> void:
	set_timer_colour(Color.SKY_BLUE)
	pass

func _on_time_reset() -> void:
	set_timer_colour(_default_color)
	_on_time_updated(0)

func save_config() -> Dictionary:
	return { "color": _default_color }

func apply_config(cfg: Dictionary) -> bool:
	if cfg.get("color") == null:
		printerr("Failed to get color from dictionary.")
		return false
	
	_default_color = cfg["color"]
	return true


func get_default_config() -> Dictionary:
	return { "color": Color.WHITE }
