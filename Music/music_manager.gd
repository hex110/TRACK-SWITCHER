extends Node

# --- Signals ---
signal layer_activated(layer_name: String)
signal layer_deactivated(layer_name: String)
signal song_changed(song_name: String, song_stream: AudioStream)
signal music_stopped()

# --- Properties ---
@export var default_transition_duration: float = 1
@export var loop_enabled: bool = true # Controls if the current song should loop

# Track all active players (currently playing or fading)
var active_players: Array[AudioStreamPlayer] = []

var current_song_name: String = ""
## --- MODIFIED --- ##
# This now stores a dictionary of players for each layer, e.g.:
# { "DrumsLayer": { "primary": <Player>, "addon": <Player> } }
var current_song_players: Dictionary = {}
var layer_states: Dictionary = {}  # Which layers are active/inactive in current song

# NEW: Track configured layers for proper state management
var configured_layers: Array[TrackData] = []
var is_music_configured: bool = false

var _transition_tween: Tween
var _layer_fade_tween: Tween

var _loop_signal_player: AudioStreamPlayer = null # Player we're listening to for the 'finished' signal
var _player_counter: int = 0  # To ensure unique names for players

# --- Godot Lifecycle ---
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- Public API ---

## Stop all music immediately
func stop_all_music_immediately():
	_kill_tweens()

	for player in active_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()

	active_players.clear()
	current_song_players.clear()
	layer_states.clear()
	current_song_name = ""
	configured_layers.clear()
	is_music_configured = false

	if is_instance_valid(_loop_signal_player):
		if _loop_signal_player.is_connected("finished", _on_song_finished):
			_loop_signal_player.finished.disconnect(_on_song_finished)
		_loop_signal_player = null

	music_stopped.emit()

## Play a single-track song with crossfade
func play_music(track_stem: Resource, song_name: String, transition_duration: float = -1.0):
	var stems = { "MusicLayer": { "primary": track_stem } }
	play_dynamic_music(stems, song_name, transition_duration)

