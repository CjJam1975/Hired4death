extends Node

signal objective_updated(text: String)
signal mission_completed(payout: int) # payout for THIS mission
signal mission_failed(reason: String)
signal stage_changed(stage_index: int, total_stages: int)

var active: bool = false
var extracted: bool = false

# Single-stage fallback
var required_session_credits: int = 200

# R.E.P.O.
var stages: Array[RepoStage] = []
var current_stage_index: int = -1
var mission_bank: int = 0 # credits delivered to extractors across stages

# Context for campaign bridge
var meta: Dictionary = {} # planet_id, contract_id, contract_type, etc.

func start_mission(def: Dictionary) -> void:
	active = true
	extracted = false
	meta = def.duplicate(true)
	mission_bank = 0
	Economy.reset_session()
	_build_stages_from_def(def)
	# Fallback for old style single-stage missions
	if stages.is_empty():
		required_session_credits = int(def.get("required_session_credits", 200))
		var s := RepoStage.new()
		s.title = "Delivery"
		s.quota = required_session_credits
		s.extractor_tag = &"any"
		s.difficulty_bump = 0.2
		stages = [s]
	current_stage_index = 0
	emit_signal("stage_changed", current_stage_index, stages.size())
	_update_objective()

func _build_stages_from_def(def: Dictionary) -> void:
	stages.clear()
	if def.has("repo_chain") and def["repo_chain"] is Array:
		for i in def["repo_chain"]:
			if i is Dictionary:
				var s := RepoStage.new()
				s.title = str(i.get("title", "Stage %d" % (stages.size() + 1)))
				s.quota = int(i.get("quota", 0))
				s.extractor_tag = StringName(str(i.get("extractor", "any")))
				s.difficulty_bump = float(i.get("difficulty_bump", 0.25))
				stages.append(s)

func on_session_credits_changed(_new_value: int) -> void:
	if not active:
		return
	_update_objective()

func try_extract() -> void:
	# Backwards compatibility: treat as "any" extractor
	try_stage_extract(&"any")

func try_stage_extract(extractor_tag: StringName) -> void:
	if not active:
		return
	if current_stage_index < 0 or current_stage_index >= stages.size():
		return
	var st := stages[current_stage_index]
	if st.extractor_tag != &"any" and st.extractor_tag != extractor_tag:
		emit_signal("mission_failed", "Wrong extractor. Deliver to: %s" % [String(st.extractor_tag)])
		return
	if Economy.session_credits < st.quota:
		emit_signal("mission_failed", "Insufficient credits to deliver (need %d)" % st.quota)
		return
	# Deliver quota to bank and advance
	Economy.deposit_session(st.quota)
	mission_bank += st.quota

	if current_stage_index < stages.size() - 1:
		current_stage_index += 1
		emit_signal("stage_changed", current_stage_index, stages.size())
		_update_objective()
	else:
		# Final delivery completes the mission. Commit bank + remaining carried credits.
		var payout := mission_bank + Economy.session_credits
		Economy.total_credits += mission_bank
		Economy.commit_session_to_total()
		mission_bank = 0
		active = false
		extracted = true
		emit_signal("mission_completed", payout)

func abort_mission(reason: String = "Aborted") -> void:
	if not active:
		return
	active = false
	mission_bank = 0
	Economy.reset_session()
	emit_signal("mission_failed", reason)

func _update_objective() -> void:
	if stages.is_empty():
		var s = "Collect credits: %d / %d. Extract to complete." % [Economy.session_credits, required_session_credits]
		emit_signal("objective_updated", s)
		return
	var idx := current_stage_index + 1
	var total := stages.size()
	var st := stages[current_stage_index]
	var text := "%s (%d/%d)\nDeliver: $%d to Extractor [%s]\nCarried: $%d • Banked: $%d" % [
		st.title, idx, total, st.quota, String(st.extractor_tag),
		Economy.session_credits, mission_bank
	]
	emit_signal("objective_updated", text)
