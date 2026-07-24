class_name TutorialRuntime
extends RefCounted

signal step_advanced(step: Dictionary, deliveries: Array)
signal feedback_requested(app_id: String, style: String, sound: String)
signal nudge_requested(delivery: Dictionary)

var case_id := ""
var messages: Dictionary = {}
var steps: Array = []
var milestones: Array = []
var current_index := 0
var completed_steps: Dictionary = {}
var completed_milestones: Dictionary = {}
var consumed_messages: Dictionary = {}
var consumed_fallbacks: Dictionary = {}
var observed_facts: Dictionary = {}
var current_step_elapsed := 0.0
var skipped := false

var _enabled := false
var _initial_facts: Array = []

func configure(case_data: Dictionary, saved_state: Dictionary = {}, reconstruction_facts: Array = []) -> void:
	case_id = String(case_data.get("caseId", ""))
	messages.clear()
	for message in case_data.get("tutorialMessages", []):
		if message is Dictionary:
			var message_id := String(message.get("id", ""))
			if not message_id.is_empty():
				messages[message_id] = message.duplicate(true)
	var flow: Dictionary = case_data.get("tutorialFlow", {})
	_enabled = bool(flow.get("enabled", false))
	steps = flow.get("steps", []).duplicate(true)
	milestones = flow.get("milestones", []).duplicate(true)
	_initial_facts = reconstruction_facts.duplicate(true)
	_reset_state()
	_apply_save_data(saved_state)
	for fact in reconstruction_facts:
		_record_fact_dictionary(fact)
	_recompute_current_index()
	_silently_advance_satisfied_steps()

func observe(action_type: String, target: String = "", metadata: Dictionary = {}) -> Array:
	var fact := {"type": action_type, "target": target, "metadata": metadata.duplicate(true)}
	_record_fact_dictionary(fact)
	var advances: Array = []
	if not _enabled or skipped:
		return advances
	var feedback_emitted := false
	if not is_complete():
		var step: Dictionary = steps[current_index]
		if _condition_satisfied(step.get("completeWhen", {})):
			var step_id := String(step.get("id", ""))
			completed_steps[step_id] = true
			current_index += 1
			current_step_elapsed = 0.0
			var deliveries := _collect_unconsumed_deliveries(step.get("delivery", []))
			advances.append(step.duplicate(true))
			step_advanced.emit(step.duplicate(true), deliveries)
			feedback_emitted = _request_feedback(step.get("feedback", {}), false)
			_silently_advance_satisfied_steps()
	for milestone in milestones:
		if not milestone is Dictionary:
			continue
		var milestone_id := String(milestone.get("id", ""))
		if milestone_id.is_empty() or completed_milestones.has(milestone_id):
			continue
		if _condition_satisfied(milestone.get("when", {})):
			completed_milestones[milestone_id] = true
			if not feedback_emitted:
				feedback_emitted = _request_feedback(milestone.get("feedback", {}), false)
	return advances

func tick(delta: float) -> void:
	if not _enabled or skipped or is_complete():
		return
	current_step_elapsed += maxf(delta, 0.0)
	var step: Dictionary = steps[current_index]
	var fallback: Dictionary = step.get("fallback", {})
	if fallback.is_empty():
		return
	var step_id := String(step.get("id", ""))
	if consumed_fallbacks.has(step_id):
		return
	if current_step_elapsed < float(fallback.get("afterSec", INF)):
		return
	consumed_fallbacks[step_id] = true
	var delivery := fallback.duplicate(true)
	var content_id := String(delivery.get("contentId", ""))
	if not content_id.is_empty():
		consumed_messages[content_id] = true
	nudge_requested.emit(delivery)

func get_current_step_id() -> String:
	if not _enabled or current_index >= steps.size():
		return ""
	return String(steps[current_index].get("id", ""))

func get_help_text() -> String:
	if not _enabled:
		return "当前案件没有可恢复的教学备忘。输入 help <命令> 查看本地手册。"
	if skipped:
		return "教学投递已暂停。输入 tutorial restart 可按当前案件状态重新同步。"
	if is_complete():
		return "教学签名盒已封存。输入 help <命令> 继续使用 ZERO-SHELL 本地手册。"
	return String(steps[current_index].get("helpText", "先核对当前已经取得的原始内容。"))

func is_complete() -> bool:
	return not _enabled or current_index >= steps.size()

func is_skipped() -> bool:
	return skipped

func skip() -> void:
	skipped = true

func restart(reconstruction_facts: Array = []) -> void:
	var facts: Array = []
	if not reconstruction_facts.is_empty():
		facts = reconstruction_facts.duplicate(true)
		_initial_facts = facts.duplicate(true)
	else:
		facts = _initial_facts.duplicate(true)
		for fact in observed_facts.values():
			facts.append(fact.duplicate(true))
	_reset_state()
	for fact in facts:
		_record_fact_dictionary(fact)
	_silently_advance_satisfied_steps()

