extends Node

func _ready() -> void:
	Mission.mission_completed.connect(_on_mission_completed)
	Mission.mission_failed.connect(_on_mission_failed)

func _on_mission_completed(payout: int) -> void:
	var planet_id: StringName = Mission.meta.get("planet_id", &"")
	var contract_id: StringName = Mission.meta.get("contract_id", &"")
	Campaign.on_mission_completed(planet_id, contract_id, payout)
	Game.goto_hub()

func _on_mission_failed(reason: String) -> void:
	var planet_id: StringName = Mission.meta.get("planet_id", &"")
	var contract_id: StringName = Mission.meta.get("contract_id", &"")
	Campaign.on_mission_failed(planet_id, contract_id, reason)
	Game.goto_hub()
