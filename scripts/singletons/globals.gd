extends Node

## Signal for when the timer has began running
signal timer_began
## Signal for when the timer has been paused
signal timer_paused
## Signal for when the timer has resumed from pausing
signal timer_resumed
## Signal for when the timer has finished running
signal timer_finished
## Signal for when the timer needs to reset
signal timer_reset
## Signal for when the split ID is incremented
signal split_incremented(counter: int)

## Handle to the root window class
@onready var window: Window = $/root
## Script that is attached to the root window on startup
@onready var main_window_script = preload("res://scripts/main_window.gd")

## Global enumerations

## The type of comparison being ran. The default comparison option
## refers to the type pointed to in this class, which is set via
## the `default_comparison` setting or by cycling hotkeys.
enum Comparison
{
	## The currently running global comparison
	CURRENT_COMPARISON,
	## The current "PB" run, i.e. the fastest time a run has been completed
	PERSONAL_BEST,
	## The best time achieved for the given segment overall
	BEST_TIME,
	## The sum of all times achieved divided by the number of attempts that
	## reached this segment
	AVERAGE_TIME,
	## The worst time achieved on this segment
	WORST_TIME,
}

## The kind of calculation that is ran whenever updating a value that obeys
## these types.
enum ColumnType
{
	## The difference between the overall running time and the segment's time.
	## Multiple segments will accumulate on this value.
	DELTA,
	## The time taken overall to reach the given segment.
	SPLIT_TIME,
	## Before completion, shows the cumulative delta. Once completed, it shows 
	## the split time.
	DELTA_SPLIT_TIME,
	## The difference between the time taken for the segment and the given
	## comparison. Non-cumulative.
	SEGMENT_DELTA,
	## The time taken to complete the individual segment.
	SEGMENT_TIME,
	## Before completion, shows the segment delta. Once completed, shows the
	## split delta.
	SEGMENT_DELTA_SEGMENT_TIME,
}


func _ready() -> void:
	$"/root".set_script(main_window_script)
