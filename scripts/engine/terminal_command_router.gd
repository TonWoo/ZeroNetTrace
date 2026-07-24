class_name TerminalCommandRouter
extends RefCounted

const SUPPORTED_COMMANDS := [
	"scan", "probe", "crack", "login", "ls", "cd", "cat", "open", "get", "trace", "note", "disconnect", "help", "tutorial"
]

const COMMAND_HELP := {
	"scan": {"group": "网络侦察", "syntax": "scan", "purpose": "列出当前网络边界内可见节点。", "when": "获得新地址或进入新网络边界后。", "example": "scan"},
	"probe": {"group": "网络侦察", "syntax": "probe <节点>", "purpose": "识别节点的访问模式、锁层和反向追踪配置。", "when": "在 crack 前确认目标状态。", "example": "probe NODE"},
	"crack": {"group": "网络侦察", "syntax": "crack <节点>", "purpose": "启动虚构锁层的异步破解任务。", "when": "probe 确认目标可破解后。", "example": "crack NODE"},
	"login": {"group": "网络侦察", "syntax": "login <节点> -u <用户> -p <密码>", "purpose": "使用已调查得到的凭证登录节点。", "when": "probe 显示目标只接受凭证时。", "example": "login NODE -u USER -p PASS"},
	"cd": {"group": "文件系统", "syntax": "cd [节点:]<目录>", "purpose": "切换当前节点或目录。", "when": "节点已获得访问权限后。", "example": "cd NODE:/archive"},
	"ls": {"group": "文件系统", "syntax": "ls [目录]", "purpose": "列出当前目录内容。", "when": "进入节点后先了解文件结构。", "example": "ls /archive"},
	"cat": {"group": "文件系统", "syntax": "cat <文件>", "purpose": "在终端阅读文本、日志或表格原文。", "when": "需要核对可读文件内容时。", "example": "cat /path/file.log"},
	"open": {"group": "文件系统", "syntax": "open <文件>", "purpose": "在查看器中打开文件。", "when": "文件需要图像、视频或专用查看方式时。", "example": "open /path/frame.dat"},
	"get": {"group": "文件系统", "syntax": "get <文件>", "purpose": "把原始文件复制到本地证据目录。", "when": "确认文件需要作为结案证据保存时。", "example": "get /path/evidence.log"},
	"trace": {"group": "风险控制", "syntax": "trace <中继>", "purpose": "利用 COUNTER-PING 中继降低反向追踪压力。", "when": "破解或浏览时出现中继提示后。", "example": "trace RELAY"},
	"disconnect": {"group": "风险控制", "syntax": "disconnect", "purpose": "主动断开当前网络会话。", "when": "追踪压力过高或准备离开节点时。", "example": "disconnect"},
	"note": {"group": "调查辅助", "syntax": "note <内容>", "purpose": "把文字追加到笔记本。", "when": "需要保存自己的推理时。", "example": "note 镜面位置与旧照片不一致"},
	"help": {"group": "系统帮助", "syntax": "help [命令]", "purpose": "查看命令索引或单条命令说明。", "when": "不清楚下一步操作方法时。", "example": "help probe"},
	"tutorial": {"group": "系统帮助", "syntax": "tutorial <skip|restart>", "purpose": "跳过或重新同步序章教学。", "when": "只想关闭教学投递，或需要恢复教学上下文时。", "example": "tutorial restart"}
}

const HELP_GROUPS := ["网络侦察", "文件系统", "风险控制", "调查辅助", "系统帮助"]

var runtime
var tutorial_runtime
var current_node := ""
var current_path := "/"
var command_history: Array[String] = []

func _init(runtime_ref = null, tutorial_ref = null) -> void:
	runtime = runtime_ref
	tutorial_runtime = tutorial_ref

func configure(runtime_ref, tutorial_ref = null) -> void:
	runtime = runtime_ref
	tutorial_runtime = tutorial_ref

