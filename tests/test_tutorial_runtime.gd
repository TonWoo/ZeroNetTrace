extends RefCounted

const TutorialRuntimeScript = preload("res://scripts/engine/tutorial_runtime.gd")

func run(t) -> void:
	var case_data := {
		"caseId": "tutorial_test",
		"tutorialMessages": [
			{"id": "msg_mail", "sender": "离线签名盒", "text": "先核对附件。"},
			{"id": "msg_scan", "sender": "ZERO-SHELL", "text": "未知防护状态需先识别。"},
			{"id": "msg_nudge", "sender": "ZERO-SHELL", "text": "先读原始邮件。"}
		],
		"tutorialFlow": {
			"enabled": true,
			"steps": [
				{"id": "read_mail", "completeWhen": {"type": "mail_opened", "target": "mail_primary"}, "delivery": [{"contentId": "msg_mail", "channel": "messenger"}], "feedback": {"appId": "mail", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 75, "contentId": "msg_nudge", "channel": "messenger"}, "helpText": "先核对死者留下的原始邮件。"},
				{"id": "search", "completeWhen": {"type": "gate_resolved", "target": "gate_a"}, "delivery": [{"contentId": "msg_scan", "channel": "terminal"}], "feedback": {"appId": "browser", "pulse": "soft", "sound": "progress_soft"}, "helpText": "把两段已知信息放进同一次检索。"},
				{"id": "probe", "completeWhen": {"type": "command_succeeded", "target": "probe", "where": {"addr": "node.test"}}, "delivery": [], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "helpText": "先识别节点防护。"}
			],
			"milestones": [
				{"id": "first_answer", "when": {"type": "report_answered", "target": "q1"}, "feedback": {"appId": "report", "pulse": "soft", "sound": "progress_soft"}}
			]
		}
	}
	var tutorial = TutorialRuntimeScript.new()
	tutorial.configure(case_data)
	t.equal(tutorial.get_current_step_id(), "read_mail", "tutorial starts at the first unsatisfied step")
	var first: Array = tutorial.observe("mail_opened", "mail_primary")
	t.equal(first.size(), 1, "matching current action advances exactly one step")
	t.equal(tutorial.get_current_step_id(), "search", "tutorial moves to the next step")
	t.equal(tutorial.observe("mail_opened", "mail_primary").size(), 0, "repeated actions are idempotent")
	t.equal(tutorial.observe("gate_resolved", "gate_a").size(), 1, "recorded gate action advances the search step")
	t.equal(tutorial.observe("command_succeeded", "probe", {"addr": "wrong.test"}).size(), 0, "metadata filters reject the wrong node")
	t.equal(tutorial.observe("command_succeeded", "probe", {"addr": "node.test"}).size(), 1, "metadata filters accept the required node")
	t.truthy(tutorial.is_complete(), "all steps complete the tutorial")
	var saved: Dictionary = tutorial.to_save_data()
	var restored = TutorialRuntimeScript.new()
	restored.configure(case_data, saved)
	t.truthy(restored.is_complete(), "completed tutorial state survives save restore")
	restored.restart([{"type": "mail_opened", "target": "mail_primary"}])
	t.equal(restored.get_current_step_id(), "search", "restart skips facts already satisfied by current case state")
	restored.skip()
	t.truthy(restored.is_skipped(), "skip disables tutorial progression")
	var future = TutorialRuntimeScript.new()
	future.configure(case_data)
	t.equal(future.observe("gate_resolved", "gate_a").size(), 0, "future facts do not bypass the active step immediately")
	future.observe("mail_opened", "mail_primary")
	t.equal(future.get_current_step_id(), "probe", "a recorded future fact is silently skipped after the active step completes")
	var compound_case := {
		"caseId": "compound_tutorial",
		"tutorialFlow": {
			"enabled": true,
			"steps": [{
				"id": "collect_three_facts",
				"completeWhen": {"allOf": [
					{"type": "command_succeeded", "target": "ls"},
					{"anyOf": [
						{"type": "file_opened", "target": "/archive/a.log"},
						{"type": "file_opened", "target": "/archive/b.log"}
					]},
					{"type": "evidence_collected", "target": "ev_log"}
				]},
				"delivery": [],
				"feedback": {},
				"helpText": "先核对原文，再保留证据。"
			}]
		}
	}
	var compound = TutorialRuntimeScript.new()
	compound.configure(compound_case)
	t.equal(compound.observe("command_succeeded", "ls").size(), 0, "allOf waits for every required fact")
	t.equal(compound.observe("file_opened", "/archive/b.log").size(), 0, "anyOf accepts a valid branch without bypassing remaining facts")
	t.equal(compound.observe("evidence_collected", "ev_log").size(), 1, "allOf advances after an anyOf branch and every other fact are satisfied")
	var nudge_runtime = TutorialRuntimeScript.new()
	nudge_runtime.configure(case_data)
	var nudges: Array = []
	var feedbacks: Array = []
	nudge_runtime.nudge_requested.connect(func(delivery): nudges.append(delivery))
	nudge_runtime.feedback_requested.connect(func(app_id, style, sound): feedbacks.append([app_id, style, sound]))
	nudge_runtime.tick(74.0)
	t.equal(nudges.size(), 0, "tutorial fallback waits for its threshold")
	nudge_runtime.tick(1.0)
	t.equal(nudges.size(), 1, "tutorial fallback emits once at its threshold")
	nudge_runtime.tick(90.0)
	t.equal(nudges.size(), 1, "tutorial fallback is idempotent")
	nudge_runtime.observe("report_answered", "q1")
	nudge_runtime.observe("report_answered", "q1")
	t.equal(feedbacks.size(), 1, "tutorial milestones request feedback once without advancing the step")
