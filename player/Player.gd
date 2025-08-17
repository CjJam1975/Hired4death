extends CharacterBody3D

@export var move_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 5.5
@export var mouse_sens: float = 0.08
@export var interact_distance: float = 3.0

@onready var cam_pivot: Node3D = $CamPivot
@onready var camera: Camera3D = $CamPivot/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_pitch := 0.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotate_look(event.relative)
	elif event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	var wish_dir := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_speed := (Input.is_action_pressed("sprint")) ? sprint_speed : move_speed
	var target_vel := wish_dir * target_speed

	velocity.x = lerp(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_vel.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

func _rotate_look(rel: Vector2) -> void:
	rotation_degrees.y -= rel.x * mouse_sens
	look_pitch = clamp(look_pitch - rel.y * mouse_sens, -85.0, 85.0)
	cam_pivot.rotation_degrees.x = look_pitch

func _try_interact() -> void:
	var space_state := get_world_3d().direct_space_state
	var from := camera.global_transform.origin
	var to := from + camera.global_transform.basis.z * -interact_distance
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result := space_state.intersect_ray(params)
	if result.size() > 0:
		var collider := result.get("collider")
		if collider and collider.is_in_group("interactable") and collider.has_method("interact"):
			collider.interact(self)
