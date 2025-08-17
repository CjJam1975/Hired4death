extends Resource
class_name Planet

@export var id: StringName
@export var display_name: String = "Planet"
@export var planet_seed: int = 0
@export var liberation: float = 0.0 # 0..1
@export var heat: float = 0.0 # 0..1 pressure
@export var faction: Faction
@export var biomes: Array[StringName] = []
