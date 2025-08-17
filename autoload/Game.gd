extends Node
class_name Game

signal game_state_changed(state: int)
signal paused_changed(paused: bool)

enum GameState { HUB, MISSION, PAUSED }

var current_state: int = GameState.HUB setget _set_state
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func _set_state(s: int) -> void:
	current_state = s
	emit_signal("game_state_changed", s)

func goto_hub() -> void:
	_set_state(GameState.HUB)

func start_mission(mission_def: Dictionary = {}) -> void:
	_set_state(GameState.MISSION)
	Mission.start_mission(mission_def)

func set_paused(p: bool) -> void:
	get_tree().paused = p
	emit_signal("paused_changed", p)
