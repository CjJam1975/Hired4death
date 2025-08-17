extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	close_button.pressed.connect(close)
	self.visible = false

func open() -> void:
	self.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	tab_container.current_tab = 0

func close() -> void:
	self.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if self.visible and event.is_action_pressed("ui_cancel"):
		close()
