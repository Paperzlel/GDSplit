class_name LContentsPanel
extends VBoxContainer


func _ready() -> void:
	child_entered_tree.connect(_on_content_added)
	await get_tree().root.ready
	resized.emit()


## Called whenever a new node is added to the main contents, often whenever
## the split layout is being redesigned.
func _on_content_added(child : Node) -> void:
	if child is not Control:
		push_error("Non-Control node added to contents.")
		return
	
	position.y = 0


## Saves the layout and sends the data over to the SplitMetadata singleton to
## be properly parsed.
func save_layout() -> void:
	var dict: Dictionary
	var arr: Array[Dictionary]
	for n: Node in get_children():
		if n is not LType:
			printerr("Node is of invalid type, is class " + n.get_class())
		else:
			var t: LType = n
			arr.append(t.save_config())
	
	dict["contents"] = arr
	SplitMetadata.save_layout_metadata(dict)