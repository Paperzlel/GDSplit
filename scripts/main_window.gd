class_name LRootWindow
extends Window

## Preloaded script that is attached to child windows for management purposes
@onready var window_script: GDScript = preload("res://scripts/window_handler.gd")
## The contents part of the main window, where all operations are passed through
@onready var contents: LContentsPanel = $contents

## Whether the focus of the window has been exited since program start
var has_exited_focus: bool = false
## The position of the cursor on-screen at the last movement
var cursor_position: Vector2i
## Reference to the options subwindow
var option_subwindow: Window
## Reference to the layout settings subwindow
var layout_settings_subwindow: Window
## Reference to the element list subwindow
var element_list_window: LWindowHandler
## Reference to the split settings subwindow
var split_settings_subwindow: Window = null

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

## The number of ms since the timer was began. Wraps every 500
## million years, which is unlikely to happen in most runs.
var start_ms: int = 0

## The time at which pause was hit in milliseconds. Resets on every
## pause.
var pause_start_ms: int = 0

## The total amount of time the timer has been paused in milliseconds.
## Doesn't reset until the run is over.
var total_pause_ms: int = 0

## The number of milliseconds the timer has been paused in this specific
## series of being paused.
var pause_ms: int = 0

## The number of milliseconds that have elapsed in total. Will
## also wrap the same amount, so calculating times based off
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
	# Grab MS here, since it'll change every time we reset.
	start_ms = Time.get_ticks_msec()
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
	# Get pause time here
	pause_start_ms = Time.get_ticks_msec()
	time_state = TimerState.STATE_PAUSED


## Event to run whenever the splits have been resumed from their paused
## state.
func resume_splits() -> void:
	Globals.timer_resumed.emit()
	# Reuse event where applicable, does the same thing I think
	get_tree().call_group("real_timers", "_on_time_began")
	total_pause_ms += pause_ms
	time_state = TimerState.STATE_RUNNING


## Event to run whenever the splits need to be reset back to their initial
## state.
func reset_splits() -> void:
	Globals.timer_reset.emit()
	get_tree().call_group("real_timers", "_on_time_reset")
	time_state = TimerState.STATE_READY
	s_elapsed = 0
	ms_elapsed = 0
	total_pause_ms = 0
	split_counter = 0


## Window management


## Displays the given subwindow. Subwindows are expected to
## appear at the user's cursor, although this is exclusive to
## the menu window for the moment.
func show_subwindow(window: Window) -> void:
	if window.borderless:
		window.position = DisplayServer.mouse_get_position()
	window.show()


## Creates a new subwindow that is a direct child of the current
## root window.
func create_subwindow(win_name: String, hint: LWindowHandler.SubWindowHint) -> Window:
	var subwindow: LWindowHandler = LWindowHandler.new(hint)
	subwindow.name = win_name
	subwindow.set_script(window_script)
	# Connect subwindow request if it exists.
	if subwindow.has_signal("open_subwindow_requested"):
		subwindow.connect("open_subwindow_requested", _on_subwindow_open_requested)
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
	option_subwindow.borderless = true
	option_subwindow.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	layout_settings_subwindow = create_subwindow("layout_settings_subwindow", LWindowHandler.SubWindowHint.HINT_LAYOUT_MENU)
	split_settings_subwindow = create_subwindow("split_settings_subwindow", LWindowHandler.SubWindowHint.HINT_SPLIT_MENU)

	# Manually set once done, to prevent OS.alert() during startup from 
	await get_tree().root.ready
	always_on_top = true



func _process(_delta: float) -> void:
	# Run real-time pausable timers
	var current_time_ms: int = Time.get_ticks_msec()
	if time_state == TimerState.STATE_RUNNING:
		# During running, the elapsed ms follows this formula:
		ms_elapsed = current_time_ms - start_ms - total_pause_ms
		# We calculate everything in milliseconds because it's a simple enough
		# measurement with more than enough accuracy and plenty of time to run
		# out (500 million years). Nodes that use the elapsed time are expected
		# to calculate the time in H:M:S.MS themselves at the moment.

		get_tree().call_group("real_timers", "_on_time_updated", ms_elapsed)
	elif time_state == TimerState.STATE_PAUSED:
		pause_ms = current_time_ms - pause_start_ms


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


## Opens the subwindow specified by the name. `name` does not need to include the
## `subwindow` suffix, as it's appended here.
func _on_subwindow_open_requested(win_name: String) -> void:
	win_name += "_subwindow"
	match win_name:
		split_settings_subwindow.name:
			show_subwindow(split_settings_subwindow)
		layout_settings_subwindow.name:
			show_subwindow(layout_settings_subwindow)
		option_subwindow.name:
			show_subwindow(option_subwindow)
		_:
			pass
