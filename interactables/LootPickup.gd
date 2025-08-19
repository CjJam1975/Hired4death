extends Interactable

@export var value: int = 50

func _ready() -> void:
	add_to_group("interactable")
	$Area3D.add_to_group("interactable") # Added: Ensure Area3D is detectable by interact raycast

func interact(_player: Node) -> void:
	Economy.add_credits(value)
	queue_free()
