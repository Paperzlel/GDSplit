class_name SplitsLeftRow
extends HBoxContainer

## The split icon location
@onready var split_icon: TextureRect = $icon
## The name of the split
@onready var split_name: Label = $name

## The config used by the split. We care exclusively about the name in this
## instance.
var cfg: LSplit = null

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


func _ready() -> void:
	cfg.name_updated.connect(_on_split_name_updated)
	if !cfg.split_name.is_empty():
		split_name.text = cfg.split_name


func _on_split_name_updated() -> void:
	split_name.text = cfg.split_name
