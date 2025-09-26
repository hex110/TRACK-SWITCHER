extends Control

signal level_started(selected_tracks: Array[TrackData])

@onready var background: Polygon2D = $BlurBackground
@export var tracks_container: VBoxContainer
@export var press_key_to_start: Label
@export var level_name: Label

@onready var tutorial: ColorRect = $BlurBackgroundTutorial

var current_level_data: LevelData
var selected_tracks: Array[String] = []
var base_level: BaseLevel

func _ready():
	GameManager.can_pause = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	update_diagonal_shape()
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_update_press_key_label()
	tutorial.visible = false
	
	$AudioStreamPlayer.play()
	
	if GameManager.track_tutorial == true:
		_show_track_tutorial()
		GameManager.track_tutorial = false

func update_diagonal_shape():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Start point: 65% across the bottom edge
	var start_point = Vector2(screen_size.x * 0.65, screen_size.y)
	
	# Calculate the diagonal line with 60 degrees
	var angle = deg_to_rad(60)
	var slope = tan(angle)
	
	# Line equation: y = slope * (x - start_x) + start_y
	# Find where this line intersects the left edge (x = 0)
	var left_intersect_y = slope * (0 - screen_size.x * 0.65) + screen_size.y
	
	# Find where this line intersects the top edge (y = 0)
	var top_intersect_x = (0 - screen_size.y) / slope + screen_size.x * 0.65
	
	var points = []
	
	# Always start with bottom-left corner
	points.append(Vector2(0, screen_size.y))
	
	# Add the starting point (65% across bottom)
	points.append(start_point)
	
	# Determine the end point of the diagonal line and close the polygon
	if left_intersect_y >= 0 and left_intersect_y <= screen_size.y:
		# Line intersects the left edge within screen bounds
		points.append(Vector2(0, left_intersect_y))
	else:
		# Line intersects the top edge within screen bounds
		points.append(Vector2(top_intersect_x, 0))
		# Add top-left corner to close the polygon
		points.append(Vector2(0, 0))
	
	background.position = Vector2.ZERO
	background.polygon = PackedVector2Array(points)

func set_level_data(level_data: LevelData):
	current_level_data = level_data
	selected_tracks.clear()
	if is_inside_tree():
		populate_tracks()
		update_level_name()

func set_base_level(level: BaseLevel):
	base_level = level

func populate_tracks():
	for child in tracks_container.get_children():
		child.queue_free()

	if not current_level_data or not current_level_data.collectible_tracks:
		return

	var unlocked_tracks_for_level = GameManager.get_unlocked_tracks(current_level_data.level_name)

	for track in current_level_data.collectible_tracks:
		if not track:
			continue

		var track_row = HBoxContainer.new()
		track_row.focus_mode = Control.FOCUS_NONE

		var icon = TextureRect.new()
		icon.texture = track.icon_white
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icon.custom_minimum_size = Vector2(32, 32)
		icon.size = Vector2(32, 32)
		icon.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER

		var checkbox = CheckButton.new()
		checkbox.text = track.display_name
		checkbox.focus_mode = Control.FOCUS_NONE
		checkbox.custom_minimum_size.x = 400
		checkbox.add_theme_font_size_override("font_size", 42)

		# Check if this track is currently active in MusicManager
		var is_active = MusicManager.is_layer_active(track.layer_name)
		var is_unlocked = track.layer_name in unlocked_tracks_for_level

		checkbox.button_pressed = is_active
		checkbox.disabled = not is_unlocked  # Disable if locked, but don't affect checked state

		# Gray out icon if track is locked
		if not is_unlocked:
			icon.modulate.a = 0.3

		if is_active:
			selected_tracks.append(track.layer_name)

		checkbox.pressed.connect(_on_track_checkbox_pressed.bind(track))

		track_row.add_child(icon)
		track_row.add_child(checkbox)
		tracks_container.add_child(track_row)

func _on_track_checkbox_pressed(track_data: TrackData):
	var checkbox = tracks_container.get_children().filter(func(row):
		return row.get_child(1).text == track_data.display_name
	)[0].get_child(1) as CheckButton

	if checkbox.button_pressed:
		if track_data.layer_name not in selected_tracks:
			selected_tracks.append(track_data.layer_name)
	else:
		selected_tracks.erase(track_data.layer_name)

	# Toggle the track in real-time using the same method as HUD UI
	MusicManager.set_layer_active(track_data.layer_name, checkbox.button_pressed, 0.5)

func get_selected_tracks() -> Array[String]:
	return selected_tracks

func _on_start_pressed() -> void:
	if not current_level_data:
		return

	var selected_track_data: Array[TrackData] = []
	for track_name in selected_tracks:
		for track in current_level_data.collectible_tracks:
			if track and track.layer_name == track_name:
				selected_track_data.append(track)
				break
	
	GameManager.can_pause = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	level_started.emit(selected_track_data)

func _input(event):
	if visible and _is_jump_action(event):
		_on_start_pressed()

func _is_jump_action(event) -> bool:
	var keybinds = ConfigFileHandler.load_keybinds()

	if not keybinds.has("jump"):
		return false

	var bound_event = keybinds["jump"]

	if event is InputEventKey and bound_event is InputEventKey:
		if event.keycode == bound_event.keycode and event.pressed:
			return true
	elif event is InputEventMouseButton and bound_event is InputEventMouseButton:
		if event.button_index == bound_event.button_index and event.pressed:
			return true

	return false

func _update_press_key_label():
	if not press_key_to_start:
		return

	var keybinds = ConfigFileHandler.load_keybinds()
	var key_name = "?"

	if keybinds.has("jump"):
		var event = keybinds["jump"]
		if event is InputEventKey:
			key_name = OS.get_keycode_string(event.keycode).to_lower()
		elif event is InputEventMouseButton:
			key_name = "mouse " + str(event.button_index)

	press_key_to_start.text = "(press {0} to start)".format([key_name])

func update_level_name():
	if not level_name or not current_level_data:
		return

	level_name.text = current_level_data.display_name

func _show_track_tutorial() -> void:
	tutorial.modulate.a = 0.0
	tutorial.visible = true
	var tween = create_tween()
	tween.tween_property(tutorial, "modulate:a", 1.0, 0.5)

func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
