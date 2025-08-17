extends Node

signal campaign_updated
signal contracts_updated(planet_id: StringName, contracts: Array)

var planets: Array[Planet] = []
var active_planet_id: StringName
var available_contracts: Dictionary = {}
var company_profit_pool: int = 0

func _ready() -> void:
	_init_default_campaign()
	_roll_contracts_for_all()
	emit_signal("campaign_updated")

func _init_default_campaign() -> void:
	var bugs := Faction.new()
	bugs.id = &"bugs"
	bugs.display_name = "Xeno Hive"
	bugs.aggression = 0.6
	bugs.tech_level = 0.2
	bugs.spawn_table = {}
	var p := Planet.new()
	p.id = &"morrow"
	p.display_name = "Morrow"
	p.seed = randi()
	p.liberation = 0.12
	p.heat = 0.35
	p.faction = bugs
	p.biomes = [&"arid", &"basalt"]
	planets = [p]
	active_planet_id = p.id

func get_planets() -> Array[Planet]:
	return planets

func get_planet(planet_id: StringName) -> Planet:
	for p in planets:
		if p.id == planet_id:
			return p
	return null

func _roll_contracts_for_all() -> void:
	for p in planets:
		available_contracts[p.id] = _roll_contracts_for_planet(p)
	emit_signal("contracts_updated", active_planet_id, available_contracts.get(active_planet_id, []))

func _roll_contracts_for_planet(p: Planet) -> Array[Contract]:
	var arr: Array[Contract] = []
	var c1 := Contract.new()
	c1.id = &"salvage_basic"
	c1.type = Contract.Type.SALVAGE
	c1.title = "Recover Corporate Assets"
	c1.description = "Collect assets and deliver to multiple extractors."
	c1.target_value = 3000
	c1.reward_base = 250
	c1.risk_mult = 1.0
	arr.append(c1)
	var c2 := Contract.new()
	c2.id = &"uplink_basic"
	c2.type = Contract.Type.UPLINK
	c2.title = "Deploy Uplink Beacon"
	c2.description = "Power up and defend a beacon until upload completes."
	c2.target_value = 1
	c2.reward_base = 300
	c2.risk_mult = 1.2
	arr.append(c2)
	return arr

func get_contracts_for(planet_id: StringName) -> Array[Contract]:
	return available_contracts.get(planet_id, [])

func select_planet(planet_id: StringName) -> void:
	active_planet_id = planet_id
	emit_signal("contracts_updated", planet_id, available_contracts.get(planet_id, []))
	emit_signal("campaign_updated")

func start_contract(planet_id: StringName, contract: Contract) -> void:
	var p := get_planet(planet_id)
	if p == null:
		push_warning("Planet not found: %s" % [planet_id])
		return
	var mission_def := {
		"planet_id": planet_id,
		"contract_id": String(contract.id),
		"contract_type": contract.type,
		"required_session_credits": contract.target_value,
		"reward_base": contract.reward_base,
		"risk_mult": contract.risk_mult,
		"planet_seed": p.seed,
		"faction_id": String(p.faction.id),
		"heat": p.heat
	}
	# Inject a REPO chain for salvage contracts
	if contract.type == Contract.Type.SALVAGE:
		mission_def["repo_chain"] = [
			{"title": "Stage 1 — Surface Depot", "quota": 3000, "extractor": "alpha", "difficulty_bump": 0.2},
			{"title": "Stage 2 — Deep Outpost", "quota": 7000, "extractor": "beta", "difficulty_bump": 0.35}
		]
	Game.start_mission(mission_def)

func on_mission_completed(planet_id: StringName, _contract_id: StringName, payout: int) -> void:
	var p := get_planet(planet_id)
	if p == null:
		return
	var lib_gain := clamp(float(payout) / 2000.0, 0.01, 0.08)
	p.liberation = clamp(p.liberation + lib_gain, 0.0, 1.0)
	p.heat = clamp(p.heat - 0.05, 0.0, 1.0)
	company_profit_pool += int(payout * 0.25)
	_roll_contracts_for_all()
	emit_signal("campaign_updated")

func on_mission_failed(planet_id: StringName, _contract_id: StringName, _reason: String) -> void:
	var p := get_planet(planet_id)
	if p == null:
		return
	p.heat = clamp(p.heat + 0.07, 0.0, 1.0)
	emit_signal("campaign_updated")
