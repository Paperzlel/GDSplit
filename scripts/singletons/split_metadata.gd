extends Node

## Config file contains:
## - Version ID
## - Last used file
## - Last used theme

## Array of split names, stored here for reasons
var splits: Array[String] = []
## Array of split metadata, accessed by finding the ID for the split
## from the split array.
var _splits_metadata: Array[Dictionary] = []


## Parses the split file metadata, and updates if needed.
func parse_split_file_metadata(file: Dictionary) -> bool:
	Globals.check_and_update_if_needed(file)
	
	_splits_metadata = file["splits"]

	for d: Dictionary in _splits_metadata:
		var split_name: String = String(d.get("name"))
		if split_name.is_empty():
			split_name = ""
		splits.push_back(split_name)

	return true

