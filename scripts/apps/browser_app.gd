extends "res://scripts/apps/app_window.gd"

signal search_submitted(text: String)

const SITE_SCENES := {
	"search": "res://scenes/sites/search_site.tscn",
	"campus": "res://scenes/sites/campus_portal.tscn",
	"forum": "res://scenes/sites/old_forum.tscn",
	"raven": "res://scenes/sites/raven_live.tscn",
	"changming": "res://scenes/sites/changming_site.tscn",
	"workorder": "res://scenes/sites/workorder_site.tscn"
}

var runtime
var case_data: Dictionary = {}
var address: LineEdit
var site_host: MarginContainer
var history: Array[String] = []
var history_index := -1
var current_site_id := ""

func _build_body(parent: MarginContainer) -> void:
	app_id = "browser"
	app_title = "浏览器 // 零索"
	title_label.text = " %s" % app_title
	var column := VBoxContainer.new()
	parent.add_child(column)
	var nav := HBoxContainer.new()
	column.add_child(nav)
	var back := Button.new()
	back.text = "<"
	back.pressed.connect(_go_back)
	nav.add_child(back)
	var forward := Button.new()
	forward.text = ">"
	forward.pressed.connect(_go_forward)
	nav.add_child(forward)
	address = LineEdit.new()
	address.placeholder_text = "输入任意搜索词或虚构地址"
	address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	address.text_submitted.connect(_search)
	nav.add_child(address)
	var go := Button.new()
	go.text = "检索"
	go.pressed.connect(func(): _search(address.text))
	nav.add_child(go)
	site_host = MarginContainer.new()
	site_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(site_host)

func configure(runtime_ref, new_case_data: Dictionary) -> void:
	runtime = runtime_ref
	case_data = new_case_data
	_render_site({"skin": "search", "title": "零索", "subtitle": "输入你知道的，不要等系统告诉你。", "results": case_data.get("defaultNoiseResults", [])})

func _process(delta: float) -> void:
	if runtime and visible and current_site_id == "site_raven_live":
		runtime.advance_content_read("site_raven_live:postdeath", delta)

func _search(text: String) -> void:
	var query := text.strip_edges()
	if query.is_empty() or runtime == null:
		return
	if history_index < history.size() - 1:
		history = history.slice(0, history_index + 1)
	history.append(query)
	history_index = history.size() - 1
	var direct_site := find_direct_site(query)
	if not direct_site.is_empty():
		if _site_is_unlocked(direct_site):
			_render_site(direct_site)
		else:
			_render_site({"skin": "search", "title": "访问被拒绝", "content": "该页面需要先取得对应凭证并完成登录。"})
		search_submitted.emit(query)
		return
	var matches: Array = runtime.submit_search(query)
	var gate_ids: Array[String] = []
	for gate_value in matches:
		gate_ids.append(String(gate_value.get("id", "")))
	var selected := {}
	for site_value in case_data.get("sites", []):
		var site: Dictionary = site_value
		if gate_ids.has(String(site.get("gateId", ""))):
			selected = site
			break
	if selected.is_empty():
		selected = {"skin": "search", "title": "零索：%s" % query, "subtitle": "没有精确命中。以下结果来自公共缓存。", "results": case_data.get("defaultNoiseResults", [])}
	_render_site(selected)
	search_submitted.emit(query)

func _render_site(site_data: Dictionary) -> void:
	for child in site_host.get_children():
		child.queue_free()
	var skin := String(site_data.get("skin", "search"))
	var packed = load(String(SITE_SCENES.get(skin, SITE_SCENES["search"])))
	var page = packed.instantiate()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	site_host.add_child(page)
	page.render(site_data)
	current_site_id = String(site_data.get("id", ""))
	if runtime and not current_site_id.is_empty():
		runtime.mark_site_read(current_site_id)

func find_direct_site(query: String) -> Dictionary:
	var normalized := query.strip_edges().to_lower().trim_suffix("/")
	for site_value in case_data.get("sites", []):
		var site: Dictionary = site_value
		for address_value in site.get("addresses", []):
			if normalized == String(address_value).strip_edges().to_lower().trim_suffix("/"):
				return site
	return {}

func _site_is_unlocked(site: Dictionary) -> bool:
	var gate_id := String(site.get("requiresGate", ""))
	return gate_id.is_empty() or (runtime != null and runtime.resolved_gates.has(gate_id))

func _go_back() -> void:
	if history_index > 0:
		history_index -= 1
		address.text = history[history_index]
		_search_without_history(address.text)

func _go_forward() -> void:
	if history_index + 1 < history.size():
		history_index += 1
		address.text = history[history_index]
		_search_without_history(address.text)

func _search_without_history(query: String) -> void:
	if runtime == null:
		return
	var matches: Array = runtime.submit_search(query)
	var ids: Array[String] = []
	for gate_value in matches:
		ids.append(String(gate_value.get("id", "")))
	for site_value in case_data.get("sites", []):
		if ids.has(String(site_value.get("gateId", ""))):
			_render_site(site_value)
			return
	_render_site({"skin": "search", "title": "零索：%s" % query, "results": case_data.get("defaultNoiseResults", [])})
