extends Node

var can_pause: bool = true
var track_tutorial: bool = false

const SAVE_FILE = "user://game_data.save"
var game_data = {
	"best_times": {},
	"unlocked_tracks": {},
	"unlocked_levels": [],
	"game_completed": false
}

var level_database = [
	preload("res://Levels/Level1/level1_data.tres"),
	preload("res://Levels/Level2/level2_data.tres"),
	preload("res://Levels/Level3/level3_data.tres"),
	preload("res://Levels/Level4/level4_data.tres"),
	# Add more levels...
]

var current_level_data: LevelData
var selected_track_data: Array[TrackData] = []

func get_level_data(level_name: String) -> LevelData:
	for level_data in level_database:
		if level_data.level_name == level_name:
			return level_data
	return null

func get_level_data_by_index(index: int) -> LevelData:
	if index >= 0 and index < level_database.size():
		return level_database[index]
	return null

func get_medal_type(level_name: String, completion_time: float) -> String:
	var level_data = get_level_data(level_name)
	if not level_data:
		return "none"
	
	if completion_time <= level_data.gold_time:
		return "gold"
	elif completion_time <= level_data.silver_time:
		return "silver"
	elif completion_time <= level_data.bronze_time:
		return "bronze"
	return "none"

func _ready():
	# CHANGED: Call the new, unified load function
	load_game_data()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(_delta):
	if Input.is_action_just_pressed("restart") and get_tree().current_scene and get_tree().current_scene.name != "MainMenu":
		restart_level()

func restart_level():
	get_tree().paused = false
	get_tree().reload_current_scene()

func load_screen_to_scene(target: String) -> void:
	var loading_screen = preload("res://UI/LoadingScreen/LoadingScreen.tscn").instantiate()
	loading_screen.next_scene_path = target
	get_tree().current_scene.add_child(loading_screen)

# This is our new main save function for EVERYTHING
func save_game_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()

# This is our new main load function for EVERYTHING
func load_game_data():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var loaded_data = json.data
				if loaded_data.has("best_times"):
					game_data.best_times = loaded_data.best_times
				if loaded_data.has("unlocked_tracks"):
					game_data.unlocked_tracks = loaded_data.unlocked_tracks
				if loaded_data.has("unlocked_levels"):
					game_data.unlocked_levels = loaded_data.unlocked_levels
				if loaded_data.has("game_completed"):
					game_data.game_completed = loaded_data.game_completed

	# Ensure first level is always unlocked
	ensure_first_level_unlocked()

# MODIFIED: save_best_time now uses the new structure and unlocks next level
func save_best_time(level_name: String, completion_time: float) -> bool:
	var is_new_record = false
	var current_best = game_data.best_times.get(level_name, -1.0)

	if current_best < 0 or completion_time < current_best:
		game_data.best_times[level_name] = completion_time
		is_new_record = true

		# If this is the first time completing this level, unlock the next one
		if current_best < 0:
			unlock_next_level(level_name)

		save_game_data() # Use the new save function

	return is_new_record

# MODIFIED: get_best_time now uses the new structure
func get_best_time(level_name: String) -> float:
	return game_data.best_times.get(level_name, -1.0)

# --- NEW FUNCTIONS FOR TRACKS ---

func unlock_track_for_level(level_name: String, track_layer_name: String):
	if not game_data.unlocked_tracks.has(level_name):
		game_data.unlocked_tracks[level_name] = []
	
	var unlocked_list = game_data.unlocked_tracks[level_name]
	if not track_layer_name in unlocked_list:
		unlocked_list.append(track_layer_name)
		save_game_data()
		print("Unlocked '%s' for level '%s'" % [track_layer_name, level_name])

func get_unlocked_tracks(level_name: String) -> Array:
	return game_data.unlocked_tracks.get(level_name, [])

func is_track_unlocked(level_name: String, track_layer_name: String) -> bool:
	var unlocked_list = get_unlocked_tracks(level_name)
	return track_layer_name in unlocked_list

# --- LEVEL UNLOCK FUNCTIONS ---

func ensure_first_level_unlocked():
	if level_database.size() > 0:
		var first_level = level_database[0]
		if first_level and not is_level_unlocked(first_level.level_name):
			game_data.unlocked_levels.append(first_level.level_name)

func unlock_next_level(current_level_name: String):
	var next_level = get_next_level_data(current_level_name)
	if next_level and not is_level_unlocked(next_level.level_name):
		game_data.unlocked_levels.append(next_level.level_name)
		print("Unlocked level: ", next_level.level_name)

func is_level_unlocked(level_name: String) -> bool:
	return level_name in game_data.unlocked_levels

func get_unlocked_level_names() -> Array:
	return game_data.unlocked_levels.duplicate()

func get_unlocked_level_data() -> Array[LevelData]:
	var unlocked_levels: Array[LevelData] = []
	for level_data in level_database:
		if is_level_unlocked(level_data.level_name):
			unlocked_levels.append(level_data)
	return unlocked_levels

# --- NEW UNIFIED RESET FUNCTIONS ---

