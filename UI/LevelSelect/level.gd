@tool
extends Control

@export var level_data: LevelData : set = set_level_data
@export var is_level_unlocked: bool = true : set = set_level_unlocked

@export var gold_medal: Texture2D
@export var silver_medal: Texture2D
@export var bronze_medal: Texture2D

@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var track_icons_container: HBoxContainer = $TrackIconsContainer

var level_load: PackedScene = null
var hover_timer: Timer = null
var is_mouse_over: bool = false

func set_level_data(value: LevelData):
	level_data = value
	if is_inside_tree():
		update_display()

func set_level_unlocked(value: bool):
	is_level_unlocked = value
	if is_inside_tree():
		update_display()

func update_display():
	if not level_data:
		return

	$LevelName.text = level_data.display_name
	$TextureRect.texture = level_data.level_image

	# Show locked/unlocked state
	if not is_level_unlocked:
		# Dim the entire level button for locked levels
		modulate = Color(0.8, 0.8, 0.8, 1)
		$BestTime.text = "LOCKED"
		hide_medal()
		clear_track_icons()
	else:
		# Normal appearance for unlocked levels
		modulate = Color.WHITE
		if not Engine.is_editor_hint():
			var best_time = GameManager.get_best_time(level_data.level_name)
			if best_time > 0:
				$BestTime.text = format_time(best_time)
				show_medal(best_time)
			else:
				$BestTime.text = "Not completed"
				hide_medal()
			update_track_icons()

func update_track_icons():
	# Clear any old icons first
	clear_track_icons()

	if not level_data or not level_data.collectible_tracks:
		return

	# Get the list of tracks the player has actually unlocked for this level
	var unlocked_tracks_for_level = GameManager.get_unlocked_tracks(level_data.level_name)

	# Create an icon for every *possible* track in the level
	for track in level_data.collectible_tracks:
		if not track: continue # Skip empty slots in the array

		var icon_rect = TextureRect.new()
		icon_rect.texture = track.icon
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER

		# If the track's layer_name is in our saved list, it's unlocked.
		if track.layer_name in unlocked_tracks_for_level:
			# Full color for unlocked
			icon_rect.modulate = Color.WHITE
			icon_rect.tooltip_text = track.display_name + " (Collected)"
		else:
			# Dim the icon if it's locked
			icon_rect.modulate = Color(0.2, 0.2, 0.2, 0.2)
			icon_rect.tooltip_text = track.display_name + " (Missing)"

		track_icons_container.add_child(icon_rect)

func clear_track_icons():
	for child in track_icons_container.get_children():
		child.queue_free()


func show_medal(time: float):
	var medal_type = GameManager.get_medal_type(level_data.level_name, time)
	
	# Assuming you have a medal icon in your level button scene
	var medal_icon = $Medal  # Add this node to your level button scene
	
	match medal_type:
		"gold":
			medal_icon.texture = gold_medal  # You'll need to export these
			medal_icon.visible = true
		"silver":
			medal_icon.texture = silver_medal
			medal_icon.visible = true
		"bronze":
			medal_icon.texture = bronze_medal
			medal_icon.visible = true
		_:
			medal_icon.visible = false

func hide_medal():
	if has_node("Medal"):
		$Medal.visible = false

func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	return "%d:%02d" % [minutes, seconds]

func _ready():
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.5
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_load_level_scene)
	add_child(hover_timer)
	update_display()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_display()

func _on_mouse_entered() -> void:
	is_mouse_over = true
	if is_level_unlocked:
		scale = Vector2(1.25, 1.25)
		hover_audio.play()
		if level_data:
			hover_timer.start()

func _on_mouse_exited() -> void:
	is_mouse_over = false
	if is_level_unlocked:
		scale = Vector2(1, 1)
	hover_timer.stop()
	level_load = null

func _load_level_scene():
	if level_data:
		level_load = load(level_data.scene_path)
