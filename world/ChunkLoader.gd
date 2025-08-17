extends Node3D
class_name ChunkLoader

@export var target: NodePath
@export var chunks: Array[NodePath] = []
@export var active_radius: float = 180.0
@export var hysteresis: float = 20.0

var _t: Node3D

func _ready() -> void:
	_t = get_node_or_null(target)
	_update_chunks(true)

func _process(_delta: float) -> void:
	if _t == null:
		_t = get_node_or_null(target)
		return
	_update_chunks(false)

func _update_chunks(force: bool) -> void:
	if _t == null:
		return
	for p in chunks:
		var n := get_node_or_null(p)
		if n == null:
			continue
		var d := n.global_transform.origin.distance_to(_t.global_transform.origin)
		var should := d <= active_radius
		# Apply hysteresis to avoid flicker
		if not force:
			var currently := n.is_visible_in_tree()
			if currently and d <= active_radius + hysteresis:
				should = true
			if not currently and d >= active_radius - hysteresis:
				should = false
		n.visible = should
		if n is Node:
			n.process_mode = Node.PROCESS_MODE_INHERIT if should else Node.PROCESS_MODE_DISABLED
			
