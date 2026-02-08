class_name LSplitsRightRow
extends Label

var cfg: LSplit = null
var row_comparison: Globals.ComparisonType = Globals.ComparisonType.CURRENT_COMPARISON
var row_delta: Globals.DeltaType = Globals.DeltaType.DELTA
var index: int = 0

func _init(config: LSplit, comp: Globals.ComparisonType, delta: Globals.DeltaType, idx: int) -> void:
	cfg = config
	row_comparison = comp
	row_delta = delta
	index = idx


func _ready() -> void:
	calculate_time()
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pass


func calculate_time() -> void:
	var time: int = -1
	match row_comparison:
		Globals.ComparisonType.CURRENT_COMPARISON:
			row_comparison = Globals.global_comparison
			calculate_time()
		Globals.ComparisonType.PERSONAL_BEST:
			var run_id: String = SplitMetadata.pb_id
			if cfg.times.has(run_id):
				time = cfg.times[run_id]
		Globals.ComparisonType.BEST_TIME:
			time = cfg.best_time
		Globals.ComparisonType.AVERAGE_TIME:
			var sum: int = 0
			for k: String in cfg.times:
				sum += cfg.times[k]
			time = sum / cfg.times.keys().size()
		Globals.ComparisonType.WORST_TIME:
			for k: String in cfg.times:
				if cfg.times[k] > time:
					time = cfg.times[k]
		_:
			push_error("Invalid row comparison.")
	
	# Time is invalid, so put nothing.
	if time == -1:
		text = "-"
		return
	
	# Check delta types
	match row_delta:
		Globals.DeltaType.DELTA:
			pass
		Globals.DeltaType.SPLIT_TIME:
			# TODO: Not accurate
			text = Globals.ms_to_time(time, 2)
		Globals.DeltaType.SEGMENT_DELTA:
			pass
		Globals.DeltaType.SEGMENT_TIME:
			text = Globals.ms_to_time(time, 2)
			pass
		Globals.DeltaType.SEGMENT_DELTA_SEGMENT_TIME:
			text = Globals.ms_to_time(time, 2)
		_:
			push_error("Invalid row delta type.")