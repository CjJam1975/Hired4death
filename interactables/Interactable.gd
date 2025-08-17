extends Node3D
class_name Interactable

@export var prompt: String = "Use"

func can_interact(_player: Node) -> bool:
	return true

func interact(_player: Node) -> void:
	pass
