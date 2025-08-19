extends CharacterBody3D

@export var move_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var crouch_speed: float = 3.0 # movement speed while crouched
@export var acceleration: float = 12.0
@export var jump_velocity: float = 5.5
@export var mouse_sens: float = 0.05
@export var interact_distance: float = 3.0
@export var crouch_height: float = 0.8 # collider height when crouched

@onready var cam_pivot: Node3D = $CamPivot
@onready var camera: Camera3D = $CamPivot/Camera3D

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var look_pitch: float = 0.0

# Added crouch to action list with default as KEY_CTRL
const ACTIONS := {
	"ui_up": [KEY_W,],
	"ui_down": [KEY_S,],
	"ui_left": [KEY_A,],
	"ui_right": [KEY_D,],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E],
	"crouch": [KEY_CTRL], # Added crouch action
}

var _hud: Control = null

# Crouch state
var _is_crouching: bool = false
var _original_height: float = 1.6

func _ready() -> void:
	_setup_default_keybinds()
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_print_current_keybinds()
	_hud = get_tree().get_first_node_in_group("HUD")
	# Cache collider height for crouch toggle
	var collider = $CollisionShape3D
	if collider and collider.shape is CapsuleShape3D:
		_original_height = collider.shape.height

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotate_look(event.relative)

func _physics_process(delta: float) -> void:
	# Crouch input check
	var was_crouching = _is_crouching
	_is_crouching = Input.is_action_pressed("crouch")
	if _is_crouching != was_crouching:
		_update_crouch_state(_is_crouching) # Toggle collider height

	var input_dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var wish_dir := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# Use crouch, sprint, or walk speed as appropriate
	var target_speed: float = (
		crouch_speed if _is_crouching else sprint_speed if Input.is_action_pressed("sprint") else move_speed
	)
	var target_vel: Vector3 = wish_dir * target_speed
	velocity.x = lerp(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_vel.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	move_and_slide()
	_update_interact_prompt()
	# Debug: show when interact is attempted
	if Input.is_action_just_pressed("interact"):
		print_debug("[Interact Debug] Interact key pressed.")
		_try_interact()

func _rotate_look(rel: Vector2) -> void:
	rotation_degrees.y -= rel.x * mouse_sens
	look_pitch = clamp(look_pitch - rel.y * mouse_sens, -85.0, 85.0)
	cam_pivot.rotation_degrees.x = look_pitch

func _try_interact() -> void:
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.global_transform.origin
	var to: Vector3 = from + camera.global_transform.basis.z * -interact_distance
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result := space_state.intersect_ray(params)
	if result.size() > 0:
		var collider = result.get("collider")
		var interactable = collider
		# If collider isn't interactable, check its parent (for Area3D -> LootPickup)
		if not (collider.is_in_group("interactable") and collider.has_method("interact")) and collider.get_parent():
			if collider.get_parent().is_in_group("interactable") and collider.get_parent().has_method("interact"):
				interactable = collider.get_parent()
		if interactable.is_in_group("interactable") and interactable.has_method("interact"):
			print_debug("[Interact Debug] Interacting with: ", interactable.name, " (", interactable, ")")
			interactable.interact(self)
		else:
			print_debug("[Interact Debug] Ray hit non-interactable (on interact): ", collider.name, " (", collider, ")")


func _update_interact_prompt() -> void:
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.global_transform.origin
	var to: Vector3 = from + camera.global_transform.basis.z * -interact_distance
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result := space_state.intersect_ray(params)
	if result.size() > 0:
		var collider = result.get("collider")
		var interactable = collider
		# If collider isn't interactable, check its parent (Area3D -> LootPickup)
		if not (collider.is_in_group("interactable") and "prompt" in collider) and collider.get_parent():
			if collider.get_parent().is_in_group("interactable") and "prompt" in collider.get_parent():
				interactable = collider.get_parent()
		if interactable.is_in_group("interactable") and "prompt" in interactable:
			print_debug("[Interact Debug] Looking at interactable: ", interactable.name, " (", interactable, ") with prompt: ", interactable.prompt)
			if _hud and _hud.has_method("set_prompt"):
				_hud.set_prompt("%s (E)" % interactable.prompt)
			return
		else:
			if collider:
				print_debug("[Interact Debug] Ray hit non-interactable: ", collider.name, " (", collider, ")")
			else:
				print_debug("[Interact Debug] Ray hit unknown object.")
	print_debug("[Interact Debug] No interactable detected in view.")
	if _hud and _hud.has_method("set_prompt"):
		_hud.set_prompt("")

func _setup_default_keybinds() -> void:
	for action in ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var expected_keys = ACTIONS[action]
		var existing := InputMap.action_get_events(action)
		if existing.size() == 0:
			InputMap.action_erase_events(action)
			for sc in expected_keys:
				var ev := InputEventKey.new()
				ev.physical_keycode = sc
				InputMap.action_add_event(action, ev)

func _print_current_keybinds() -> void:
	print("=== Current Keybinds ===")
	for action in ACTIONS.keys():
		var events = InputMap.action_get_events(action)
		var keys := []
		for ev in events:
			if ev is InputEventKey:
				keys.append(OS.get_keycode_string(ev.keycode if ev.keycode != 0 else ev.physical_keycode))
		print("%s: %s" % [action, ", ".join(keys)])

func _update_crouch_state(enable: bool) -> void:
	# Adjust collider height for crouching
	var collider = $CollisionShape3D
	if collider and collider.shape is CapsuleShape3D:
		if enable:
			collider.shape.height = crouch_height
		else:
			collider.shape.height = _original_height
