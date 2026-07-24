extends RefCounted

const ViewerScript = preload("res://scripts/apps/viewer_app.gd")
const RuntimeScript = preload("res://scripts/engine/case_runtime.gd")

func run(t) -> void:
	var case_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/minimal_case.json"))
	case_data["horrorEvents"].append({"id": "fixture_frame", "level": "C", "trigger": {"type": "viewer_frame", "target": "fixture:7"}, "once": true, "variants": {"full": {"text": "fixture"}}})
	var runtime = RuntimeScript.new()
	runtime.setup(case_data)
	var viewer = ViewerScript.new()
	viewer._ready()
	viewer.configure(runtime)
	t.truthy(viewer.has_method("asset_resource_path"), "viewer exposes the documented assetId replacement path")
	if viewer.has_method("asset_resource_path"):
		t.equal(viewer.asset_resource_path("fixture_special"), "res://assets/art/fixture_special.png", "viewer maps assetId to the drop-in PNG location")
	viewer.current_file = {
		"type": "video",
		"frames": 10,
		"assetId": "fixture_base",
		"frameEvents": {
			"7": {"assetId": "fixture_special", "description": "第七格异常", "trigger": {"type": "viewer_frame", "target": "fixture:7"}}
		}
	}
	viewer.frame_controls.visible = true
	viewer.frame_slider.max_value = 10
	viewer._set_frame(7)
	t.contains_text(viewer.placeholder_label.text, "fixture_special", "viewer takes special frame art from file data")
	t.equal(runtime.consume_triggered_horror().size(), 1, "viewer forwards the data-defined trigger")
	viewer.free()
	runtime.free()
