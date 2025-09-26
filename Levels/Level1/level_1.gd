extends BaseLevel

# --- NEW music_stems FORMAT ---
# Each layer is a dictionary with a "primary" stream (for its own bus)
# and an optional "addon" stream (which plays on the "Base" bus).
var music_stems = {
	"BaseLayer": {
		"primary": preload("res://Levels/Level1/Level1BaseShopping.wav")
	}
}

func _setup_level_specific():
	# You can still use this for things unique to this level, if needed.
	pass

func _start_level_specific():
	MusicManager.play_dynamic_music(music_stems, "Shopping")
