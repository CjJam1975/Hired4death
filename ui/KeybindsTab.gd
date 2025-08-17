extends VBoxContainer

# List of gameplay input actions to allow rebinding
const GAMEPLAY_ACTIONS := [
	"ui_up", "ui_down", "ui_left", "ui_right",
	"jump", "sprint", "interact"
]

var _waiting_for_action: String = ""
var _action_buttons: Dictionary = {}

func _ready() -> void:
	_draw_keybinds()

func _draw_keybinds() -> void:
	clear()
	_action_buttons.clear()
	for action in GAMEPLAY_ACTIONS:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = _action_display_name(action)
		hbox.add_child(label)
		
		var key_name = _get_action_key_name(action)
		var btn = Button.new()
		btn.text = key_name
		btn.pressed.connect(_on_rebind_pressed.bind(action, btn))
		hbox.add_child(btn)
		_action_buttons[action] = btn
		add_child(hbox)

func _action_display_name(action: String) -> String:
	match action:
		"ui_up": return "Move Forward"
		"ui_down": return "Move Back"
		"ui_left": return "Move Left"
		"ui_right": return "Move Right"
		"jump": return "Jump"
		"sprint": return "Sprint"
		"interact": return "Interact"
		_: return action

func _get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.keycode if ev.keycode != 0 else ev.physical_keycode)
	return "Unbound"

func _on_rebind_pressed(action: String, btn: Button) -> void:
	_waiting_for_action = action
	btn.text = "Press any key..."
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_for_action == "":
		return
	if event is InputEventKey and event.pressed and event.keycode != 0:
		var action = _waiting_for_action
		InputMap.action_erase_events(action)
		var ev = InputEventKey.new()
		ev.keycode = event.keycode
		InputMap.action_add_event(action, ev)
		# Update button text
		if _action_buttons.has(action):
			_action_buttons[action].text = OS.get_keycode_string(event.keycode)
		_waiting_for_action = ""
		set_process_unhandled_input(false)
		get_viewport().set_input_as_handled()

func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
