extends Interactable

@export var value: int = 50

func _ready() -> void:
	add_to_group("interactable")

func interact(_player: Node) -> void:
	Economy.add_credits(value)
	queue_free()
