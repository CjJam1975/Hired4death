extends Resource
class_name Faction

@export var id: StringName
@export var display_name: String = "Faction"
@export_range(0.0, 1.0) var aggression: float = 0.5
@export_range(0.0, 1.0) var tech_level: float = 0.5
# key: String enemy_id, value: PackedScene
@export var spawn_table: Dictionary = {}
