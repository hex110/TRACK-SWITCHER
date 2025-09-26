# music_player_ui.gd
extends VBoxContainer

# --- Node References ---
@onready var song_title_label: Label = $SongTitleLabel
@onready var current_time_label: Label = $ProgressContainer/CurrentTimeLabel
@onready var total_time_label: Label = $ProgressContainer/TotalTimeLabel
@onready var song_progress_bar: ProgressBar = $ProgressContainer/SongProgressBar


func _ready():
	# --- Connect to MusicManager signals ---
	# We use call_deferred to ensure the MusicManager is fully ready.
	MusicManager.song_changed.connect(_on_music_manager_song_changed)
	MusicManager.music_stopped.connect(_on_music_manager_music_stopped)
	
	# Connect to the progress bar's input signal
	song_progress_bar.gui_input.connect(_on_progress_bar_gui_input)
	
	# Start hidden, since no song is playing initially.
	hide()
	
	# Check if music started playing before it existed
	if MusicManager.is_playing():
		var current_song = MusicManager.get_current_song_name()
		var current_stream = MusicManager.get_current_song_stream()
		if current_song and current_stream:
			# Manually set up the UI with current song info
			song_title_label.text = "Now Playing: " + current_song
			total_time_label.text = _format_time(current_stream.get_length())
			song_progress_bar.value = 0
			current_time_label.text = "0:00"
			show()
	else:
		# Start hidden if no song is playing
		hide()


func _process(_delta):
	# If the UI is visible and music is playing, update the progress.
	if visible and MusicManager.is_playing():
		update_progress_ui()


# --- UI Update Logic ---

func update_progress_ui():
	var length = MusicManager.get_song_length()
	var songPosition = MusicManager.get_playback_position()
	
	if length > 0:
		# ProgressBar's value is from min_value to max_value (e.g., 0 to 100).
		song_progress_bar.value = (songPosition / length) * song_progress_bar.max_value
		current_time_label.text = _format_time(songPosition)


# --- Signal Handlers ---

# Called when MusicManager starts a new song.
func _on_music_manager_song_changed(song_name: String, song_stream: AudioStream):
	song_title_label.text = "Now Playing: " + song_name
	total_time_label.text = _format_time(song_stream.get_length())
	
	# Reset progress and show the UI element.
	song_progress_bar.value = 0
	current_time_label.text = "0:00"
	show()

# Called when MusicManager.stop_music() is called.
func _on_music_manager_music_stopped():
	hide()


# Called when the user clicks on the progress bar.
func _on_progress_bar_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Calculate the clicked position as a percentage (0.0 to 1.0).
		var click_percent = event.position.x / song_progress_bar.size.x
		click_percent = clampf(click_percent, 0.0, 1.0)
		
		# Calculate the target time in seconds.
		var target_position = MusicManager.get_song_length() * click_percent
		
		# Tell the MusicManager to seek to that position.
		MusicManager.seek_all_layers(target_position)
		
		# Update the UI immediately for a responsive feel.
		update_progress_ui()


# --- Helper Function ---

func _format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var remaining_seconds = int(seconds) % 60
	# The "%02d" format ensures we get "01", "02", etc.
	return "%d:%02d" % [minutes, remaining_seconds]
