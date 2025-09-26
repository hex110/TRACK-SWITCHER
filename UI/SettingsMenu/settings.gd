extends Control

signal back_requested

@onready var audio_bus_sound_idx: int = AudioServer.get_bus_index("Sounds")
@onready var audio_bus_music_idx: int = AudioServer.get_bus_index("Music")

@export var sound_volume_slider: HSlider
@export var music_volume_slider: HSlider

@export var test_sound: AudioStreamPlayer

@export var display_mode_options_button: OptionButton
@export var resolution_options_button: OptionButton

@export var keybinds_menu : Control

@export var jumpscare_image: TextureRect
@export var jumpscare_background: ColorRect
@export var jumpscare_sound: AudioStreamPlayer

@export var animation_player: AnimationPlayer

var jumpscare_shown: bool = false
var was_maximized: bool = false

func _ready() -> void:
	hide()
	
	var video_settings = ConfigFileHandler.load_video_settings()
	var audio_settings = ConfigFileHandler.load_audio_settings()
	
	sound_volume_slider.value = audio_settings.sound_volume
	music_volume_slider.value = audio_settings.music_volume
	
	display_mode_options_button.select(video_settings.display_mode)

	# Setup resolution dropdown
	var available_resolutions = ConfigFileHandler.get_available_resolutions()
	resolution_options_button.clear()
	var current_resolution = video_settings.resolution
	var selected_index = 0

	for i in range(available_resolutions.size()):
		var resolution = available_resolutions[i]
		resolution_options_button.add_item(resolution)
		if resolution == current_resolution:
			selected_index = i

	resolution_options_button.select(selected_index)

	# Set initial resolution dropdown state based on display mode
	resolution_options_button.disabled = (video_settings.display_mode != 2)

	AudioServer.set_bus_volume_linear(audio_bus_sound_idx, audio_settings.sound_volume)
	AudioServer.set_bus_volume_linear(audio_bus_music_idx, audio_settings.music_volume)

	set_display_mode_from_index(video_settings.display_mode)

func _process(_delta):
	# Monitor for window maximize state changes
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var is_maximized = not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED)
		if is_maximized != was_maximized:
			was_maximized = is_maximized
			if is_maximized:
				# Window was just maximized, update resolution setting to match
				var current_window_size = DisplayServer.window_get_size()
				var resolution_str = str(current_window_size.x) + "x" + str(current_window_size.y)
				ConfigFileHandler.save_video_setting("resolution", resolution_str)
				update_resolution_dropdown_selection(resolution_str)

func update_resolution_dropdown_selection(resolution_str: String):
	# Update the dropdown to reflect the current resolution
	for i in range(resolution_options_button.get_item_count()):
		if resolution_options_button.get_item_text(i) == resolution_str:
			resolution_options_button.select(i)
			return

func _on_back_pressed() -> void:
	emit_signal("back_requested")
	hide_menu()

func show_menu() -> void:
	# This function is called by the UIManager.
	keybinds_menu.hide()
	animation_player.play("Appear")

func hide_menu() -> void:
	# This function is also called by the UIManager.
	animation_player.play("Disappear")

func _on_sound_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(audio_bus_sound_idx, value)
	ConfigFileHandler.save_audio_setting("sound_volume", value)

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(audio_bus_music_idx, value)
	ConfigFileHandler.save_audio_setting("music_volume", value)

func set_display_mode_from_index(index: int):
	var mode
	match index:
		0: mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		1: mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		2: mode = DisplayServer.WINDOW_MODE_WINDOWED

	DisplayServer.window_set_mode(mode)

	# Enable/disable resolution dropdown based on display mode
	resolution_options_button.disabled = (index != 2)  # Only enabled in windowed mode

	apply_current_resolution()

func apply_current_resolution():
	var video_settings = ConfigFileHandler.load_video_settings()
	var resolution = ConfigFileHandler.parse_resolution(video_settings.resolution)

	# Only apply resolution in windowed mode
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		# Force window out of maximized state if it's maximized
		if not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED):
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MAXIMIZE_DISABLED, true)

		# Set the new size
		DisplayServer.window_set_size(resolution)

		# Center the window on the primary screen
		var screen = DisplayServer.get_primary_screen()
		var screen_size = DisplayServer.screen_get_size(screen)
		var screen_position = DisplayServer.screen_get_position(screen)
		var window_pos = Vector2i(
			screen_position.x + (screen_size.x - resolution.x) / 2,
			screen_position.y + (screen_size.y - resolution.y) / 2
		)
		DisplayServer.window_set_position(window_pos)

func _on_display_mode_options_button_item_selected(index: int) -> void:
	set_display_mode_from_index(index)

	ConfigFileHandler.save_video_setting("display_mode", index)

func _on_resolution_options_button_item_selected(index: int) -> void:
	var available_resolutions = ConfigFileHandler.get_available_resolutions()
	var selected_resolution = available_resolutions[index]

	ConfigFileHandler.save_video_setting("resolution", selected_resolution)
	apply_current_resolution()

func _on_sound_volume_slider_drag_ended(_value_changed: bool) -> void:
	test_sound.play()
	pass

func _on_jumpscare_button_pressed() -> void:
	if jumpscare_shown == false:
		jumpscare_image.show()
		jumpscare_background.show()
		
		jumpscare_sound.play()
		
		jumpscare_shown = true
		await get_tree().create_timer(0.5).timeout
		
		jumpscare_image.hide()
		jumpscare_background.hide()
		jumpscare_shown = false


func _on_keybinds_button_pressed() -> void:
	animation_player.play("SettingsToKeybinds")

func settings_appear_again() -> void:
	animation_player.play("KeybindsToSettings")
