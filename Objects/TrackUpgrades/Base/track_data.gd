# track_data.gd
extends Resource
class_name TrackData

@export_group("Track Info")
## The name used by MusicManager (e.g., "PercussionLayer", "MelodyLayer")
@export var layer_name: String
## The user-friendly name to display in the UI (e.g., "Percussion")
@export var display_name: String
## An icon to show in the Level Select screen.
@export var icon: Texture2D
## The white version of the icon.
@export var icon_white: Texture2D

## --- NEW: BEAT DETECTION SETTINGS ---
@export_group("Beat Detection Settings")
## The minimum energy required to register a beat.
@export var beat_threshold: float = 0.15
## The minimum time (in seconds) that must pass before another beat can be detected.
@export var beat_cooldown: float = 0.15