func execute(raw_text: String) -> Dictionary:
	var parsed := parse(raw_text)
	var command := String(parsed.get("command", ""))
	if command.is_empty():
		return _result(false, "empty_command", String(parsed.get("error", "请输入命令。")))
	command_history.append(raw_text)
	if not SUPPORTED_COMMANDS.has(command):
		var suggestion := _closest_command(command)
		if not suggestion.is_empty():
			return _result(false, "unknown_command", "未知命令：%s。你是否想输入 %s？" % [command, suggestion])
		return _result(false, "unknown_command", "未知命令：%s。输入 help 查看本地命令手册。" % command)
	if command == "help":
		var help_target := _required_arg(parsed.get("args", []), 0)
		if help_target == "tutorial" and tutorial_runtime != null:
			return _result(true, "help_tutorial", tutorial_runtime.get_help_text())
		return _result(true, "help_ok", _help_index() if help_target.is_empty() else _help_for(help_target))
	if command == "tutorial":
		return _execute_tutorial(parsed.get("args", []))
	var missing := _validate_required_arguments(command, parsed)
	if not missing.is_empty():
		return _missing_argument(command)
	if runtime == null:
		return _result(false, "runtime_missing", "案件运行时尚未加载。")
	var args: Array = parsed.get("args", [])
	var options: Dictionary = parsed.get("options", {})
	match command:
		"scan":
			var addresses: Array[String] = runtime.get_visible_addresses()
			return _result(true, "scan_ok", "可见节点：\n" + "\n".join(addresses))
		"probe":
			return runtime.probe(_required_arg(args, 0))
		"crack":
			return runtime.start_crack(_required_arg(args, 0))
		"login":
			var addr := _required_arg(args, 0)
			var response: Dictionary = runtime.login(addr, String(options.get("u", "")), String(options.get("p", "")))
			if bool(response.get("ok", false)):
				current_node = addr
				current_path = "/"
			return response
		"ls":
			var target_path := _resolve_path(_required_arg(args, 0, current_path))
			var entries: Array[String] = runtime.list_directory(current_node, target_path)
			if entries.is_empty() and not runtime.directory_exists(current_node, target_path):
				return _result(false, "directory_missing", "目录不存在或当前未连接节点。")
			return _result(true, "list_ok", "\n".join(entries))
		"cd":
			return _change_directory(_required_arg(args, 0, "/"))
		"cat":
			var read_result: Dictionary = runtime.open_file(current_node, _resolve_path(_required_arg(args, 0)))
			if bool(read_result.get("ok", false)) and String(read_result.get("type", "text")) not in ["text", "log", "doc", "sheet", "db"]:
				return _result(false, "cat_unsupported", "该文件类型请使用 open。")
			return read_result
		"open":
			var open_result: Dictionary = runtime.open_file(current_node, _resolve_path(_required_arg(args, 0)))
			if bool(open_result.get("ok", false)):
				open_result["action"] = "open_viewer"
			return open_result
		"get":
			return runtime.collect_evidence(current_node, _resolve_path(_required_arg(args, 0)))
		"trace":
			return runtime.trace_target(_required_arg(args, 0))
		"note":
			var note_text := " ".join(args).strip_edges()
			if note_text.is_empty():
				return _result(false, "note_empty", "笔记内容为空。")
			runtime.notes += ("\n" if not runtime.notes.is_empty() else "") + note_text
			return _result(true, "note_saved", "笔记已保存。")
		"disconnect":
			current_node = ""
			current_path = "/"
			return runtime.force_disconnect(false)
	return _result(false, "unknown_command", "未知命令。")

func autocomplete(prefix: String) -> Array[String]:
	var normalized := prefix.to_lower()
	var results: Array[String] = []
	for command in SUPPORTED_COMMANDS:
		if command.begins_with(normalized):
			results.append(command)
	return results

func _change_directory(raw_target: String) -> Dictionary:
	var target_node := current_node
	var target_path := raw_target
	if raw_target.contains(":"):
		var split_at := raw_target.find(":")
		target_node = raw_target.left(split_at)
		target_path = raw_target.substr(split_at + 1)
	if target_node.is_empty() or not runtime.is_node_authenticated(target_node):
		return _result(false, "not_authenticated", "目标节点尚未登录或破解完成。")
	var normalized := _normalize_path(target_path if target_path.begins_with("/") else current_path.path_join(target_path))
	if not runtime.directory_exists(target_node, normalized):
		return _result(false, "directory_missing", "目录不存在。")
	current_node = target_node
	current_path = normalized
	return _result(true, "directory_changed", "%s:%s" % [current_node, current_path])

func _resolve_path(raw_path: String) -> String:
	if raw_path.begins_with("/"):
		return _normalize_path(raw_path)
	return _normalize_path(current_path.path_join(raw_path))

func _normalize_path(path: String) -> String:
	var parts: Array[String] = []
	for part in path.replace("\\", "/").split("/", false):
		if part == "." or part.is_empty():
			continue
		if part == "..":
			if not parts.is_empty():
				parts.pop_back()
		else:
			parts.append(part)
	return "/" + "/".join(parts)

func _required_arg(args: Array, index: int, fallback := "") -> String:
	if index < args.size():
		return String(args[index])
	return String(fallback)

