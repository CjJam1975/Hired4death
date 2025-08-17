extends Control

@onready var objective_label: Label = $VBoxContainer/Objective
@onready var credits_label: Label = $VBoxContainer/Credits
@onready var stage_label: Label = $VBoxContainer/Stage

func _ready() -> void:
	Mission.objective_updated.connect(_on_objective_updated)
	Mission.stage_changed.connect(_on_stage_changed)
	Economy.credits_changed.connect(_on_credits_changed)
	_on_objective_updated("")
	_on_credits_changed(Economy.total_credits, Economy.session_credits)
	_on_stage_changed(0, 1)

func _on_objective_updated(text: String) -> void:
	objective_label.text = text

func _on_credits_changed(total: int, session: int) -> void:
	credits_label.text = "Credits: %d (carried: %d)" % [total, session]

func _on_stage_changed(idx: int, total: int) -> void:
	stage_label.text = "Stage %d / %d" % [idx + 1, total]
