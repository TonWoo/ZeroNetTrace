extends "res://scripts/apps/app_window.gd"

var source_conversations: Array = []
var conversations: Array = []
var pushed_messages: Array = []
var runtime
var list: ItemList
var transcript: RichTextLabel

func _build_body(parent: MarginContainer) -> void:
	app_id = "messenger"
	app_title = "通讯器 // PING"
	title_label.text = " %s" % app_title
	var split := HSplitContainer.new()
	parent.add_child(split)
	list = ItemList.new()
	list.custom_minimum_size.x = 170
	list.item_selected.connect(_show_conversation)
	split.add_child(list)
	transcript = RichTextLabel.new()
	transcript.bbcode_enabled = true
	transcript.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transcript.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(transcript)

func set_conversations(new_conversations: Array, new_runtime = null) -> void:
	source_conversations = new_conversations
	pushed_messages.clear()
	if runtime != new_runtime:
		if runtime != null and runtime.state_changed.is_connected(_refresh_content):
			runtime.state_changed.disconnect(_refresh_content)
		runtime = new_runtime
		if runtime != null and not runtime.state_changed.is_connected(_refresh_content):
			runtime.state_changed.connect(_refresh_content)
	_refresh_content()

func _refresh_content() -> void:
	conversations = []
	for conversation_value in source_conversations:
		var conversation: Dictionary = conversation_value.duplicate(true)
		var source_messages: Array = conversation_value.get("messages", [])
		conversation["messages"] = runtime.filter_unlocked_entries(source_messages) if runtime != null else source_messages.duplicate(true)
		conversations.append(conversation)
	if not pushed_messages.is_empty():
		if conversations.is_empty():
			conversations.append({"name": "线人提示", "messages": []})
		conversations[0].get("messages", []).append_array(pushed_messages)
	list.clear()
	for conversation_value in conversations:
		list.add_item(String(conversation_value.get("name", "未知联系人")))
	if not conversations.is_empty():
		list.select(0)
		_show_conversation(0)

func push_hint(sender: String, text: String, timestamp: String) -> void:
	pushed_messages.append({"from": sender, "time": timestamp, "text": text})
	_refresh_content()

func _show_conversation(index: int) -> void:
	if index < 0 or index >= conversations.size():
		return
	var lines: Array[String] = []
	for message_value in conversations[index].get("messages", []):
		var message: Dictionary = message_value
		var color := "#33ff66" if String(message.get("from", "")) == "陈默" else "#d7ddd8"
		lines.append("[color=#777f7a]%s[/color] [color=%s][b]%s[/b][/color]\n%s" % [message.get("time", ""), color, message.get("from", ""), message.get("text", "")])
	transcript.text = "\n\n".join(lines)
