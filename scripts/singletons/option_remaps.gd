@tool
extends Node


static var option_dict: Dictionary[String, String] = {
    # Timer options
    "idle_color": "Default Color",
    "playing_color": "Playing Color",
    "paused_color": "Paused Color",
    "finished_color": "Finished Color",

    # Split options
    "visible_splits": "Visible Split Count",
    "splits_until_move": "Split Until Scrolling",
    "show_icons": "Show Split Icons",
    "show_column_titles": "Show Column Titles",
    "last_split_always_at_bottom": "Final Split Always At Bottom",
    "columns": "Columns",
    # (we don't have a way to modify columns just yet)
}