extends Node

@export var hub_scene_path := "res://hub/Hub.tscn"
@export var mission_scene_path := "res://world/TestOutpost.tscn"
@export var hud_scene_path := "res://ui/HUD.tscn"

var _current_world: Node = null
var _hud: Control = null

func _ready() -> void:
	Game.game_state_changed.connect(_on_game_state_changed)
	_load_hub()

func _clear_world() -> void:
	if is_instance_valid(_current_world):
		_current_world.queue_free()
		_current_world = null
	if is_instance_valid(_hud):
		_hud.queue_free()
		_hud = null

func _load_hub() -> void:
	_clear_world()
	if ResourceLoader.exists(hub_scene_path):
		var hub := load(hub_scene_path).instantiate()
		add_child(hub)
		_current_world = hub
	else:
		push_warning("Hub scene not found: %s" % hub_scene_path)

func _load_mission() -> void:
	_clear_world()
	if ResourceLoader.exists(mission_scene_path):
		var world := load(mission_scene_path).instantiate()
		add_child(world)
		_current_world = world
		# HUD
		if ResourceLoader.exists(hud_scene_path):
			_hud = load(hud_scene_path).instantiate()
			add_child(_hud)
		else:
			push_warning("HUD scene not found: %s" % hud_scene_path)
	else:
		push_warning("Mission scene not found: %s" % mission_scene_path)

func _on_game_state_changed(state: int) -> void:
	match state:
		Game.GameState.HUB:
			_load_hub()
		Game.GameState.MISSION:
			_load_mission()
