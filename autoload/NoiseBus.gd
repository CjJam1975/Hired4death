extends Node

signal noise_emitted(pos: Vector3, amount: float)

func emit_noise(pos: Vector3, amount: float) -> void:
	emit_signal("noise_emitted", pos, amount)
