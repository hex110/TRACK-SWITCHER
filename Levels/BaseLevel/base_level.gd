# base_level.gd
extends Node2D
class_name BaseLevel

@export var level_data: LevelData

# NEW: Allow specifying which tracks should be active (for level select UI)
var tracks_to_activate: Array[TrackData] = []

@onready var player = $Player

@onready var level_timer = $LevelTimer
@onready var win_flag = $WinFlag
@onready var win_screen = $CanvasLayer/WinScreen
@onready var level_start_screen = $CanvasLayer/LevelStartScreen

func _ready():
	if not level_data:
		push_error("Level data not assigned in: " + scene_file_path)
		return

	# Reset any music filter effects (in case track upgrade animation was interrupted)
	GameManager.reset_music_filter()

	setup_level()
	connect_signals()
	start_music_immediately()
	show_level_start_screen()

func setup_level():
	# Set timer thresholds from level data
	level_timer.bronze_time = level_data.bronze_time
	level_timer.silver_time = level_data.silver_time
	level_timer.gold_time = level_data.gold_time
	
	Engine.time_scale = 1.0
	
	# Call setup hook for child classes
	_setup_level_specific()

func connect_signals():
	level_timer.level_completed.connect(_on_level_completed)
	win_flag.level_completed.connect(_on_goal_reached)

	# NEW: Listen for when the song is loaded and ready.
	MusicManager.song_changed.connect(_on_music_song_changed)

	# Connect level start screen signals
	if level_start_screen:
		level_start_screen.level_started.connect(_on_level_started)

func start_music_immediately():
	# Start music with all unlocked tracks immediately
	_start_level_specific()

func start_level():
	# Just start the timer - music is already playing
	level_timer.start_timer()

# NEW: This function is called by the signal AFTER MusicManager has loaded the song.
func _on_music_song_changed(_song_name: String, _song_stream: AudioStream):
	# This is the perfect, timing-safe place to configure layers.
	configure_level_layers()

func configure_level_layers():
	if not level_data:
		print("DEBUG: No level_data available")
		return

	# Safety check for scene tree availability
	if not is_inside_tree():
		print("BaseLevel not in tree, skipping layer configuration")
		return

	print("DEBUG: Configuring layers for level: ", level_data.level_name)

	var track_data_to_activate: Array[TrackData] = []

	# NEW: If tracks were specified (e.g., from level select), use those
	if not tracks_to_activate.is_empty():
		track_data_to_activate = tracks_to_activate.duplicate()
		print("DEBUG: Using pre-specified tracks: ", track_data_to_activate.map(func(td): return td.layer_name if td else "null"))
	else:
		# Otherwise, use the unlocked tracks approach
		var unlocked_track_names = GameManager.get_unlocked_tracks(level_data.level_name)
		print("DEBUG: Unlocked tracks from GameManager: ", unlocked_track_names)

		# Look through all track upgrade objects in the level to find their TrackData
		var tree = get_tree()
		if tree:
			var track_upgrades = tree.get_nodes_in_group("track_upgrades")
			print("DEBUG: Found ", track_upgrades.size(), " track upgrades in group")

			for upgrade in track_upgrades:
				if is_instance_valid(upgrade) and upgrade.track_data:
					print("DEBUG: Track upgrade found - layer_name: ", upgrade.track_data.layer_name,
						  ", display_name: ", upgrade.track_data.display_name)
					if unlocked_track_names.has(upgrade.track_data.layer_name):
						track_data_to_activate.append(upgrade.track_data)
						print("DEBUG: Adding track to activate: ", upgrade.track_data.layer_name)
					else:
						print("DEBUG: Track not unlocked: ", upgrade.track_data.layer_name)
				else:
					print("DEBUG: Invalid upgrade or missing track_data")

	# Configure the music manager with the active tracks
	print("DEBUG: Configuring MusicManager with ", track_data_to_activate.size(), " tracks")
	MusicManager.configure_layers(track_data_to_activate)
	print("Configured layers for level: ", track_data_to_activate.map(func(td): return td.layer_name if td else "null"))


# NEW: Function to set which tracks should be active (call this before level starts)
func show_level_start_screen():
	if level_start_screen:
		level_start_screen.set_level_data(level_data)
		level_start_screen.set_base_level(self)
		level_start_screen.show()
		get_tree().paused = true


func _on_level_started(selected_tracks: Array[TrackData]):
	set_tracks_to_activate(selected_tracks)
	if level_start_screen:
		level_start_screen.hide()
	get_tree().paused = false

	# Suppress jump input briefly to prevent immediate jumping after pressing start
	#if player and player.state_machine:
		#player.state_machine.suppress_jump_input(0.05)

	start_level()


func set_tracks_to_activate(tracks: Array[TrackData]):
	tracks_to_activate = tracks.duplicate()
	print("DEBUG: Set tracks to activate: ", tracks_to_activate.map(func(td): return td.layer_name if td else "null"))

# Virtual functions for child classes to override
func _setup_level_specific():
	# Override this in child classes for level-specific setup
	pass

func _start_level_specific():
	# Override this in child classes for level-specific start logic
	pass

# Standard level completion handling
func _on_goal_reached():
	level_timer.stop_timer()

func _on_level_completed(completion_time: float, medal_type: String):
	var is_new_record = GameManager.save_best_time(level_data.level_name, completion_time)
	var best_time = GameManager.get_best_time(level_data.level_name)
	
	win_screen.show_completion(completion_time, medal_type, is_new_record, best_time, level_data)
	
	player.hide_ui()
	player.stop()
