@tool
class_name ReactiveElement
extends Node2D

@export var track_data: TrackData

@export_group("Audio Setup")
@export var spectrum_analyzer_index: int = 0
# REMOVED: @export var beat_threshold: float = 0.15
# REMOVED: @export var beat_cooldown: float = 0.15

@export_group("Animation")
@export var animation_player: AnimationPlayer

var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var _cooldown_remaining: float = 0.0

func _ready():
	# Stop everything initially until we know the state.
	deactivate()

	if Engine.is_editor_hint():
		return

	if not track_data:
		printerr("ReactiveElement has no TrackData assigned. It will not function.", self)
		return

	MusicManager.layer_activated.connect(_on_music_layer_toggled)
	MusicManager.layer_deactivated.connect(_on_music_layer_toggled)

	call_deferred("_initialize_audio_analyzer")
	call_deferred("_sync_with_music_system")

func _on_music_layer_toggled(layer_name: String):
	if track_data and layer_name == track_data.layer_name:
		if MusicManager.is_layer_active(layer_name):
			activate()
		else:
			deactivate()

func _sync_with_music_system():
	# Wait for the music system to be fully ready before syncing
	if not MusicManager.is_music_system_ready():
		# Try again later
		get_tree().create_timer(0.1).timeout.connect(_sync_with_music_system)
		return

	if track_data and MusicManager.is_layer_active(track_data.layer_name):
		activate()
	else:
		deactivate()

func _initialize_audio_analyzer():
	if Engine.is_editor_hint(): return
	
	if not track_data:
		printerr("ReactiveElement has no TrackData assigned. It will not function.", self)
		return
	
	var bus_name = track_data.layer_name.replace("Layer", "")
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		spectrum_instance = AudioServer.get_bus_effect_instance(bus_idx, spectrum_analyzer_index)
	else:
		printerr("Audio bus not found for reactive element: '", bus_name, "' derived from '", track_data.layer_name, "'.", self)

func _on_beat():
	if animation_player and not animation_player.is_playing():
		animation_player.play("Pulse")

# --- MODIFIED _process FUNCTION ---
func _process(delta):
	# First, handle the cooldown.
	if _cooldown_remaining > 0:
		_cooldown_remaining -= delta
		return

	# Ensure we have both a spectrum instance and track data before proceeding.
	if not spectrum_instance or not track_data:
		return

	var magnitude = spectrum_instance.get_magnitude_for_frequency_range(20, 1000)
	var energy = magnitude.length()

	# --- CHANGED: Use track_data's threshold ---
	if energy > track_data.beat_threshold:
		#print(energy, track_data.layer_name)
		# A beat is detected.
		_on_beat()
		
		# --- CHANGED: Use track_data's cooldown ---
		# Start the cooldown to prevent immediate re-triggering.
		_cooldown_remaining = track_data.beat_cooldown

func activate():
	show()
	_cooldown_remaining = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT
	if animation_player:
		animation_player.play("Activate")

func deactivate():
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	if animation_player:
		animation_player.play("Deactivate")
