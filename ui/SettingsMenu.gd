extends Control

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var back_button: Button = $Panel/BackButton
@onready var quit_button: Button = $Panel/QuitButton

@onready var language_dropdown: OptionButton = $Panel/TabContainer/GeneralTab/LanguageDropdown
@onready var subtitles_checkbox: CheckBox = $Panel/TabContainer/GeneralTab/SubtitlesCheckbox

@onready var fullscreen_check: CheckBox = $Panel/TabContainer/VideoTab/FullscreenCheck
@onready var vsync_check: CheckBox = $Panel/TabContainer/VideoTab/VsyncCheck
@onready var resolution_dropdown: OptionButton = $Panel/TabContainer/VideoTab/ResolutionDropdown

@onready var master_slider: HSlider = $Panel/TabContainer/AudioTab/MasterSlider
@onready var music_slider: HSlider = $Panel/TabContainer/AudioTab/MusicSlider
@onready var sfx_slider: HSlider = $Panel/TabContainer/AudioTab/SFXSlider

func _ready() -> void:
	# Populate dropdowns with defaults if empty
	if language_dropdown.item_count == 0:
		language_dropdown.add_item("English")
		language_dropdown.add_item("Spanish")
		language_dropdown.add_item("French")
		language_dropdown.add_item("German")
		language_dropdown.add_item("Japanese")

	if resolution_dropdown.item_count == 0:
		resolution_dropdown.add_item("1920x1080")
		resolution_dropdown.add_item("1280x720")
		resolution_dropdown.add_item("2560x1440")
		resolution_dropdown.add_item("3840x2160")

	# Connect all signals
	back_button.pressed.connect(_on_back_pressed)
	quit_button.pressed.connect(_on_quit_to_menu)
	language_dropdown.item_selected.connect(_on_language_selected)
	subtitles_checkbox.toggled.connect(_on_subtitles_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_back_pressed():
	self.hide()
	get_tree().paused = false

func _on_quit_to_menu():
	self.hide()
	get_tree().paused = false
	if Engine.has_singleton("Game"):
		Game.goto_hub()

func _on_language_selected(idx: int):
	print("Language selected:", language_dropdown.get_item_text(idx))

func _on_subtitles_toggled(enabled: bool):
	print("Subtitles toggled:", enabled)

func _on_fullscreen_toggled(enabled: bool):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_resolution_selected(idx: int):
	var res = resolution_dropdown.get_item_text(idx)
	var parts = res.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
	print("Resolution selected:", res)

func _on_master_volume_changed(value: float):
	var idx = AudioServer.get_bus_index("Master")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear2db(value))

func _on_music_volume_changed(value: float):
	var idx = AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear2db(value))

func _on_sfx_volume_changed(value: float):
	var idx = AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear2db(value))

func linear2db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return 20.0 * log(value) / log(10.0)
