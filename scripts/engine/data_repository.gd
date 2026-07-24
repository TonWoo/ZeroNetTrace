extends Node

var last_error := ""
var case_index: Array = []

func load_json(path: String) -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "文件不存在：%s" % path
		return {}
	var json := JSON.new()
	var error := json.parse(FileAccess.get_file_as_string(path))
	if error != OK:
		last_error = "JSON 解析失败 %s:%d：%s" % [path, json.get_error_line(), json.get_error_message()]
		return {}
	if not json.data is Dictionary:
		last_error = "JSON 根节点必须是对象：%s" % path
		return {}
	return json.data

func load_index(path := "res://data/cases/index.json") -> Array:
	var data := load_json(path)
	case_index = data.get("cases", [])
	return case_index

func load_case(case_id: String) -> Dictionary:
	if case_index.is_empty():
		load_index()
	for entry_value in case_index:
		var entry: Dictionary = entry_value
		if String(entry.get("id", "")) == case_id:
			return load_json(String(entry.get("path", "")))
	last_error = "案件不存在：%s" % case_id
	return {}
