extends Node3D
class_name EncounterDirector

@export var faction: Faction
@export var spawn_points: Array[NodePath] = []
@export var base_intensity: float = 0.2 # 0..1
@export var time_ramp: float = 0.015 # intensity per second
@export var noise_influence: float = 0.3
@export var max_active_enemies: int = 12
@export var spawn_interval: float = 4.0

var _intensity: float = 0.0
var _active: Array[Node] = []
var _timer := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_intensity = base_intensity
	if Engine.has_singleton("NoiseBus"):
		NoiseBus.noise_emitted.connect(_on_noise)
	# Listen for stage changes to ramp pressure
	if Engine.has_singleton("Mission"):
		Mission.stage_changed.connect(_on_stage_changed)

func _process(delta: float) -> void:
	_intensity = clamp(_intensity + time_ramp * delta, 0.0, 1.0)
	_timer += delta
	_clean_dead()
	if _timer >= spawn_interval:
		_timer = 0.0
		_try_spawn_wave()

func _on_noise(pos: Vector3, amount: float) -> void:
	var d := global_transform.origin.distance_to(pos)
	var effect = amount / max(1.0, d)
	_intensity = clamp(_intensity + effect * noise_influence, 0.0, 1.0)

func _on_stage_changed(stage_index: int, _total: int) -> void:
	# Simple ramp: deeper stages mean more pressure
	_intensity = clamp(base_intensity + 0.25 * float(stage_index), 0.0, 1.0)
	max_active_enemies = 8 + 6 * stage_index
	spawn_interval = max(1.5, 4.0 - 0.5 * float(stage_index))
	time_ramp = 0.015 + 0.01 * float(stage_index)

func _try_spawn_wave() -> void:
	if faction == null:
		return
	if _active.size() >= max_active_enemies:
		return
	var budget := 1 + int(round(_intensity * 4.0))
	var spawns = min(budget, max_active_enemies - _active.size())
	for i in spawns:
		var p := _pick_spawn_point()
		var enemy := _pick_enemy_scene()
		if p != null and enemy != null:
			var inst := (enemy as PackedScene).instantiate()
			get_tree().current_scene.add_child(inst)
			inst.global_transform.origin = p.global_transform.origin
			_active.append(inst)

func _pick_spawn_point() -> Node3D:
	if spawn_points.is_empty():
		var nodes := get_tree().get_nodes_in_group("spawn_point")
		return nodes[_rng.randi_range(0, nodes.size() - 1)] if nodes.size() > 0 else null
	var path := spawn_points[_rng.randi_range(0, spawn_points.size() - 1)]
	return get_node_or_null(path)

func _pick_enemy_scene() -> PackedScene:
	var scenes: Array = faction.spawn_table.values()
	if scenes.is_empty():
		return null
	return scenes[_rng.randi_range(0, scenes.size() - 1)]

func _clean_dead() -> void:
	_active = _active.filter(func(n): return is_instance_valid(n))
