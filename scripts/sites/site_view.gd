class_name SiteView
extends PanelContainer

@export var skin_id := "search"

var title_label: Label
var content_label: RichTextLabel
var identity_label: Label
var identity_bar: PanelContainer

func _ready() -> void:
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	_build_identity_chrome(column)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	column.add_child(title_label)
	var rule := HSeparator.new()
	column.add_child(rule)
	content_label = RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.fit_content = false
	content_label.scroll_active = true
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_label.custom_minimum_size.y = 260
	column.add_child(content_label)
	_apply_skin()

func _build_identity_chrome(column: VBoxContainer) -> void:
	var profile := _skin_profile()
	identity_bar = PanelContainer.new()
	identity_bar.custom_minimum_size.y = 46
	column.add_child(identity_bar)
	var chrome := VBoxContainer.new()
	chrome.add_theme_constant_override("separation", 2)
	identity_bar.add_child(chrome)
	identity_label = Label.new()
	identity_label.name = "SkinIdentity"
	identity_label.text = String(profile.get("identity", skin_id))
	identity_label.add_theme_font_size_override("font_size", 17 if skin_id != "forum" else 15)
	identity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if skin_id == "changming" else HORIZONTAL_ALIGNMENT_LEFT
	chrome.add_child(identity_label)
	var meta := Label.new()
	meta.text = String(profile.get("meta", ""))
	meta.add_theme_font_size_override("font_size", 11 if skin_id in ["forum", "workorder"] else 12)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if skin_id == "changming" else HORIZONTAL_ALIGNMENT_LEFT
	chrome.add_child(meta)
	match skin_id:
		"forum":
			var strip := Label.new()
			strip.text = "[ 首页 ] [ 技术区 ] [ 夜话 ] [ 存档下载 ]"
			strip.add_theme_font_size_override("font_size", 12)
			column.add_child(strip)
		"raven":
			var live_strip := Label.new()
			live_strip.text = "● REC　23:47:49 OFFLINE　弹幕缓存：40"
			live_strip.add_theme_color_override("font_color", Color("#d04a4a"))
			column.add_child(live_strip)
		"workorder":
			var tabs := Label.new()
			tabs.text = "待处理(7)　|　活性维护　|　棚区排班　|　身份池"
			tabs.add_theme_font_size_override("font_size", 12)
			column.add_child(tabs)
		"campus":
			var crumb := Label.new()
			crumb.text = "首页 > 信息公开 > 缓存查询"
			crumb.add_theme_font_size_override("font_size", 12)
			column.add_child(crumb)
		"changming":
			var memorial_rule := HSeparator.new()
			column.add_child(memorial_rule)

func render(data: Dictionary) -> void:
	if title_label == null:
		_build()
	title_label.text = String(data.get("title", "未命名页面"))
	var lines: Array[String] = []
	if data.has("subtitle"):
		lines.append("[color=#777777]%s[/color]\n" % String(data["subtitle"]))
	if data.has("content"):
		lines.append(String(data["content"]))
	for result_value in data.get("results", []):
		var result: Dictionary = result_value
		lines.append("[b]%s[/b]\n[color=#777777]%s[/color]\n%s\n" % [result.get("title", ""), result.get("url", ""), result.get("snippet", "")])
	for post_value in data.get("posts", []):
		var post: Dictionary = post_value
		lines.append("[b]#%s %s[/b]  [color=#777777]%s[/color]\n%s" % [post.get("floor", ""), post.get("author", "匿名"), post.get("time", ""), post.get("body", "")])
		for reply_value in post.get("replies", []):
			var reply: Dictionary = reply_value
			lines.append("  [color=#666666]↳ %s：%s[/color]" % [reply.get("author", "访客"), reply.get("body", "")])
		lines.append("")
	if data.has("dynamicBefore"):
		lines.append("[b]—— 生前动态 ——[/b]")
		for entry_value in data.get("dynamicBefore", []):
			lines.append("[color=#777777]%s[/color] %s" % [entry_value.get("time", ""), entry_value.get("text", "")])
	if data.has("dynamicAfter"):
		lines.append("\n[b]—— 死后动态 ——[/b]")
		for entry_value in data.get("dynamicAfter", []):
			lines.append("[color=#777777]%s[/color] %s" % [entry_value.get("time", ""), entry_value.get("text", "")])
	if data.has("comments"):
		lines.append("\n[b]—— 评论区 ——[/b]")
		for comment_value in data.get("comments", []):
			lines.append("[color=#777777]%s[/color] [b]%s[/b]：%s" % [comment_value.get("time", ""), comment_value.get("author", ""), comment_value.get("text", "")])
	if data.has("tickets"):
		lines.append("[b]—— 工单队列 ——[/b]")
		for ticket_value in data.get("tickets", []):
			lines.append("[b]%s / %s[/b] [color=#777777]%s · %s[/color]\n%s\n" % [ticket_value.get("id", ""), ticket_value.get("title", ""), ticket_value.get("owner", ""), ticket_value.get("status", ""), ticket_value.get("body", "")])
	content_label.text = "\n".join(lines)