## --- MODIFIED: play_dynamic_music --- ##
## Play a multi-stem song with crossfade.
## track_stems format: { "LayerName": { "primary": AudioStream, "addon": Optional[AudioStream] } }
func play_dynamic_music(track_stems: Dictionary, song_name: String, transition_duration: float = 0.0):
	var duration = default_transition_duration if transition_duration < 0 else transition_duration
	
	if song_name == current_song_name and is_playing():
		return
	
	if track_stems.is_empty():
		push_error("MusicManager: No stems provided")
		return
	
	_kill_tweens()
	_transition_tween = create_tween().set_parallel()
	
	if is_instance_valid(_loop_signal_player):
		if _loop_signal_player.is_connected("finished", _on_song_finished):
			_loop_signal_player.finished.disconnect(_on_song_finished)
		_loop_signal_player = null
	
	var players_to_remove = active_players.duplicate()
	for player in players_to_remove:
		if is_instance_valid(player) and player.volume_db > -79.0:
			_transition_tween.tween_property(player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if players_to_remove.size() > 0:
		get_tree().create_timer(duration).timeout.connect(_cleanup_old_players.bind(players_to_remove))
	
	var new_song_players: Dictionary = {}
	var base_player: AudioStreamPlayer = null
	
	for layer_name in track_stems:
		var layer_data = track_stems[layer_name]
		if not layer_data is Dictionary or not layer_data.has("primary"):
			printerr("MusicManager: Invalid stem data for '", layer_name, "'. Must be a dictionary with a 'primary' key.")
			continue

		# This dictionary will hold all players for this layer
		var players_for_layer: Dictionary = {}
		
		# --- Create PRIMARY player ---
		var primary_stream = layer_data["primary"]
		var primary_player = _create_player(layer_name, primary_stream)
		# Route to its own bus for analysis
		var bus_name = layer_name.replace("Layer", "")
		primary_player.bus = bus_name if AudioServer.get_bus_index(bus_name) >= 0 else "Music"
		players_for_layer["primary"] = primary_player
		
		# --- Create ADDON player (if it exists) ---
		if layer_data.has("addon") and layer_data["addon"] is AudioStream:
			var addon_stream = layer_data["addon"]
			# Create a unique name for the addon player
			var addon_player = _create_player(layer_name + "Addon", addon_stream)
			# Route addon sounds to the 'Base' bus as requested
			addon_player.bus = "Base" if AudioServer.get_bus_index("Base") >= 0 else "Music"
			players_for_layer["addon"] = addon_player

		new_song_players[layer_name] = players_for_layer
		
		# Track the first layer's primary player for timing info
		if base_player == null:
			base_player = primary_player
	
	layer_states.clear()
	var initial_active_layer = "BaseLayer" if track_stems.has("BaseLayer") else track_stems.keys()[0]
	
	for layer_name in track_stems:
		var is_initially_active = (layer_name == initial_active_layer)
		layer_states[layer_name] = is_initially_active
		var target_db = 0.0 if is_initially_active else -80.0
		
		# Fade in ALL players associated with the initial layer
		var players_to_fade = new_song_players[layer_name]
		for player in players_to_fade.values():
			_transition_tween.tween_property(player, "volume_db", target_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	current_song_name = song_name
	current_song_players = new_song_players
	_loop_signal_player = base_player
	is_music_configured = true

	if loop_enabled and is_instance_valid(_loop_signal_player):
		_loop_signal_player.finished.connect(_on_song_finished)

	if base_player:
		song_changed.emit(current_song_name, base_player.stream)

## Activate/deactivate a layer with fade
func set_layer_active(layer_name: String, is_active: bool, fade_duration: float = 1.0):
	if not current_song_players.has(layer_name):
		return
	if layer_states.get(layer_name, false) == is_active:
		return
	
	layer_states[layer_name] = is_active
	var target_db = 0.0 if is_active else -80.0
	
	_fade_layer_volume(layer_name, target_db, fade_duration)
	
	if is_active:
		layer_activated.emit(layer_name)
	else:
		layer_deactivated.emit(layer_name)

func is_layer_active(layer_name: String) -> bool:
	return layer_states.get(layer_name, false)

## NEW: Configure which layers should be active based on TrackData array
func configure_layers(track_data_array: Array[TrackData]):
	print("DEBUG MusicManager: configure_layers called with ", track_data_array.size(), " tracks")
	print("DEBUG MusicManager: is_music_configured = ", is_music_configured)
	print("DEBUG MusicManager: current_song_players keys = ", current_song_players.keys())

	if not is_music_configured:
		push_warning("MusicManager: configure_layers called before music is loaded. Ignoring.")
		return

	configured_layers = track_data_array.duplicate()

	# Kill any existing layer fade tweens to avoid conflicts
	_kill_tweens()

	# Directly set volumes without fading to avoid tween conflicts
	for layer_name in current_song_players:
		print("DEBUG MusicManager: Deactivating layer: ", layer_name)
		layer_states[layer_name] = false
		_set_layer_volume_direct(layer_name, -80.0)

	# Always activate the base layer (BaseLayer or first available layer)
	var base_layer_name = "BaseLayer" if current_song_players.has("BaseLayer") else current_song_players.keys()[0]
	if current_song_players.has(base_layer_name):
		print("DEBUG MusicManager: Activating base layer: ", base_layer_name)
		layer_states[base_layer_name] = true
		_set_layer_volume_direct(base_layer_name, 0.0)

	# Then activate the additional configured layers
	for track_data in track_data_array:
		if track_data and current_song_players.has(track_data.layer_name):
			print("DEBUG MusicManager: Activating additional layer: ", track_data.layer_name)
			layer_states[track_data.layer_name] = true
			_set_layer_volume_direct(track_data.layer_name, 0.0)
		elif track_data:
			print("DEBUG MusicManager: Layer not found in current_song_players: ", track_data.layer_name)

## NEW: Get the currently configured layers
func get_configured_layers() -> Array[TrackData]:
	return configured_layers.duplicate()

## NEW: Check if music system is fully configured and ready
func is_music_system_ready() -> bool:
	return is_music_configured and not current_song_players.is_empty()

## --- MODIFIED: seek_all_layers --- ##
func seek_all_layers(position_sec: float):
	for layer_name in current_song_players:
		var players_for_layer = current_song_players[layer_name]
		for player in players_for_layer.values():
			if is_instance_valid(player):
				player.seek(position_sec)

func get_song_length() -> float:
	if not current_song_players.is_empty():
		# Get the dictionary of players for the first layer
		var first_layer_players = current_song_players.values()[0]
		# Use its primary player for info
		var first_player = first_layer_players.get("primary")
		if is_instance_valid(first_player) and first_player.stream:
			return first_player.stream.get_length()
	return 0.0

func get_playback_position() -> float:
	if not current_song_players.is_empty():
		var first_layer_players = current_song_players.values()[0]
		var first_player = first_layer_players.get("primary")
		if is_instance_valid(first_player):
			return first_player.get_playback_position()
	return 0.0

## --- MODIFIED: is_playing --- ##
func is_playing() -> bool:
	# If any single player is playing, we consider the music to be playing.
	for layer_name in current_song_players:
		var players_for_layer = current_song_players[layer_name]
		for player in players_for_layer.values():
			if is_instance_valid(player) and player.is_playing():
				return true
	return false

# --- Private Methods ---

## --- NEW: Helper function to create a player --- ##
func _create_player(name_suffix: String, stream: AudioStream) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	_player_counter += 1
	player.name = "Player_%d_%s" % [_player_counter, name_suffix]
	player.stream = stream
	player.volume_db = -80.0 # Start silent
	add_child(player)
	player.play()
	active_players.append(player) # Track for cleanup
	return player

## --- MODIFIED: _fade_layer_volume --- ##
func _fade_layer_volume(layer_name: String, target_db: float, fade_duration: float):
	if not current_song_players.has(layer_name):
		return

	var players_for_layer = current_song_players[layer_name]

	if _layer_fade_tween and _layer_fade_tween.is_valid():
		_layer_fade_tween.kill()

	_layer_fade_tween = create_tween().set_parallel()

	for player in players_for_layer.values():
		if is_instance_valid(player):
			if fade_duration > 0:
				_layer_fade_tween.tween_property(player, "volume_db", target_db, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			else:
				player.volume_db = target_db

## NEW: Set layer volume directly without fading
func _set_layer_volume_direct(layer_name: String, target_db: float):
	if not current_song_players.has(layer_name):
		return

	var players_for_layer = current_song_players[layer_name]
	for player in players_for_layer.values():
		if is_instance_valid(player):
			player.volume_db = target_db
			print("DEBUG: Set ", player.name, " volume to ", target_db, "db")

## --- MODIFIED: restart_current_song --- ##
func restart_current_song(transition_duration: float = 0.0):
	if current_song_name.is_empty():
		return
	
	if transition_duration <= 0:
		# Seek all players to the beginning and continue playing
		for layer_name in current_song_players:
			var players_for_layer = current_song_players[layer_name]
			for player in players_for_layer.values():
				if is_instance_valid(player):
					player.play(0.0)
		
		# Re-emit signal using the main timing player
		if is_instance_valid(_loop_signal_player) and _loop_signal_player.stream:
			song_changed.emit(current_song_name, _loop_signal_player.stream)
	else:
		# Rebuild the stems dict to do a full transition. This is more complex now.
		# For simplicity, we just rebuild it from the current players.
		var stems = {}
		for layer_name in current_song_players:
			var players_for_layer = current_song_players[layer_name]
			var layer_data = {}
			if players_for_layer.has("primary") and is_instance_valid(players_for_layer["primary"]):
				layer_data["primary"] = players_for_layer["primary"].stream
			if players_for_layer.has("addon") and is_instance_valid(players_for_layer["addon"]):
				layer_data["addon"] = players_for_layer["addon"].stream
			stems[layer_name] = layer_data
			
		play_dynamic_music(stems, current_song_name, transition_duration)


func _cleanup_old_players(players_to_remove: Array):
	for player in players_to_remove:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
			active_players.erase(player)

func _kill_tweens():
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
	if _layer_fade_tween and _layer_fade_tween.is_valid():
		_layer_fade_tween.kill()

func get_current_song_name() -> String:
	return current_song_name

func get_current_song_stream() -> AudioStream:
	if is_instance_valid(_loop_signal_player):
		return _loop_signal_player.stream
	return null

# --- Signal Handlers ---

func _on_song_finished():
	if loop_enabled and not current_song_name.is_empty():
		restart_current_song(0.0)
