extends Resource
class_name Contract

enum Type { SALVAGE, UPLINK, CAPTURE, PURGE }

@export var id: StringName
@export var title: String = "Contract"
@export_multiline var description: String = ""
@export var type: Type = Type.SALVAGE
@export var target_value: int = 1
@export var reward_base: int = 100
@export var risk_mult: float = 1.0
