extends CharacterBody3D

enum State { IDLE, PATROL, CHASE }

@export var move_speed: float = 3.5
@export var view_distance: float = 15.0
@export var view_fov_deg: float = 80.0
@export var lose_sight_time: float = 2.0
@export var waypoints: Array[NodePath] = []

@onready var agent: NavigationAgent3D = $NavigationAgent3D

var state: int = State.PATROL
var last_seen_time: float = -999.0
var current_wp := 0
var target: Node = null

func _ready() -> void:
	add_to_group("enemy")
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_update_target_visibility(delta)
	match state:
		State.PATROL:
			_do_patrol()
		State.CHASE:
			_do_chase()
		_:
			pass
	_move_with_agent(delta)

func _update_target_visibility(delta: float) -> void:
	if not is_instance_valid(target):
		target = _find_player()
	var can_see := _can_see_target(target)
	if can_see:
		last_seen_time = Time.get_ticks_msec() / 1000.0
		state = State.CHASE
	elif state == State.CHASE:
		var t := Time.get_ticks_msec() / 1000.0
		if t - last_seen_time > lose_sight_time:
			state = State.PATROL

func _find_player() -> Node:
	var players := get_tree().get_nodes_in_group("player")
	return players.front() if players.size() > 0 else null

func _can_see_target(t: Node) -> bool:
	if t == null:
		return false
	var to_vec := t.global_transform.origin - global_transform.origin
	if to_vec.length() > view_distance:
		return false
	var dir := -global_transform.basis.z
	var angle := rad_to_deg(acos(clamp(dir.normalized().dot(to_vec.normalized()), -1.0, 1.0)))
	if angle > view_fov_deg * 0.5:
		return false
	# Raycast for line-of-sight
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(global_transform.origin + Vector3.UP * 1.5, t.global_transform.origin + Vector3.UP * 1.5)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return false
	return hit.get("collider") == t

func _do_patrol() -> void:
	if waypoints.is_empty():
		return
	var wp_node := get_node_or_null(waypoints[current_wp])
	if wp_node == null:
		return
	agent.target_position = wp_node.global_transform.origin
	if (global_transform.origin.distance_to(agent.target_position) < 1.0):
		current_wp = (current_wp + 1) % waypoints.size()

func _do_chase() -> void:
	if target == null:
		return
	agent.target_position = target.global_transform.origin

func _move_with_agent(delta: float) -> void:
	if agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
	else:
		var next_pos := agent.get_next_path_position()
		var dir := (next_pos - global_transform.origin).normalized()
		var desired := dir * move_speed
		velocity.x = desired.x
		velocity.z = desired.z
		# Gravity
		if not is_on_floor():
			velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()
