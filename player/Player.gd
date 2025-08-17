extends Node

# Helper to auto-create input actions at runtime.
# Add temporarily to main scene, run once, then remove.
const ACTIONS := {
	"ui_up": [KEY_W, KEY_UP],
	"ui_down": [KEY_S, KEY_DOWN],
	"ui_left": [KEY_A, KEY_LEFT],
	"ui_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E],
}

func _ready() -> void:
	for action in ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for sc in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = sc
			InputMap.action_add_event(action, ev)
	print("Input actions created/updated.")
