extends RefCounted

const CASE_PATHS := [
	"res://data/cases/prologue.json",
	"res://data/cases/case_01_gate.json",
	"res://data/cases/case_02_dead_streamer.json"
]
const ART_STYLE_SUFFIX := "muted colors, early-2000s Chinese internet aesthetic, slightly low-res, candid documentary realism, no futuristic neon"
const HORROR_STYLE_SUFFIX := "muted colors, low-bitrate early-2000s Chinese internet video, slightly low-res, liminal documentary realism, no gore, no futuristic neon"
const PROMPT_SECTIONS := [
	"Purpose and medium:",
	"Camera and composition:",
	"Scene and required details:",
	"Required readable text:",
	"Continuity:",
	"Lighting and image defects:",
	"Do not include:",
	"Output requirements:"
]
const HORROR_ART_IDS := ["art_raven_stream_base", "art_frame39"]

func run(t) -> void:
	var validator_script = load("res://scripts/engine/content_validator.gd")
	var repository_script = load("res://scripts/engine/data_repository.gd")
	t.truthy(validator_script != null and repository_script != null, "content test dependencies load")
	if validator_script == null or repository_script == null:
		return
	var validator = validator_script.new()
	var repository = repository_script.new()
	var art_manifest := FileAccess.get_file_as_string("res://assets/art_manifest.md")
	t.truthy(art_manifest.count(ART_STYLE_SUFFIX) >= 8, "art manifest applies the shared documentary style suffix")
	t.truthy(art_manifest.count(HORROR_STYLE_SUFFIX) >= 2, "horror frames apply the shared low-bitrate horror suffix")
	var index_data: Dictionary = repository.load_json("res://data/cases/index.json")
	t.equal(index_data.get("cases", []).size(), 3, "MVP index contains prologue, case 01 and case 02")
	var loaded_cases: Array[Dictionary] = []
	for path in CASE_PATHS:
		var case_data: Dictionary = repository.load_json(path)
		t.truthy(not case_data.is_empty(), "case JSON loads: %s" % path)
		if case_data.is_empty():
			continue
		loaded_cases.append(case_data)
		t.equal(validator.validate_case(case_data, true), [], "case passes structural and placeholder validation: %s" % path)
		t.truthy(not String(case_data.get("coreQuestion", "")).is_empty(), "case declares its core question")
		t.truthy(case_data.get("investigationLines", []).size() >= 1, "case declares investigation lines")
		t.truthy(case_data.get("twists", []).size() >= 1, "case declares twists")
		t.truthy(case_data.has("unlockRequirements"), "case declares unlock requirements")
		for mail_value in case_data.get("mails", []):
			t.truthy(String(mail_value.get("body", "")).length() >= 100, "every story mail has at least 100 Chinese characters")
		for site_value in case_data.get("sites", []):
			if site_value.has("results"):
				t.truthy(site_value.get("results", []).size() >= 5, "every search hit page has at least five results")
	if loaded_cases.size() != 3:
		repository.free()
		return
	var art_assets := {}
	for loaded_case in loaded_cases:
		for asset_value in loaded_case.get("artAssets", []):
			art_assets[String(asset_value.get("id", ""))] = asset_value
	t.equal(art_assets.size(), 10, "MVP registers ten unique image-generation contracts")
	t.equal(art_manifest.count("### GPT Image 2 Prompt"), 10, "art manifest gives every asset a copyable GPT Image 2 prompt block")
	for asset_id_value in art_assets:
		var asset_id := String(asset_id_value)
		t.contains_text(art_manifest, "## `%s`" % asset_id, "art manifest gives %s its own asset section" % asset_id)
		var prompt := String(art_assets[asset_id].get("prompt", ""))
		t.truthy(prompt.length() >= 700, "%s prompt is a detailed GPT Image 2 scene contract" % asset_id)
		for section in PROMPT_SECTIONS:
			t.contains_text(prompt, section, "%s prompt contains section %s" % [asset_id, section])
		var expected_suffix := HORROR_STYLE_SUFFIX if HORROR_ART_IDS.has(asset_id) else ART_STYLE_SUFFIX
		t.equal(prompt.count(expected_suffix), 1, "%s prompt applies its shared style exactly once" % asset_id)
	var prompt_tokens := {
		"art_deadletter_stamp": ["MIRROR-17", "only fully readable text"],
		"art_gate_n17": ["N17", "old access-control reader"],
		"art_shenzhi_df2": ["DF-2", "2023", "35mm film camera"],
		"art_lanpu_corridor": ["fixed high corner surveillance camera", "no human figure"],
		"art_raven_avatar": ["young Chinese male game streamer", "square profile avatar"],
		"art_cat_mantou": ["chubby white cat", "mechanical keyboard"],
		"art_raven_room_reference": ["left side of the door", "fixed webcam position"],
		"art_raven_stream_base": ["right side of the door", "replica studio room"],
		"art_frame39": ["art_raven_stream_base.png", "foreground actor keeps his head lowered", "mirror reflection turns its head", "right side of the door"],
		"art_studio_b": ["棚 B", "lighting stands", "unfinished fake walls"]
	}
	for asset_id_value in prompt_tokens:
		var asset_id := String(asset_id_value)
		var prompt := String(art_assets.get(asset_id, {}).get("prompt", ""))
		for token_value in prompt_tokens[asset_id]:
			t.contains_text(prompt, String(token_value), "%s prompt preserves required detail: %s" % [asset_id, token_value])
	var case01: Dictionary = loaded_cases[1]
	t.truthy(case01.get("investigationLines", []).size() >= 3 and case01.get("investigationLines", []).size() <= 5, "case 01 has three to five investigation lines")
	t.truthy(case01.get("twists", []).size() >= 2, "case 01 declares both reversals")
	t.truthy(case01.get("conversations", [])[0].get("messages", []).size() >= 48, "case 01 has at least 24 two-way chat rounds")
	var case01_forum := _site(case01, "site_case01_forum")
	t.truthy(case01_forum.get("posts", []).size() >= 12, "case 01 forum has at least twelve posts")
	t.truthy(_count_full_posts(case01_forum.get("posts", [])) >= 5, "case 01 has at least five full posts with three replies")
	t.equal(_unique_reply_count(case01_forum.get("posts", [])), _reply_count(case01_forum.get("posts", [])), "case 01 forum replies are individually written instead of duplicated filler")
	t.truthy(_file_lines(case01, "ev_gate_log") >= 40, "case 01 access log has at least forty lines")
	t.truthy(_file_lines(case01, "ev_version_log") >= 40, "case 01 version log has at least forty lines")
	var case02: Dictionary = loaded_cases[2]
	t.equal(case02.get("investigationLines", []).size(), 5, "case 02 declares all five template investigation lines")
	t.truthy(case02.get("twists", []).size() >= 2, "case 02 declares both reversals")
	var raven_site := _site(case02, "site_raven_live")
	t.equal(raven_site.get("dynamicBefore", []).size(), 30, "case 02 has thirty pre-death posts")
	t.equal(raven_site.get("dynamicAfter", []).size(), 90, "case 02 has ninety post-death posts")
	t.truthy(raven_site.get("comments", []).size() >= 40, "case 02 has forty fan comments")
	var comment_authors := {}
	var numbered_comment_authors := 0
	for comment_value in raven_site.get("comments", []):
		var author := String(comment_value.get("author", ""))
		comment_authors[author] = true
		if author.contains("_"):
			numbered_comment_authors += 1
	t.equal(numbered_comment_authors, 0, "case 02 fan comments use natural handles instead of numbered faction templates")
	t.truthy(comment_authors.size() >= 35, "case 02 fan comments are written by a varied set of handles")
	t.truthy(case02.get("conversations", [])[0].get("messages", []).size() >= 120, "case 02 has sixty two-way chat rounds")
	t.truthy(_file_lines(case02, "ev_ingest_log") >= 40, "case 02 ingest log has at least forty lines")
	t.truthy(_file_lines(case02, "ev_stream_history") >= 15, "case 02 live history has at least fifteen lines")
	var leak_forum := _site(case02, "site_changming_leak")
	t.truthy(leak_forum.get("posts", []).size() >= 12, "case 02 leak forum has twelve complete topic titles")
	t.truthy(leak_forum.get("posts", [])[0].get("replies", []).size() >= 12, "leak post has at least twelve replies")
	t.truthy(_count_full_posts(leak_forum.get("posts", [])) >= 5, "case 02 leak forum has at least five full posts with three replies")
	t.truthy(_site(case02, "site_workorders").get("tickets", []).size() >= 7, "workorder site has seven complete tickets")
	t.truthy(_file_lines(case02, "ev_schedule") >= 20, "schedule has at least twenty rows")
	t.truthy(_file_lines(case02, "ev_identity_pool") >= 30, "identity pool has at least thirty rows")
	t.equal(case02.get("caseReport", []).size(), 5, "case 02 has five report questions")
	var frame_event := _horror(case02, "h3")
	t.equal(frame_event.get("trigger", {}).get("type"), "viewer_frame", "case 02 jumpscare uses viewer frame trigger")
	t.equal(frame_event.get("trigger", {}).get("target"), "raven_47s:39", "case 02 jumpscare is exactly evidence frame 39")
	var frame_after_text := String(frame_event.get("afterBeat", {}).get("text", ""))
	var frame_chat_texts: Array[String] = []
	for message_value in case02.get("conversations", [])[0].get("messages", []):
		if String(message_value.get("unlockWhen", {}).get("type", "")) == "horror" and String(message_value.get("unlockWhen", {}).get("id", "")) == "h3":
			frame_chat_texts.append(String(message_value.get("text", "")))
	t.truthy(not frame_after_text.is_empty() and not frame_chat_texts.has(frame_after_text), "frame 39 after-beat message is unique instead of duplicating the unlocked transcript")
	var stream_file := _file(case02, "ev_raven_video")
	t.truthy(stream_file.get("frameEvents", {}).has("39"), "stream file carries its frame-39 presentation data")
	t.equal(stream_file.get("frameEvents", {}).get("39", {}).get("trigger", {}).get("target"), "raven_47s:39", "frame event target is data driven")
	var asset_ids: Array[String] = []
	for asset_value in case02.get("artAssets", []):
		asset_ids.append(String(asset_value.get("id", "")))
	t.truthy(asset_ids.has("art_frame39") and asset_ids.has("art_raven_stream_base"), "case 02 registers base stream and frame 39 art")
	repository.free()