func _help_index() -> String:
	var lines: Array[String] = ["ZERO-SHELL 本地命令手册"]
	for group in HELP_GROUPS:
		var commands: Array[String] = []
		for command in SUPPORTED_COMMANDS:
			var entry: Dictionary = COMMAND_HELP.get(command, {})
			if String(entry.get("group", "")) == group:
				commands.append(command)
		if not commands.is_empty():
			lines.append("\n[%s]" % group)
			lines.append("  " + "  ".join(commands))
	lines.append("\n输入 help <命令> 查看用途、语法和通用示例。")
	return "\n".join(lines)

func _help_for(command: String) -> String:
	var normalized := command.to_lower()
	if not COMMAND_HELP.has(normalized):
		var suggestion := _closest_command(normalized)
		if not suggestion.is_empty():
			return "本地手册中没有 %s。你是否想查看 help %s？" % [command, suggestion]
		return "本地手册中没有 %s。输入 help 查看命令索引。" % command
	var entry: Dictionary = COMMAND_HELP[normalized]
	return "%s\n用途：%s\n语法：%s\n何时使用：%s\n通用示例：%s" % [
		normalized.to_upper(),
		String(entry.get("purpose", "")),
		String(entry.get("syntax", "")),
		String(entry.get("when", "")),
		String(entry.get("example", ""))
	]

func _validate_required_arguments(command: String, parsed: Dictionary) -> String:
	var args: Array = parsed.get("args", [])
	if command in ["probe", "crack", "cat", "open", "get", "trace"] and _required_arg(args, 0).is_empty():
		return command
	if command == "login":
		var options: Dictionary = parsed.get("options", {})
		if _required_arg(args, 0).is_empty() or String(options.get("u", "")).is_empty() or String(options.get("p", "")).is_empty():
			return command
	return ""

func _missing_argument(command: String) -> Dictionary:
	var entry: Dictionary = COMMAND_HELP.get(command, {})
	return _result(false, "missing_argument", "参数不足。语法：%s\n输入 help %s 查看本地手册。" % [String(entry.get("syntax", command)), command])

func _execute_tutorial(args: Array) -> Dictionary:
	if tutorial_runtime == null:
		return _result(false, "tutorial_unavailable", "当前案件没有可同步的教学签名盒。输入 help <命令> 查看本地手册。")
	var action := _required_arg(args, 0).to_lower()
	match action:
		"skip":
			tutorial_runtime.skip()
			return _result(true, "tutorial_skipped", "教学签名盒已静音。案件进度、证据与三级提示保持不变。")
		"restart":
			tutorial_runtime.restart()
			return _result(true, "tutorial_restarted", "教学签名盒已按当前案件状态重新同步。输入 help tutorial 读取最近恢复的操作备忘。")
	return _result(false, "tutorial_usage", "用法：tutorial <skip|restart>。输入 help tutorial 查看当前操作备忘。")

func _closest_command(command: String) -> String:
	var closest := ""
	var best_score := 0.0
	for candidate in SUPPORTED_COMMANDS:
		var score := command.similarity(candidate)
		if score > best_score:
			best_score = score
			closest = candidate
	return closest if best_score >= 0.55 else ""

func _result(ok: bool, code: String, text: String) -> Dictionary:
	return {"ok": ok, "code": code, "text": text}

func parse(raw_text: String) -> Dictionary:
	var tokens := _tokenize(raw_text.strip_edges())
	if tokens.is_empty():
		return {"command": "", "args": [], "options": {}, "error": "请输入命令。"}
	var command := String(tokens.pop_front()).to_lower()
	var args: Array[String] = []
	var options := {}
	var index := 0
	while index < tokens.size():
		var token := String(tokens[index])
		if token.begins_with("-") and token.length() > 1:
			var key := token.trim_prefix("--").trim_prefix("-")
			if index + 1 >= tokens.size() or String(tokens[index + 1]).begins_with("-"):
				options[key] = true
			else:
				options[key] = String(tokens[index + 1])
				index += 1
		else:
			args.append(token)
		index += 1
	return {"command": command, "args": args, "options": options, "error": ""}

func _tokenize(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var current := ""
	var quote := ""
	for character in text:
		if quote.is_empty() and (character == "\"" or character == "'"):
			quote = character
		elif not quote.is_empty() and character == quote:
			quote = ""
		elif quote.is_empty() and character in [" ", "\t"]:
			if not current.is_empty():
				tokens.append(current)
				current = ""
		else:
			current += character
	if not current.is_empty():
		tokens.append(current)
	return tokens
