extends Area3D
class_name ExtractZone

@export var extractor_tag: StringName = &"alpha"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Use stage-aware extraction; old code path still supported via Mission.try_extract()
		Mission.try_stage_extract(extractor_tag)
