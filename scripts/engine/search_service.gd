class_name SearchService
extends RefCounted

const REMOVED_CHARACTERS := " \t\r\n，。！？、；：‘’“”（）【】《》〈〉…—·,.!?;:'\"()[]{}<>_-+="

func normalize(value: String) -> String:
	var folded := ""
	for character in value:
		var code := character.unicode_at(0)
		if code == 0x3000:
			folded += " "
		elif code >= 0xFF01 and code <= 0xFF5E:
			folded += String.chr(code - 0xFEE0)
		else:
			folded += character
	folded = folded.to_lower()
	var result := ""
	for character in folded:
		if REMOVED_CHARACTERS.find(character) < 0:
			result += character
	return result

func matches_gate(query: String, gate: Dictionary) -> bool:
	var normalized_query := normalize(query)
	if normalized_query.is_empty():
		return false
	var terms: Array = gate.get("accept", []) + gate.get("aliases", [])
	for term_value in terms:
		if term_value is Dictionary:
			continue
		var term := normalize(String(term_value))
		if not term.is_empty() and normalized_query.contains(term):
			return true
	return false

func matching_gates(query: String, gates: Array) -> Array:
	var matches: Array = []
	for gate_value in gates:
		var gate: Dictionary = gate_value
		if String(gate.get("channel", "search")) == "search" and matches_gate(query, gate):
			matches.append(gate)
	return matches

