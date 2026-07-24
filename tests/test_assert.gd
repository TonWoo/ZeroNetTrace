class_name TestAssert
extends RefCounted

var failures: Array[String] = []
var assertions := 0

func equal(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func truthy(value: Variant, message: String) -> void:
	assertions += 1
	if not bool(value):
		failures.append(message)

func contains_text(haystack: String, needle: String, message: String) -> void:
	assertions += 1
	if haystack.find(needle) < 0:
		failures.append("%s | missing=%s" % [message, needle])

