extends RefCounted

const SERVICES := ["DataRepository", "CaseRuntime", "SaveService", "EventBus", "AudioDirector", "HorrorDirector"]

func run(t) -> void:
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	t.contains_text(project_text, "[autoload]", "project declares autoload services")
	for service in SERVICES:
		t.contains_text(project_text, "%s=" % service, "%s is registered as an autoload" % service)
