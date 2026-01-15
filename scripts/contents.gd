class_name LContentsPanel
extends VBoxContainer


## Clears all children from the list.
func clear_contents() -> void:
	for c: Node in get_children():
		remove_child(c)


func _ready() -> void:
	child_entered_tree.connect(_on_content_added)
	child_exiting_tree.connect(_on_content_removed)
	await get_tree().root.ready
	resized.emit()


## Called whenever a new node is added to the main contents, often whenever
## the split layout is being redesigned.
func _on_content_added(child : Node) -> void:
	if child is not Control:
		push_error("Non-Control node added to contents.")
		return
	
	position.y = 0


## Called whenever content is removed from the tree. Can be called multiple
## times per frame, so we may simply make this a method and call it when done
## rather than resizing the window multiple times per frame. (TODO:)
func _on_content_removed(child: Node) -> void:
	if child is not Control:
		push_error("Non-Control node added to contents.")
		return
	
	position.y = 0
	# manually set size because containers are losers like this
	var n_size: int = 0
	for n: Control in get_children():
		n_size += int(n.size.y)
		if n_size > 0:
			n_size += 4
	size.y = n_size
	resized.emit()
