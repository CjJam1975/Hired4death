extends Resource
class_name RepoStage

@export var title: String = "Stage"
@export var quota: int = 0
@export var extractor_tag: StringName = &"any" # which Extractor to deliver to
@export var difficulty_bump: float = 0.25 # applied in EncounterDirector when this stage begins
