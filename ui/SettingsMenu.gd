extends Control

@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var language_dropdown: OptionButton = $Panel/VBoxContainer/TabContainer/GeneralTab/General_LanguageRow/LanguageDropdown
@onready var subtitles_checkbox: CheckBox = $Panel/VBoxContainer/TabContainer/GeneralTab/General_SubtitlesRow/SubtitlesCheckbox

@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/TabContainer/VideoTab/Video_FullscreenRow/FullscreenCheck
@onready var vsync_check: CheckBox = $Panel/VBoxContainer/TabContainer/VideoTab/Video_VsyncRow/VsyncCheck
@onready var resolution_dropdown: OptionButton = $Panel/VBoxContainer/TabContainer/VideoTab/Video_ResolutionRow/ResolutionDropdown

@onready var master_slider: HSlider = $Panel/VBoxContainer/TabContainer/AudioTab/Audio_MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/TabContainer/AudioTab/Audio_MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/TabContainer/AudioTab/Audio_SFXRow/SFXSlider

@onready var keybind_buttons := {
	"ui_up": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_MoveForwardRow/MoveForwardButton,
	"ui_down": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_MoveBackwardRow/MoveBackwardButton,
	"ui_left": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_MoveLeftRow/MoveLeftButton,
	"ui_right": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_MoveRightRow/MoveRightButton,
	"jump": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_JumpRow/JumpButton,
	"sprint": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_SprintRow/SprintButton,
	"interact": $Panel/VBoxContainer/TabContainer/KeybindsTab/Keybinds_InteractRow/InteractButton
}

@onready var back_button: Button = $Panel/VBoxContainer/BottomButtons/BackButton
@onready var quit_button: Button = $Panel/VBoxContainer/BottomButtons/QuitButton

var rebinding_action: String = ""

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_language_dropdown()
	_initialize_resolution_dropdown()
	_load_settings()
	_connect_signals()

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	language_dropdown.item_selected.connect(_on_language_selected)
	subtitles_checkbox.toggled.connect(_on_subtitles_toggled)
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	for action in keybind_buttons.keys():
		keybind_buttons[action].pressed.connect(_on_keybind_button_pressed.bind(action))

func _initialize_language_dropdown() -> void:
	language_dropdown.clear()
	language_dropdown.add_item("English")

func _initialize_resolution_dropdown() -> void:
	resolution_dropdown.clear()
	var resolutions = [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440)
	]
	for res in resolutions:
		resolution_dropdown.add_item("%d x %d" % [res.x, res.y])

func _load_settings() -> void:
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	master_slider.value = 1.0
	music_slider.value = 1.0
	sfx_slider.value = 1.0
	subtitles_checkbox.button_pressed = false
	language_dropdown.select(0)
	resolution_dropdown.select(2)
	_update_keybind_buttons()

func _on_back_pressed() -> void:
	close()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(pressed: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED)

func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_music_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))

func _on_sfx_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))

func _on_language_selected(_idx: int) -> void:
	pass

func _on_subtitles_toggled(_pressed: bool) -> void:
	pass

func _on_resolution_selected(idx: int) -> void:
	var res = [
		Vector2i(1280, 720),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440)
	][idx]
	DisplayServer.window_set_size(res)

func _on_keybind_button_pressed(action: String) -> void:
	rebinding_action = action
	keybind_buttons[action].text = "Press key..."
	set_process_unhandled_input(true)
	set_focus_mode(Control.FOCUS_NONE)

func _unhandled_input(event: InputEvent) -> void:
	if rebinding_action == "":
		return
	if event is InputEventKey and event.pressed and event.keycode != 0:
		InputMap.action_erase_events(rebinding_action)
		var ev := InputEventKey.new()
		ev.keycode = event.keycode
		InputMap.action_add_event(rebinding_action, ev)
		keybind_buttons[rebinding_action].text = OS.get_keycode_string(event.keycode)
		rebinding_action = ""
		set_process_unhandled_input(false)
		set_focus_mode(Control.FOCUS_ALL)

func _update_keybind_buttons() -> void:
	for action in keybind_buttons.keys():
		var events = InputMap.action_get_events(action)
		var key_name = ""
		for ev in events:
			if ev is InputEventKey:
				key_name = OS.get_keycode_string(ev.keycode if ev.keycode != 0 else ev.physical_keycode)
				break
		if key_name == "":
			key_name = "Unset"
		keybind_buttons[action].text = key_name

func open() -> void:
	visible = true
	get_tree().paused = true
	show()
	move_to_front()

func close() -> void:
	visible = false
	get_tree().paused = false
	hide()
