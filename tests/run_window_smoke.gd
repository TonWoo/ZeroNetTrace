extends SceneTree

const AppWindowScript = preload("res://scripts/apps/app_window.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var window = AppWindowScript.new()
	root.add_child(window)
	await process_frame
	window.size = Vector2(640, 520)
	await process_frame
	window._toggle_collapse()
	await process_frame
	await process_frame
	if not is_equal_approx(window.size.y, 48.0):
		printerr("FAIL: minimized height expected 48, got %.1f" % window.size.y)
		quit(1)
		return
	window._toggle_collapse()
	await process_frame
	await process_frame
	if not is_equal_approx(window.size.y, 520.0):
		printerr("FAIL: restored height expected 520, got %.1f" % window.size.y)
		quit(1)
		return
	window.free()
	print("PASS: app window minimize and restore preserve geometry")
	quit(0)
