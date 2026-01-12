class_name LRootWindow
extends Window

@onready var window_script: GDScript = preload("res://scripts/window_handler.gd")
@onready var contents: LContentsPanel = $contents

var has_exited_focus: bool = false
var cursor_position: Vector2i
var option_subwindow: Window

## Splitting

## Different states the timer can be in.
enum TimerState
{
	## The timer is ready to run once the split key had been pressed.
	STATE_READY,
	## The timer is currently running.
	STATE_RUNNING,
	## The timer has paused and is awaiting another press to resume.
	STATE_PAUSED,
	## The timer has concluded running and can now be reset.
	STATE_FINISHED,
}


var _internal_time_state: TimerState
## The state of the global timer.
var time_state: TimerState = TimerState.STATE_READY:
	get:
		return _internal_time_state
	set(value):
		_internal_time_state = value


# TODO: Remove?
## Whether a splits file has been loaded or not
var has_splits: bool = false
## The number of splits loaded
var split_counter: int = 0

## The number of milliseconds elapsed overall. Reset every time
## it ticks over 1000.
var ms_elapsed: int = 0
## The number of seconds elapsed. Reset every time it ticks over
## 60.
var s_elapsed: int = 0


## Event to run whenever the split key has been pressed. In the case
## of external events, each method is separated out aside from
## `timer_began`.
func split_event() -> void:
	# Much cleaner, I like
	match time_state:
		TimerState.STATE_READY:
			begin_splits()
		TimerState.STATE_RUNNING:
			if !has_splits:
				finish_splits()
			else:
				increment_splits()
		TimerState.STATE_PAUSED:
			resume_splits()
		TimerState.STATE_FINISHED:
			reset_splits()


## Event that runs whenever the pause key is pressed. Pausing
## twice resumes, and likewise splitting resumes as well.
## Pausing can only be done when the splits are running, so
## the state needs to be one or the other, not ready or finished.
func pause_event() -> void:
	if time_state == TimerState.STATE_PAUSED:
		resume_splits()
	elif time_state == TimerState.STATE_RUNNING:
		pause_splits()


## Event that runs whenever the splits have been started.
## Functionally, this is the same as `resume_splits()` bar the
## signal but these are likely to vary much more with future
## additions.
func begin_splits() -> void:
	Globals.timer_began.emit()
	get_tree().call_group("real_timers", "_on_time_began")
	time_state = TimerState.STATE_RUNNING


## Event to run whenever the final split is reached and the timer has
## finished running.
func finish_splits() -> void:
	Globals.timer_finished.emit()
	get_tree().call_group("real_timers", "_on_time_finished")
	time_state = TimerState.STATE_FINISHED


## Event to run whenever the split count is incremented.
func increment_splits() -> void:
	split_counter += 1
	Globals.split_incremented.emit(split_counter)


## Event to run whenever the splits have been paused
func pause_splits() -> void:
	Globals.timer_paused.emit()
	get_tree().call_group("real_timers", "_on_time_paused")
	time_state = TimerState.STATE_PAUSED


## Event to run whenever the splits have been resumed from their paused
## state.
func resume_splits() -> void:
	Globals.timer_resumed.emit()
	# Reuse event where applicable, does the same thing I think
	get_tree().call_group("real_timers", "_on_time_began")
	time_state = TimerState.STATE_RUNNING


## Event to run whenever the splits need to be reset back to their initial
## state.
func reset_splits() -> void:
	Globals.timer_reset.emit()
	get_tree().call_group("real_timers", "_on_time_reset")
	time_state = TimerState.STATE_READY
	s_elapsed = 0
	ms_elapsed = 0
	split_counter = 0


## Window management


## Displays the given subwindow. Subwindows are expected to
## appear at the user's cursor, although this is exclusive to
## the menu window for the moment.
func show_subwindow(window: Window) -> void:
	window.position = get_cursor_screen_position()
	window.show()


## Creates a new subwindow that is a direct child of the current
## root window.
func create_subwindow(win_name: String, hint: LWindowHandler.SubWindowHint) -> Window:
	var subwindow: LWindowHandler = LWindowHandler.new(hint)
	subwindow.name = win_name
	subwindow.set_script(window_script)
	add_child.call_deferred(subwindow)
	return subwindow


## Gets the position of the cursor on the current screen.
func get_cursor_screen_position() -> Vector2i:
	return cursor_position + position


## Global virtual functions


func _ready() -> void:
	# Apply signals
	window_input.connect(_on_window_input)
	focus_entered.connect(_on_window_focus_entered)
	focus_exited.connect(_on_window_focus_exited)
	contents.resized.connect(_on_contents_resized)

	# Create subwindows and keep them hidden for now
	option_subwindow = create_subwindow("options_subwindow", LWindowHandler.SubWindowHint.HINT_OPTION_MENU)



func _process(delta: float) -> void:
	# Run real-time pausable timers
	if time_state == TimerState.STATE_RUNNING:
		## Update elapsed time
		ms_elapsed += int(delta * 1000)
		if ms_elapsed >= 1000:
			s_elapsed += int(ms_elapsed / 1000)
			ms_elapsed = ms_elapsed - 1000

		get_tree().call_group("real_timers", "_on_time_updated", ms_elapsed, s_elapsed)


func _on_window_input(event: InputEvent) -> void:
	# Check mouse clicks
	if event is InputEventMouseButton:
		if event.is_action_pressed("window_select"):
			start_drag()
		elif event.is_action_pressed("window_open_options"):
			show_subwindow(option_subwindow)
	
	# Check keyboard input
	elif event is InputEventKey:
		if event.is_action_pressed("split"):
			split_event()
		elif event.is_action_pressed("pause"):
			pause_event()
		elif event.is_action_pressed("reset"):
			reset_splits()
	
	# Check mouse movements
	elif event is InputEventMouseMotion:
		cursor_position = event.position


func _on_window_focus_entered() -> void:
	if has_exited_focus:
		# Hide popup window
		option_subwindow.hide()
		pass


func _on_window_focus_exited() -> void:
	has_exited_focus = true


## Update our own size to equal that of the contents.
func _on_contents_resized() -> void:
	size = contents.size