func reset_all_data():
	game_data = {
		"best_times": {},
		"unlocked_tracks": {},
		"unlocked_levels": [],
		"game_completed": false
	}
	ensure_first_level_unlocked()
	save_game_data()
	print("All game data reset!")

func reset_level_data(level_name: String):
	if game_data.best_times.has(level_name):
		game_data.best_times.erase(level_name)
	if game_data.unlocked_tracks.has(level_name):
		game_data.unlocked_tracks.erase(level_name)
	if level_name in game_data.unlocked_levels:
		game_data.unlocked_levels.erase(level_name)
	ensure_first_level_unlocked()
	save_game_data()
	print("Reset all data for: ", level_name)

# MODIFIED: Debug input
func _input(event):
	if OS.is_debug_build():
		#if event.is_action_pressed("dash"):
			#print("DASH")
		if event.is_action_pressed("restart") and Input.is_key_pressed(KEY_CTRL):
			reset_all_data() # Use the new reset function

# --- DELETED OLD REDUNDANT FUNCTIONS ---
# save_best_times(), load_best_times(), reset_all_best_times(), and reset_level_best_time()
# have been removed as they are replaced by the new system.

func get_next_level_data(current_level_name: String) -> LevelData:
	for i in range(level_database.size()):
		if level_database[i].level_name == current_level_name:
			if i + 1 < level_database.size():
				return level_database[i + 1]
			break
	return null

func load_next_level(current_level_name: String):
	var next_level = get_next_level_data(current_level_name)
	get_tree().paused = false
	if next_level:
		load_screen_to_scene(next_level.scene_path)
	else:
		get_tree().change_scene_to_file("res://UI/LevelSelect/LevelSelect.tscn")

func set_current_level_data(level_data: LevelData):
	current_level_data = level_data

func get_current_level_data() -> LevelData:
	return current_level_data

func set_selected_track_data(track_data: Array[TrackData]):
	selected_track_data = track_data.duplicate()

func get_selected_track_data() -> Array[TrackData]:
	return selected_track_data

# --- SCREEN SHAKE FUNCTIONS ---

func screen_shake(intensity: float = 15.0, duration: float = 1.0, frequency: float = 30.0):
	# Find the player's camera (it's a child of the player)
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var camera = null
	for child in player.get_children():
		if child is Camera2D:
			camera = child
			break

	if not camera:
		return

	# Store original camera position
	var original_pos = camera.position

	# Create shake effect using property tweening instead of method tweening
	var shake_tween = create_tween()

	for i in range(int(duration * frequency)):
		var t = float(i) / (duration * frequency)
		var current_intensity = intensity * (1.0 - t)

		var shake_x = randf_range(-current_intensity, current_intensity)
		var shake_y = randf_range(-current_intensity, current_intensity)
		var shake_pos = original_pos + Vector2(shake_x, shake_y)

		shake_tween.tween_property(camera, "position", shake_pos, 1.0 / frequency)

	# Return to original position
	shake_tween.tween_property(camera, "position", original_pos, 0.1)


# --- MUSIC BLUR FUNCTIONS ---

func blur_music(blur_duration: float = 1.0):
	# Get the Music bus
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		print("Warning: Music bus not found!")
		return

	# Add low-pass filter to Music bus if not already present
	var filter_effect = null
	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)

	# Check if low-pass filter already exists
	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectLowPassFilter:
			filter_effect = effect
			break

	# If no filter exists, create and add one
	if not filter_effect:
		filter_effect = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(music_bus_index, filter_effect)

	# Animate the filter cutoff frequency
	# Normal music: ~20000 Hz, Blurred: ~500 Hz
	var blur_tween = create_tween()
	blur_tween.tween_method(_set_music_cutoff.bind(filter_effect), 20000.0, 500.0, blur_duration)

func restore_music(restore_duration: float = 0.5):
	# Get the Music bus
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		return

	# Find the low-pass filter
	var filter_effect = null
	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)

	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectLowPassFilter:
			filter_effect = effect
			break

	if filter_effect:
		# Animate back to normal
		var restore_tween = create_tween()
		restore_tween.tween_method(_set_music_cutoff.bind(filter_effect), filter_effect.cutoff_hz, 20000.0, restore_duration)
		restore_tween.tween_callback(_remove_music_filter)

func reset_music_filter():
	# Remove any low-pass filter from Music bus
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index == -1:
		return

	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)

	# Remove all low-pass filters (there should only be one, but just in case)
	for i in range(effect_count - 1, -1, -1):
		var effect = AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(music_bus_index, i)

func _set_music_cutoff(filter: AudioEffectLowPassFilter, cutoff: float) -> void:
	if filter and is_instance_valid(filter):
		filter.cutoff_hz = cutoff

func _remove_music_filter() -> void:
	reset_music_filter()

# --- GAME COMPLETION FUNCTIONS ---

func mark_game_completed():
	game_data.game_completed = true
	save_game_data()
	print("Game marked as completed!")

func is_game_completed() -> bool:
	return game_data.game_completed
