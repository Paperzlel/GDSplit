## Class that is implemented by all layout "types".
## Requires the implementation of a save and load for the
## layout configuration, as classes often have custom info.
@abstract
class_name LType
extends Control


@abstract 
func save_config() -> Dictionary

@abstract
func apply_config(cfg: Dictionary) -> bool