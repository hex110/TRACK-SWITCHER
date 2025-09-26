# music_controller.gd
extends Node

# Drag the ColorRect node here from the Scene tree in the editor
@export var target_material_node: CanvasItem

# We need the bus index and effect index to get the analyzer instance
# The "Music" bus is usually index 1 (Master is 0)
@export var music_bus_index: int = 1
@export var spectrum_analyzer_index: int = 0

# These define the frequency range for our "bass"
@export var bass_frequency_min: float = 20.0
@export var bass_frequency_max: float = 250.0

# This lets you tweak the sensitivity in the Inspector!
@export var sensitivity: float = 0.1

var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var target_material: ShaderMaterial

func _ready():
	# Wait a frame for the audio server to be ready
	await get_tree().process_frame
	
	# Check if the bus and effect exist
	if AudioServer.get_bus_count() <= music_bus_index:
		push_error("Music bus at index %d doesn't exist!" % music_bus_index)
		return
		
	var effect_count = AudioServer.get_bus_effect_count(music_bus_index)
	if effect_count <= spectrum_analyzer_index:
		push_error("Spectrum analyzer at index %d doesn't exist on bus %d!" % [spectrum_analyzer_index, music_bus_index])
		return
	
	# Get the spectrum analyzer instance from the audio server
	spectrum_instance = AudioServer.get_bus_effect_instance(music_bus_index, spectrum_analyzer_index)
	
	# Rest of your code...

func _process(delta):
	if not spectrum_instance or not target_material:
		return

	# 1. Get the loudness of the bass frequencies
	var magnitude = spectrum_instance.get_magnitude_for_frequency_range(bass_frequency_min, bass_frequency_max)
	
	# THE FIX IS HERE:
	# We now remap from a linear range [0.0 to sensitivity] to our output [0.0 to 1.0]
	var target_bass_value = remap(magnitude.length(), 0.0, sensitivity, 0.0, 1.0)
	
	# We still clamp to ensure the value never goes above 1.0
	target_bass_value = clamp(target_bass_value, 0.0, 1.0)
	
	# Smoothing remains the same and is very important
	var current_bass_value = target_material.get_shader_parameter("bass_level")
	var smoothed_bass = lerp(current_bass_value, target_bass_value, delta * 10.0)

	# 2. Pass the final value to the shader
	target_material.set_shader_parameter("bass_level", smoothed_bass)
	
	# Your print statement will now show much more interesting values!
	#print(magnitude.length(), " | ", current_bass_value, " | ", target_bass_value, " | ", smoothed_bass)
