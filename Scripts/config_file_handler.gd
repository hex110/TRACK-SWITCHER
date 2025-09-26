extends Node

var config = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://settings.ini"

func _ready() -> void:
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("audio", "sound_volume", 0.5)
		config.set_value("audio", "music_volume", 0.5)
		
		config.set_value("video", "display_mode", 0)
		config.set_value("video", "resolution", get_default_resolution())
		
		config.set_value("keybinds", "move_left", "A")
		config.set_value("keybinds", "move_right", "D")
		config.set_value("keybinds", "move_up", "U")
		config.set_value("keybinds", "move_down", "S")
		config.set_value("keybinds", "jump", "SPACE")
		config.set_value("keybinds", "dash", "SHIFT")
		config.set_value("keybinds", "restart", "R")
		
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

func save_video_setting(key: String, value):
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings():
	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

func get_available_resolutions() -> Array[String]:
	var resolutions: Array[String] = []
	var current_screen = DisplayServer.get_primary_screen()
	var screen_size = DisplayServer.screen_get_size(current_screen)

	# Always include the current screen resolution first
	var current_res = str(screen_size.x) + "x" + str(screen_size.y)
	resolutions.append(current_res)

	# Common resolutions to include (if they fit on the current monitor)
	var common_resolutions = [
		"3440x1440",  # Ultrawide 1440p
		"2560x1440",  # 1440p
		"2560x1080",  # Ultrawide 1080p
		"1920x1080",  # 1080p
		"1680x1050",  # 16:10
		"1600x900",   # 16:9
		"1440x900",   # 16:10
		"1366x768",   # Common laptop
		"1280x720",   # 720p
		"1024x768"    # 4:3
	]

	# Add resolutions that fit within the current screen size
	for res_str in common_resolutions:
		var res = parse_resolution(res_str)
		if res.x <= screen_size.x and res.y <= screen_size.y and res_str != current_res:
			resolutions.append(res_str)

	return resolutions

func get_default_resolution() -> String:
	var current_screen = DisplayServer.get_primary_screen()
	var screen_size = DisplayServer.screen_get_size(current_screen)
	return str(screen_size.x) + "x" + str(screen_size.y)

func parse_resolution(resolution_str: String) -> Vector2i:
	var parts = resolution_str.split("x")
	return Vector2i(int(parts[0]), int(parts[1]))

func save_audio_setting(key: String, value):
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_audio_settings():
	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings

func save_keybind(action: StringName, event: InputEvent):
	var event_str
	if event is InputEventKey:
		event_str = OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		event_str = "mouse_" + str(event.button_index)
	
	config.set_value("keybinds", action, event_str)
	config.save(SETTINGS_FILE_PATH)

func load_keybinds():
	var keybinds = {}
	var keys = config.get_section_keys("keybinds")
	for key in keys:
		var input_event
		var event_str = config.get_value("keybinds", key)
		
		if event_str.contains("mouse_"):
			input_event = InputEventMouseButton.new()
			input_event.button_index = int(event_str.split("_")[1])
		else:
			input_event = InputEventKey.new()
			input_event.keycode = OS.find_keycode_from_string(event_str)
		
		keybinds[key] = input_event
	return keybinds
	
