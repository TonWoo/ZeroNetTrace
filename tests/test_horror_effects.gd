extends RefCounted

const TerminalScript = preload("res://scripts/apps/terminal_app.gd")
const AtmosphereScript = preload("res://scripts/engine/desktop_atmosphere.gd")

func run(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var terminal = TerminalScript.new()
	tree.root.add_child(terminal)
	terminal._ready()
	t.truthy(terminal.has_method("inject_system_line"), "terminal exposes data-driven horror injection")
	if terminal.has_method("inject_system_line"):
		terminal.inject_system_line("trace 陈默")
		t.contains_text(terminal.output.get_parsed_text(), "trace 陈默", "terminal renders the injected command")
	terminal.free()

	var atmosphere = AtmosphereScript.new()
	tree.root.add_child(atmosphere)
	atmosphere._ready()
	t.truthy(atmosphere.has_method("set_persistent_mark"), "desktop atmosphere exposes persistent anomaly marks")
	if atmosphere.has_method("set_persistent_mark"):
		atmosphere.set_persistent_mark("counter_trace")
		t.truthy(atmosphere._persistent_marks.has("counter_trace"), "desktop anomaly remains active after the event")
	atmosphere.free()
