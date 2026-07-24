extends RefCounted

func run(t) -> void:
	var script = load("res://scripts/apps/browser_app.gd")
	t.truthy(script != null, "browser app script loads")
	if script == null:
		return
	var browser = script.new()
	var case_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/case_02_dead_streamer.json"))
	browser.case_data = case_data
	t.equal(browser.find_direct_site("raven.zhibo-lan.cn").get("id"), "site_raven_live", "browser resolves exact fictional address")
	t.equal(browser.find_direct_site("渡鸦直播").get("id"), "site_raven_live", "browser resolves site alias")
	t.equal(browser.find_direct_site("oldbbs.zero/thread/CM041").get("id"), "site_changming_leak", "browser opens search-result URLs manually")
	browser.free()
