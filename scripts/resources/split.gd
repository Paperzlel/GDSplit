class_name LSplit
extends Resource

# name: string
# times: dict[string, int] (id is an int, time in ms)
# best_time: string	(points to id in times)

signal name_updated
signal times_updated
signal best_time_updated

signal removed(obj: LSplit)

var _dict: Dictionary[String, Variant]

var split_name: String:
	get:
		return _dict["name"]
	set(value):
		_dict["name"] = value
		name_updated.emit()

var times: Dictionary[String, int]:
	get:
		return _dict["times"]
	set(value):
		_dict["times"] = value
		times_updated.emit()

var best_time: int:
	get:
		return _dict["best_time"]
	set(value):
		_dict["best_time"] = value
		best_time_updated.emit()
