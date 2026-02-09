class_name LSplit
extends Resource

# name: string
# times: dict[string, int] (id is an int, time in ms)
# best_time: string	(points to id in times)

signal name_updated
signal times_updated
signal best_time_updated

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


func set_config(d: Dictionary[String, Variant]) -> void:
	_dict = d
	_dict["times"] = Dictionary(_dict["times"], TYPE_STRING, "", null, TYPE_INT, "", null)


func update() -> void:
	name_updated.emit()
	times_updated.emit()
	best_time_updated.emit()
