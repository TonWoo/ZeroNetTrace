extends Node

const DEFAULT_PATH := "user://save.json"

func save_game(payload: Dictionary) -> bool:
	return write_to(DEFAULT_PATH, payload)

func load_game() -> Dictionary:
	return read_from(DEFAULT_PATH)

func write_to(path: String, payload: Dictionary) -> bool:
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t", false))
	file.flush()
	file.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup)
		DirAccess.copy_absolute(absolute_path, absolute_backup)
		DirAccess.remove_absolute(absolute_path)
	var result := DirAccess.rename_absolute(absolute_temp, absolute_path)
	return result == OK

func read_from(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	var backup_path := path + ".bak"
	if FileAccess.file_exists(backup_path):
		var backup = JSON.parse_string(FileAccess.get_file_as_string(backup_path))
		if backup is Dictionary:
			return backup
	return {}

func remove_at(path: String) -> void:
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
