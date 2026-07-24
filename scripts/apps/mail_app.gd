extends "res://scripts/apps/app_window.gd"

signal attachment_open_requested(file_entry: Dictionary)
signal mail_opened(mail_id: String)

var source_mails: Array = []
var mails: Array = []
var runtime
var list: ItemList
var detail: RichTextLabel
var attachments: ItemList

func _build_body(parent: MarginContainer) -> void:
	app_id = "mail"
	app_title = "邮件 // DEADLETTER"
	title_label.text = " %s" % app_title
	var split := HSplitContainer.new()
	parent.add_child(split)
	list = ItemList.new()
	list.custom_minimum_size.x = 250
	list.item_selected.connect(_on_mail_selected)
	split.add_child(list)
	var right := VBoxContainer.new()
	split.add_child(right)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = true
	detail.selection_enabled = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(detail)
	attachments = ItemList.new()
	attachments.custom_minimum_size.y = 82
	attachments.item_activated.connect(_open_attachment)
	right.add_child(attachments)

func set_mails(new_mails: Array, new_runtime = null) -> void:
	source_mails = new_mails
	if runtime != new_runtime:
		if runtime != null and runtime.state_changed.is_connected(_refresh_content):
			runtime.state_changed.disconnect(_refresh_content)
		runtime = new_runtime
		if runtime != null and not runtime.state_changed.is_connected(_refresh_content):
			runtime.state_changed.connect(_refresh_content)
	_refresh_content()

func _refresh_content() -> void:
	var selected_key := ""
	var selected := list.get_selected_items()
	if not selected.is_empty() and selected[0] < mails.size():
		selected_key = _mail_key(mails[selected[0]])
	mails = runtime.filter_unlocked_entries(source_mails) if runtime != null else source_mails
	list.clear()
	for mail_value in mails:
		var mail: Dictionary = mail_value
		list.add_item("%s\n%s" % [mail.get("time", ""), mail.get("subject", "")])
	if not mails.is_empty() and not selected_key.is_empty():
		var selected_index := -1
		for index in mails.size():
			if _mail_key(mails[index]) == selected_key:
				selected_index = index
				break
		if selected_index >= 0:
			list.select(selected_index)
			_show_mail(selected_index)
		else:
			detail.text = "[color=#7f8782]选择邮件以读取原文[/color]"
			attachments.clear()
	elif not mails.is_empty():
		detail.text = "[color=#7f8782]选择邮件以读取原文[/color]"
		attachments.clear()
	else:
		detail.text = "[color=#7f8782]当前没有可读取邮件[/color]"
		attachments.clear()

func _mail_key(mail: Dictionary) -> String:
	return "%s|%s" % [mail.get("time", ""), mail.get("subject", "")]

func _show_mail(index: int) -> void:
	if index < 0 or index >= mails.size():
		return
	var mail: Dictionary = mails[index]
	detail.text = "[b]%s[/b]\n[color=#7f8782]发件人：%s\n时间：%s[/color]\n\n%s\n\n—— %s" % [mail.get("subject", ""), mail.get("from", ""), mail.get("time", ""), mail.get("body", ""), mail.get("signature", "")]
	attachments.clear()
	for attachment_value in mail.get("attachments", []):
		var attachment: Dictionary = attachment_value
		attachments.add_item("附件：%s（双击打开）" % attachment.get("name", attachment.get("path", "")))

func _on_mail_selected(index: int) -> void:
	if index < 0 or index >= mails.size():
		return
	_show_mail(index)
	var mail: Dictionary = mails[index]
	mail_opened.emit(String(mail.get("id", _mail_key(mail))))

func _open_attachment(index: int) -> void:
	var selected := list.get_selected_items()
	if selected.is_empty():
		return
	var mail: Dictionary = mails[selected[0]]
	var mail_attachments: Array = mail.get("attachments", [])
	if index >= 0 and index < mail_attachments.size():
		attachment_open_requested.emit(mail_attachments[index])
