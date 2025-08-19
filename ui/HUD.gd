extends Control

@onready var objective_label: Label = $VBoxContainer/Objective
@onready var credits_label: Label = $VBoxContainer/Credits
@onready var stage_label: Label = $VBoxContainer/Stage
@onready var prompt_label: Label = $Prompt
@onready var settings_menu = preload("res://ui/SettingsMenu.tscn").instantiate()

func _ready() -> void:
	add_child(settings_menu)
	Mission.objective_updated.connect(_on_objective_updated)
	Mission.stage_changed.connect(_on_stage_changed)
	Economy.credits_changed.connect(_on_credits_changed)
	_on_objective_updated("")
	_on_credits_changed(Economy.total_credits, Economy.session_credits)
	_on_stage_changed(0, 1)
	set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			settings_menu.close()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			settings_menu.open()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_prompt(text: String) -> void:
	print_debug("[HUD Prompt] set_prompt called with text: ", text)
	prompt_label.text = text
	prompt_label.modulate = Color.BLACK # Sets prompt color to black for visibility

func _on_objective_updated(text: String) -> void:
	objective_label.text = text

func _on_credits_changed(total: int, session: int) -> void:
	credits_label.text = "Credits: %d (carried: %d)" % [total, session]

func _on_stage_changed(idx: int, total: int) -> void:
	stage_label.text = "Stage %d / %d" % [idx + 1, total]
