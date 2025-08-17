extends Node

@export var base_step_noise: float = 0.6
@export var sprint_mult: float = 1.5

var _owner3d: Node3D

func _ready() -> void:
	_owner3d = get_parent() as Node3D

func step(did_sprint: bool) -> void:
	var pos := _owner3d.global_transform.origin
	var amt := base_step_noise * (sprint_mult if did_sprint else 1.0)
	NoiseBus.emit_noise(pos, amt)
