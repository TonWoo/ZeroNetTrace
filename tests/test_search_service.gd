extends RefCounted

func run(t) -> void:
	var script = load("res://scripts/engine/search_service.gd")
	t.truthy(script != null, "search service script must exist")
	if script == null:
		return
	var service = script.new()
	t.equal(service.normalize("  ＣＨＡＮＧＭＩＮＧ！ "), "changming", "full-width latin and punctuation normalize")
	t.equal(service.normalize("长 明。网络"), "长明网络", "Chinese whitespace and punctuation normalize")
	var gate := {"accept": ["长明"], "aliases": ["changming", "数字纪念馆"]}
	t.truthy(service.matches_gate("我想查 长明网络科技", gate), "canonical term matches inside free text")
	t.truthy(service.matches_gate("CHANGMING", gate), "alias matching ignores case")

