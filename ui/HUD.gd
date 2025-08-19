extends Control

@onready var objective_label: Label = $VBoxContainer/Objective
@onready var credits_label: Label = $VBoxContainer/Credits
@onready var stage_label: Label = $VBoxContainer/Stage
@onready var prompt_label: Label = $Prompt
@onready var settings_menu = preload("res://ui/SettingsMenu.tscn").instantiate()

# Cache for positioning the prompt over the interactable
var _prompt_world_pos: Vector3 = Vector3.ZERO
var _prompt_camera: Camera3D = null

func _ready() -> void:
	add_child(settings_menu)
	Mission.objective_updated.connect(_on_objective_updated)
	Mission.stage_changed.connect(_on_stage_changed)
	Economy.credits_changed.connect(_on_credits_changed)
	_on_objective_updated("")
	_on_credits_changed(Economy.total_credits, Economy.session_credits)
	_on_stage_changed(0, 1)
	set_prompt("Pick Up (E)") # Ensure prompt is hidden at start

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			settings_menu.close()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			settings_menu.open()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Updated: Allow prompt to be positioned above interactable in screen space and hidden by default
# text: prompt string, world_pos: interactable's global position (nullable), camera: Camera3D (nullable)
func set_prompt(text: String, world_pos: Variant = null, camera: Variant = null) -> void:
	print_debug("[HUD Prompt] set_prompt called with text: ", text)
	if text == "" or world_pos == null or camera == null:
		prompt_label.visible = false
		_prompt_camera = null
		return

	prompt_label.text = text
	prompt_label.modulate = Color.BLACK # Ensures prompt color is black/high visibility
	prompt_label.visible = true
	_prompt_world_pos = world_pos
	_prompt_camera = camera

	# Place prompt above the object on screen
	var screen_pos = camera.unproject_position(world_pos)
	screen_pos.y -= 40 # Offset upward so it's above the item
	# Clamp screen_pos inside viewport for safety
	var viewport_size = get_viewport().get_visible_rect().size
	screen_pos.x = clamp(screen_pos.x, 0, viewport_size.x - prompt_label.size.x)
	screen_pos.y = clamp(screen_pos.y, 0, viewport_size.y - prompt_label.size.y)
	prompt_label.position = screen_pos

# Call this every frame from Player.gd if prompt is visible to keep it above moving objects
func update_prompt_position(world_pos: Vector3) -> void:
	if prompt_label.visible and _prompt_camera:
		_prompt_world_pos = world_pos
		var screen_pos = _prompt_camera.unproject_position(world_pos)
		screen_pos.y -= 40
		var viewport_size = get_viewport().get_visible_rect().size
		screen_pos.x = clamp(screen_pos.x, 0, viewport_size.x - prompt_label.size.x)
		screen_pos.y = clamp(screen_pos.y, 0, viewport_size.y - prompt_label.size.y)
		prompt_label.position = screen_pos

func _on_objective_updated(text: String) -> void:
	objective_label.text = text

func _on_credits_changed(total: int, session: int) -> void:
	credits_label.text = "Credits: %d (carried: %d)" % [total, session]

func _on_stage_changed(idx: int, total: int) -> void:
	stage_label.text = "Stage %d / %d" % [idx + 1, total]
