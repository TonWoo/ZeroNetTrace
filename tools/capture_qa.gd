extends SceneTree

const MAIN_SCENE := preload("res://scenes/os/main.tscn")
const OUTPUT_DIR := "res://artifacts/qa"

var main

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _settle()
	for size in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
		DisplayServer.window_set_size(size)
		await _settle()
		_capture("desktop_%dx%d.png" % [size.x, size.y])
	DisplayServer.window_set_size(Vector2i(1600, 900))
	await _settle()
	main._load_case_at(1, {})
	main._open_app("browser")
	main.apps["browser"].snap_right()
	main.apps["browser"]._search("N17 门禁")
	await _settle()
	_capture("site_campus.png")
	main.apps["browser"]._search("bbs.campus.zero/lanpu")
	await _settle()
	_capture("site_forum.png")
	main._load_case_at(2, {})
	main._open_app("browser")
	main.apps["browser"].snap_right()
	main.apps["browser"]._search("raven.zhibo-lan.cn")
	await _settle()
	_capture("site_raven.png")
	main.apps["browser"]._search("长明")
	await _settle()
	_capture("site_search.png")
	main.apps["browser"]._search("changming-mem.cn")
	await _settle()
	_capture("site_changming.png")
	main.runtime.login("changming-mem.cn", "CM-041", "202303changming")
	main.apps["browser"]._search("changming-mem.cn/tickets")
	await _settle()
	_capture("site_workorder.png")
	main._apply_theme("green")
	await _settle()
	_capture("theme_green.png")
	main._apply_theme("amber")
	await _settle()
	_capture("theme_amber.png")
	main._apply_theme("mono")
	var stream_file := _find_file(main.current_case_data, "ev_raven_video")
	main.apps["viewer"].open_file(stream_file)
	main.apps["viewer"].snap_right()
	main.apps["viewer"]._set_frame(39)
	await _settle()
	_capture("viewer_frame39.png")
	main._load_case_at(2, {})
	main._set_horror(1)
	main.horror_selector.select(1)
	stream_file = _find_file(main.current_case_data, "ev_raven_video")
	main.apps["viewer"].open_file(stream_file)
	main.apps["viewer"].snap_right()
	main.apps["viewer"]._set_frame(39)
	await _settle()
	_capture("viewer_frame39_reduced.png")
	main._load_case_at(2, {})
	main._set_horror(2)
	main.horror_selector.select(2)
	stream_file = _find_file(main.current_case_data, "ev_raven_video")
	main.apps["viewer"].open_file(stream_file)
	main.apps["viewer"].snap_right()
	main.apps["viewer"]._set_frame(39)
	await _settle()
	_capture("viewer_frame39_off.png")
	print("PASS: visual QA captures written to %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	quit(0)

func _settle() -> void:
	await process_frame
	await process_frame
	await create_timer(0.12).timeout

func _capture(filename: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png("%s/%s" % [OUTPUT_DIR, filename])
	if error != OK:
		printerr("ERROR: unable to save visual QA capture %s (%d)" % [filename, error])

func _find_file(case_data: Dictionary, evidence_id: String) -> Dictionary:
	for node_value in case_data.get("network", []):
		for file_value in node_value.get("files", []):
			if String(file_value.get("evidenceId", "")) == evidence_id:
				return file_value
	return {}
