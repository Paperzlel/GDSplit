class_name LTimer
extends LType


# Type = TYPE_TIMER (0)
# Config =
# "default_color" (Color)
# "playing_color" (Color)
# "paused_color" (Color)
# "finished_color" (Color)


## The displayed time
@onready var time_label: Label = $time

## Color for the timer when it is idle
var _idle_color: Color = Color.WHITE

## Color for the timer when it is playing
var _playing_color: Color = Color.SEA_GREEN

## Color for the timer when it is paused
var _paused_color: Color = Color.DARK_GRAY

## Color for the timer when is has finished running
var _finished_color: Color = Color.SKY_BLUE

func set_timer_colour(colour: Color) -> void:
	if time_label != null:
		time_label.self_modulate = colour


func _on_time_updated(time_ms: int) -> void:
	var time_s: int = time_ms / 1000
	time_ms %= 1000
	time_label.text = str(time_s) + (".%02d" % (time_ms / 10))


func _on_time_began() -> void:
	set_timer_colour(_playing_color)
	pass


func _on_time_paused() -> void:
	set_timer_colour(_paused_color)
	pass


func _on_time_finished() -> void:
	set_timer_colour(_finished_color)
	pass


func _on_time_reset() -> void:
	set_timer_colour(_idle_color)
	_on_time_updated(0)


## Implementation of the `LType` class function.
func save_config() -> Dictionary:
	return {
		"idle_color": _idle_color,
		"playing_color": _playing_color,
		"paused_color": _paused_color,
		"finished_color": _finished_color
	}


## Implementation of the `LType` class function.
func apply_setting(setting: String, value: Variant) -> void:
	match setting:
		"idle_color":
			_idle_color = value
		"playing_color":
			_playing_color = value
		"paused_color":
			_paused_color = value
		"finished_color":
			_finished_color = value
		_:
			push_error("Setting %s not found in class LTimer." % setting)
	
	set_timer_colour(_idle_color)


## Implementation of the `LType` class function.
static func get_default_config() -> Dictionary[String, Variant]:
	return { 
		"idle_color": Color.WHITE,
		"playing_color": Color.SEA_GREEN,
		"paused_color": Color.DARK_GRAY,
		"finished_color": Color.SKY_BLUE
	}
