extends SceneTree

const HorrorDirectorScript = preload("res://scripts/engine/horror_director.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var director = HorrorDirectorScript.new()
	var after_beat := {"sender": "", "text": ""}
	root.add_child(director)
	await process_frame
	if not director.has_method("set_intensity"):
		printerr("FAIL: horror director has no intensity transition handler")
		quit(1)
		return
	if not director.has_signal("after_beat_ready"):
		printerr("FAIL: horror director has no data-driven after-beat signal")
		quit(1)
		return
	director.after_beat_ready.connect(func(sender: String, text: String):
		after_beat["sender"] = sender
		after_beat["text"] = text
	)
	director.set_intensity("reduced")
	director.play_event({"level": "C", "variants": {"reduced": {"text": "画面定格"}}, "afterBeat": {"sender": "苏晚", "text": "你还在吗？", "delay": 0.01}})
	await process_frame
	if not director.message.visible:
		printerr("FAIL: reduced horror event did not become visible")
		quit(1)
		return
	if director.flash.color.a > 0.0:
		printerr("FAIL: reduced C event still displayed a flash")
		quit(1)
		return
	await create_timer(0.05).timeout
	if after_beat["sender"] != "苏晚" or after_beat["text"] != "你还在吗？":
		printerr("FAIL: C event did not emit its structured after-beat")
		quit(1)
		return
	director.set_intensity("off")
	await process_frame
	if director.message.visible or director.flash.color.a > 0.0:
		printerr("FAIL: switching horror off did not clear the active presentation")
		quit(1)
		return
	director.free()
	print("PASS: horror intensity off clears active presentation")
	quit(0)