func _apply_skin() -> void:
	var profile := _skin_profile()
	var background: Color = profile.get("background", Color("#ecebe3"))
	var foreground: Color = profile.get("foreground", Color("#202020"))
	var accent: Color = profile.get("accent", foreground)
	var site_theme := Theme.new()
	site_theme.set_color("font_color", "Label", foreground)
	site_theme.set_color("font_color", "RichTextLabel", foreground)
	site_theme.set_font_size("font_size", "Label", 14 if skin_id == "forum" else 16)
	site_theme.set_font_size("normal_font_size", "RichTextLabel", 13 if skin_id == "forum" else 16)
	theme = site_theme
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = background
	panel_style.border_color = accent
	panel_style.set_border_width_all(2)
	add_theme_stylebox_override("panel", panel_style)
	if identity_bar:
		var identity_style := StyleBoxFlat.new()
		identity_style.bg_color = accent.darkened(0.2) if skin_id != "raven" else Color("#260d0d")
		identity_style.border_color = accent
		identity_style.set_border_width_all(1)
		identity_style.set_content_margin_all(7)
		identity_bar.add_theme_stylebox_override("panel", identity_style)
	if identity_label:
		identity_label.add_theme_color_override("font_color", Color("#f0eee5") if skin_id != "search" else Color("#ffffff"))
	if title_label:
		title_label.add_theme_color_override("font_color", foreground)
	if content_label:
		content_label.add_theme_color_override("default_color", foreground)

func _skin_profile() -> Dictionary:
	match skin_id:
		"campus":
			return {"background": Color("#d9e1e8"), "foreground": Color("#15293b"), "accent": Color("#315a78"), "identity": "澄岚学院信息门户", "meta": "CAMPUS NET / 学籍·设施·科研归档"}
		"forum":
			return {"background": Color("#d8d3bd"), "foreground": Color("#202718"), "accent": Color("#4d5e35"), "identity": "旧网论坛镜像 BBS", "meta": "访客计数 00387122 | 最后备份 02:04"}
		"raven":
			return {"background": Color("#171717"), "foreground": Color("#d8d8d8"), "accent": Color("#9d2424"), "identity": "RAVEN LIVE // 渡鸦频道", "meta": "纪念维护中 · LIVE 状态异常"}
		"changming":
			return {"background": Color("#e9e1cc"), "foreground": Color("#493c2e"), "accent": Color("#8b785c"), "identity": "长明·数字纪念馆", "meta": "让告别延长为一项服务"}
		"workorder":
			return {"background": Color("#cbd2c8"), "foreground": Color("#17231a"), "accent": Color("#3d5f47"), "identity": "CM-OPS / 夜班工单台", "meta": "QUEUE 07 · INTERNAL USE ONLY"}
		_:
			return {"background": Color("#ecebe3"), "foreground": Color("#202020"), "accent": Color("#404744"), "identity": "零索 / ZERO INDEX", "meta": "纯文本索引 · 公共缓存"}
