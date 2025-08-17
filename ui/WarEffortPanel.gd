extends Control

@onready var list: ItemList = $VBoxContainer/ItemList
@onready var contract_list: ItemList = $VBoxContainer/Contracts
@onready var start_button: Button = $VBoxContainer/Start

var selected_planet: StringName
var selected_contract: Contract = null

func _ready() -> void:
	Campaign.campaign_updated.connect(_refresh)
	Campaign.contracts_updated.connect(_refresh_contracts)
	_populate_planets()
	start_button.pressed.connect(_on_start_pressed)
	list.item_selected.connect(_on_planet_selected)
	contract_list.item_selected.connect(_on_contract_selected)

func _populate_planets() -> void:
	list.clear()
	for p in Campaign.get_planets():
		var pct := int(round(p.liberation * 100.0))
		list.add_item("%s — Liberation %d%% — Heat %.2f" % [p.display_name, pct, p.heat])
	selected_planet = Campaign.active_planet_id

func _refresh() -> void:
	_populate_planets()
	_refresh_contracts(Campaign.active_planet_id, Campaign.get_contracts_for(Campaign.active_planet_id))

func _refresh_contracts(planet_id: StringName, contracts: Array) -> void:
	if planet_id != selected_planet:
		return
	contract_list.clear()
	for c in contracts:
		contract_list.add_item("%s — Reward %d" % [c.title, c.reward_base])

func _on_planet_selected(idx: int) -> void:
	var ps := Campaign.get_planets()
	if idx >= 0 and idx < ps.size():
		selected_planet = ps[idx].id
		Campaign.select_planet(selected_planet)

func _on_contract_selected(idx: int) -> void:
	var arr := Campaign.get_contracts_for(selected_planet)
	if idx >= 0 and idx < arr.size():
		selected_contract = arr[idx]

func _on_start_pressed() -> void:
	if selected_contract == null:
		return
	Campaign.start_contract(selected_planet, selected_contract)
