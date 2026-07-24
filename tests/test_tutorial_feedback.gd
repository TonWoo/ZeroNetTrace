extends RefCounted

const WindowScript = preload("res://scripts/apps/app_window.gd")
const MainScript = preload("res://scripts/os/main.gd")

class FeedbackWindow:
	extends RefCounted
	var visible := true
	var pulses: Array[String] = []
	func pulse_feedback(style: String) -> void:
		pulses.append(style)

class FeedbackAudio:
	extends RefCounted
	var progress_calls := 0
	func play_progress_soft() -> void:
		progress_calls += 1

func run(t) -> void:
	var window = WindowScript.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(window)
	window._ready()
	t.truthy(window.has_method("pulse_feedback"), "app windows expose tutorial feedback pulses")
	var original_position: Vector2 = window.position
	var original_size: Vector2 = window.size
	if window.has_method("pulse_feedback"):
		window.pulse_feedback("soft")
	t.truthy(window.get("_feedback_border") != null, "feedback uses a border overlay")
	if window.get("_feedback_border") != null:
		t.truthy(window.get("_feedback_border").mouse_filter == Control.MOUSE_FILTER_IGNORE, "feedback never intercepts input")
	t.equal(window.position, original_position, "feedback does not move the window")
	t.equal(window.size, original_size, "feedback does not resize the window")
	var first_tween: Variant = window.get("_feedback_tween")
	if window.has_method("pulse_feedback"):
		window.pulse_feedback("soft")
	t.equal(window.get("_feedback_tween"), first_tween, "rapid feedback calls merge instead of flashing again")
	window.free()
	var main = MainScript.new()
	var fake_window = FeedbackWindow.new()
	var fake_audio = FeedbackAudio.new()
	main.apps = {"terminal": fake_window}
	main.audio_director = fake_audio
	main._on_tutorial_feedback_requested("terminal", "soft", "progress_soft")
	t.equal(fake_window.pulses, ["soft"], "main routes tutorial pulses to the contributing app")
	t.equal(fake_audio.progress_calls, 1, "main routes tutorial progress to the non-horror cue")
	main.free()
