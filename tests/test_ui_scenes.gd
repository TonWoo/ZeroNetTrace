extends RefCounted

const SCENES := [
	"res://scenes/os/main.tscn",
	"res://scenes/apps/terminal_app.tscn",
	"res://scenes/apps/browser_app.tscn",
	"res://scenes/apps/mail_app.tscn",
	"res://scenes/apps/messenger_app.tscn",
	"res://scenes/apps/viewer_app.tscn",
	"res://scenes/apps/notebook_app.tscn",
	"res://scenes/apps/case_report_app.tscn",
	"res://scenes/sites/search_site.tscn",
	"res://scenes/sites/campus_portal.tscn",
	"res://scenes/sites/old_forum.tscn",
	"res://scenes/sites/raven_live.tscn",
	"res://scenes/sites/changming_site.tscn",
	"res://scenes/sites/workorder_site.tscn"
]

func run(t) -> void:
	for path in SCENES:
		var packed = load(path)
		t.truthy(packed != null, "scene loads: %s" % path)
		if packed != null:
			var instance = packed.instantiate()
			t.truthy(instance is Control, "scene root is Control: %s" % path)
			t.truthy(instance.get_script() != null, "scene script is valid: %s" % path)
			instance.free()
