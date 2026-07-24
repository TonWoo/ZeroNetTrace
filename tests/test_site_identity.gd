extends RefCounted

const SITE_SCENES := [
	"res://scenes/sites/search_site.tscn",
	"res://scenes/sites/campus_portal.tscn",
	"res://scenes/sites/old_forum.tscn",
	"res://scenes/sites/raven_live.tscn",
	"res://scenes/sites/changming_site.tscn",
	"res://scenes/sites/workorder_site.tscn"
]

func run(t) -> void:
	var signatures: Array[String] = []
	for path in SITE_SCENES:
		var site = load(path).instantiate()
		site._ready()
		var marker = site.find_child("SkinIdentity", true, false)
		t.truthy(marker != null, "site has visible identity chrome: %s" % path)
		if marker != null:
			signatures.append(String(marker.text))
		t.truthy(site.theme != null, "site owns an independent Theme: %s" % path)
		site.free()
	var unique := {}
	for signature in signatures:
		unique[signature] = true
	t.equal(unique.size(), SITE_SCENES.size(), "every site identity signature is distinct")
