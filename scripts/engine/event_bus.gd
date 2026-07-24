extends Node

signal app_open_requested(app_id: String)
signal viewer_open_requested(file_entry: Dictionary)
signal note_pin_requested(label: String, image_path: String)
signal case_completed(case_id: String, grade: String)
signal save_requested
