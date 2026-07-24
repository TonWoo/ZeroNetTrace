extends RefCounted

func run(t) -> void:
	var parser_script = load("res://scripts/engine/terminal_command_router.gd")
	t.truthy(parser_script != null, "terminal command router script must exist")
	if parser_script == null:
		return
	var parser = parser_script.new()
	var parsed: Dictionary = parser.parse("login 10.24.7.115 -u suye -p mantou0713")
	t.equal(parsed.get("command"), "login", "login command is parsed")
	t.equal(parsed.get("args"), ["10.24.7.115"], "address remains positional")
	t.equal(parsed.get("options", {}).get("u"), "suye", "username option is parsed")
	t.equal(parsed.get("options", {}).get("p"), "mantou0713", "password option is parsed")
	var help_parsed: Dictionary = parser.parse("help crack")
	t.equal(help_parsed.get("command"), "help", "help command is parsed")
	t.equal(help_parsed.get("args"), ["crack"], "help target remains positional")
