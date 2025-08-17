extends Node
class_name Economy

signal credits_changed(total: int, session: int)

var total_credits: int = 0
var session_credits: int = 0

func add_credits(amount: int) -> void:
	if amount <= 0:
		return
	session_credits += amount
	emit_signal("credits_changed", total_credits, session_credits)
	Mission.on_session_credits_changed(session_credits)

func spend(amount: int) -> bool:
	if total_credits >= amount:
		total_credits -= amount
		emit_signal("credits_changed", total_credits, session_credits)
		return true
	return false

func commit_session_to_total() -> void:
	total_credits += session_credits
	session_credits = 0
	emit_signal("credits_changed", total_credits, session_credits)

func reset_session() -> void:
	session_credits = 0
	emit_signal("credits_changed", total_credits, session_credits)

# NEW: deposit carried session credits when delivering to a stage extractor
func deposit_session(amount: int) -> void:
	if amount <= 0:
		return
	session_credits = max(0, session_credits - amount)
	emit_signal("credits_changed", total_credits, session_credits)
