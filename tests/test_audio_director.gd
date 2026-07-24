extends RefCounted

const AudioDirectorScript = preload("res://scripts/engine/audio_director.gd")

func run(t) -> void:
	var director = AudioDirectorScript.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(director)
	director._ready()
	t.equal(DisplayServer.get_name(), "headless", "audio test runs with headless display server")
	t.equal(director._player, null, "headless mode does not create an audio playback graph")
	t.truthy(director.has_method("begin_silence"), "audio director exposes post-sting silence control")
	if director.has_method("begin_silence"):
		director.begin_silence(5.0)
		t.equal(director._silence_frames, 110250, "five-second horror silence is scheduled at the generator rate")
	t.truthy(director.has_method("play_hard_drive"), "audio director exposes a procedural hard-drive seek effect")
	if director.has_method("play_hard_drive"):
		director.play_hard_drive(0.1)
		t.equal(director._hard_drive_frames, 2205, "hard-drive seek duration is scheduled at the generator rate")
	director.free()
