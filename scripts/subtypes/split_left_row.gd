class_name SplitsLeftRow
extends HBoxContainer

## The split icon location
@onready var split_icon: TextureRect = $icon
## The name of the split
@onready var split_name: Label = $name


## Sets the icon to a given image. If the icon is non-null,
## then the split is extended to account for it, otherwise
## is kept hidden.
func set_icon(image : Texture2D) -> void:
	split_icon.texture = image
	# Toggle visibility on/off depending on if the child node exists.
	if image != null:
		split_icon.show()
	else:
		split_icon.hide()