func _site(case_data: Dictionary, site_id: String) -> Dictionary:
	for site_value in case_data.get("sites", []):
		if String(site_value.get("id", "")) == site_id:
			return site_value
	return {}

func _horror(case_data: Dictionary, event_id: String) -> Dictionary:
	for event_value in case_data.get("horrorEvents", []):
		if String(event_value.get("id", "")) == event_id:
			return event_value
	return {}

func _count_full_posts(posts: Array) -> int:
	var count := 0
	for post_value in posts:
		if String(post_value.get("body", "")).length() >= 80 and post_value.get("replies", []).size() >= 3:
			count += 1
	return count

func _reply_count(posts: Array) -> int:
	var count := 0
	for post_value in posts:
		count += post_value.get("replies", []).size()
	return count

func _unique_reply_count(posts: Array) -> int:
	var unique := {}
	for post_value in posts:
		for reply_value in post_value.get("replies", []):
			unique[String(reply_value.get("body", ""))] = true
	return unique.size()

func _file_lines(case_data: Dictionary, evidence_id: String) -> int:
	var file_entry := _file(case_data, evidence_id)
	if not file_entry.is_empty():
		return String(file_entry.get("content", "")).split("\n").size()
	return 0

func _file(case_data: Dictionary, evidence_id: String) -> Dictionary:
	for node_value in case_data.get("network", []):
		for file_value in node_value.get("files", []):
			if String(file_value.get("evidenceId", "")) == evidence_id:
				return file_value
	return {}