func to_save_data() -> Dictionary:
	var facts: Array = []
	for fact in observed_facts.values():
		facts.append(fact.duplicate(true))
	return {
		"caseId": case_id,
		"currentIndex": current_index,
		"completedSteps": completed_steps.keys(),
		"completedMilestones": completed_milestones.keys(),
		"consumedMessages": consumed_messages.keys(),
		"consumedFallbacks": consumed_fallbacks.keys(),
		"observedFacts": facts,
		"currentStepElapsed": current_step_elapsed,
		"skipped": skipped
	}

func _reset_state() -> void:
	current_index = 0
	completed_steps.clear()
	completed_milestones.clear()
	consumed_messages.clear()
	consumed_fallbacks.clear()
	observed_facts.clear()
	current_step_elapsed = 0.0
	skipped = false

func _apply_save_data(saved_state: Dictionary) -> void:
	if saved_state.is_empty():
		return
	var saved_case_id := String(saved_state.get("caseId", case_id))
	if not saved_case_id.is_empty() and saved_case_id != case_id:
		return
	for step_id in saved_state.get("completedSteps", []):
		completed_steps[String(step_id)] = true
	for milestone_id in saved_state.get("completedMilestones", []):
		completed_milestones[String(milestone_id)] = true
	for content_id in saved_state.get("consumedMessages", []):
		consumed_messages[String(content_id)] = true
	for fallback_id in saved_state.get("consumedFallbacks", []):
		consumed_fallbacks[String(fallback_id)] = true
	for fact in saved_state.get("observedFacts", []):
		_record_fact_dictionary(fact)
	current_index = maxi(int(saved_state.get("currentIndex", 0)), 0)
	current_step_elapsed = maxf(float(saved_state.get("currentStepElapsed", 0.0)), 0.0)
	skipped = bool(saved_state.get("skipped", false))

func _recompute_current_index() -> void:
	current_index = clampi(current_index, 0, steps.size())
	while current_index < steps.size():
		var step_id := String(steps[current_index].get("id", ""))
		if not completed_steps.has(step_id):
			break
		current_index += 1

func _silently_advance_satisfied_steps() -> void:
	while current_index < steps.size():
		var step: Dictionary = steps[current_index]
		if not _condition_satisfied(step.get("completeWhen", {})):
			break
		completed_steps[String(step.get("id", ""))] = true
		current_index += 1
		current_step_elapsed = 0.0

func _condition_satisfied(condition) -> bool:
	if not condition is Dictionary or condition.is_empty():
		return false
	if condition.has("allOf"):
		var all_conditions: Array = condition.get("allOf", [])
		if all_conditions.is_empty():
			return false
		for child in all_conditions:
			if not _condition_satisfied(child):
				return false
		return true
	if condition.has("anyOf"):
		var any_conditions: Array = condition.get("anyOf", [])
		for child in any_conditions:
			if _condition_satisfied(child):
				return true
		return false
	for fact in observed_facts.values():
		if _fact_matches_condition(fact, condition):
			return true
	return false

func _fact_matches_condition(fact: Dictionary, condition: Dictionary) -> bool:
	if String(fact.get("type", "")) != String(condition.get("type", "")):
		return false
	var required_target := String(condition.get("target", ""))
	if not required_target.is_empty() and String(fact.get("target", "")) != required_target:
		return false
	var metadata: Dictionary = fact.get("metadata", {})
	var where: Dictionary = condition.get("where", {})
	for key in where:
		if not metadata.has(key) or metadata[key] != where[key]:
			return false
	return true

func _record_fact_dictionary(fact) -> void:
	if not fact is Dictionary:
		return
	var normalized := {
		"type": String(fact.get("type", "")),
		"target": String(fact.get("target", "")),
		"metadata": Dictionary(fact.get("metadata", {})).duplicate(true)
	}
	if normalized["type"].is_empty():
		return
	observed_facts[_fact_key(normalized)] = normalized

func _fact_key(fact: Dictionary) -> String:
	var metadata: Dictionary = fact.get("metadata", {})
	var keys: Array = metadata.keys()
	keys.sort_custom(func(a, b): return String(a) < String(b))
	var canonical_metadata := {}
	for key in keys:
		canonical_metadata[key] = metadata[key]
	return "%s|%s|%s" % [fact.get("type", ""), fact.get("target", ""), JSON.stringify(canonical_metadata)]

func _collect_unconsumed_deliveries(raw_deliveries) -> Array:
	var deliveries: Array = []
	if not raw_deliveries is Array:
		return deliveries
	for raw_delivery in raw_deliveries:
		if not raw_delivery is Dictionary:
			continue
		var content_id := String(raw_delivery.get("contentId", ""))
		if not content_id.is_empty() and consumed_messages.has(content_id):
			continue
		if not content_id.is_empty():
			consumed_messages[content_id] = true
		deliveries.append(raw_delivery.duplicate(true))
	return deliveries

func _request_feedback(raw_feedback, already_emitted: bool) -> bool:
	if already_emitted or not raw_feedback is Dictionary or raw_feedback.is_empty():
		return already_emitted
	feedback_requested.emit(
		String(raw_feedback.get("appId", "")),
		String(raw_feedback.get("pulse", "soft")),
		String(raw_feedback.get("sound", ""))
	)
	return true
