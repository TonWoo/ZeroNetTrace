extends "res://scripts/apps/app_window.gd"

signal report_completed(grade: String)

var runtime
var questions: Array = []
var question_rows: Array[Dictionary] = []
var status: Label
var finish_button: Button

func _build_body(parent: MarginContainer) -> void:
	app_id = "report"
	app_title = "结案报告"
	title_label.text = " %s" % app_title
	var scroll := ScrollContainer.new()
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	finish_button = Button.new()
	finish_button.text = "提交结案"
	finish_button.disabled = true
	finish_button.pressed.connect(_finish)
	column.add_child(finish_button)

func configure(runtime_ref, new_questions: Array) -> void:
	runtime = runtime_ref
	questions = new_questions
	_rebuild()

func _rebuild() -> void:
	question_rows.clear()
	var column := status.get_parent()
	for child in column.get_children():
		if child != status and child != finish_button:
			child.queue_free()
	column.move_child(finish_button, column.get_child_count() - 1)
	for question_value in questions:
		var question: Dictionary = question_value
		var panel := VBoxContainer.new()
		var prompt := Label.new()
		prompt.text = String(question.get("q", ""))
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(prompt)
		var options := OptionButton.new()
		for option_value in question.get("options", []):
			options.add_item(String(option_value))
		panel.add_child(options)
		var evidence := Label.new()
		evidence.text = "证据：%s" % " / ".join(question.get("evidence", []))
		evidence.add_theme_color_override("font_color", Color("#858d88"))
		panel.add_child(evidence)
		var submit := Button.new()
		submit.text = "确认本题"
		panel.add_child(submit)
		var feedback := Label.new()
		panel.add_child(feedback)
		submit.pressed.connect(_submit_question.bind(question, options, feedback))
		column.add_child(panel)
		column.move_child(panel, column.get_child_count() - 2)
		question_rows.append({"id": question.get("id", ""), "feedback": feedback})
	_update_status()

func _submit_question(question: Dictionary, options: OptionButton, feedback: Label) -> void:
	var result: Dictionary = runtime.submit_report_answer(String(question.get("id", "")), options.selected)
	feedback.text = String(result.get("text", ""))
	feedback.modulate = Color("#33ff66") if bool(result.get("correct", false)) else Color("#ff6b6b")
	_update_status()

func _update_status() -> void:
	if runtime == null:
		return
	var correct := 0
	for question_value in questions:
		var question: Dictionary = question_value
		if int(runtime.report_current_answers.get(question.get("id", ""), -99)) == int(question.get("answer", -1)):
			correct += 1
	status.text = "已确认正确：%d/%d　首答评级：%s" % [correct, questions.size(), runtime.get_report_grade()]
	finish_button.disabled = correct != questions.size()

func _finish() -> void:
	report_completed.emit(runtime.get_report_grade())

