extends Control

@export var time_label: Label
@export var medal_icon: TextureRect
@export var medal_text: Label
@export var record_label: Label

@export var gold_medal: Texture2D
@export var silver_medal: Texture2D
@export var bronze_medal: Texture2D

var self_current_level_data: LevelData

func _ready():
	# Hide initially
	visible = false

func show_completion(completion_time: float, medal_type: String, is_new_record: bool, best_time: float, current_level_data: LevelData = null):
	# Format and show time
	time_label.text = format_time(completion_time)
	get_tree().paused = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	$AudioStreamPlayer.play()
	
	# Show medal
	match medal_type:
		"gold":
			medal_icon.texture = gold_medal
			medal_text.text = "GOLD!"
			medal_text.modulate = Color.GOLD
		"silver":
			medal_icon.texture = silver_medal
			medal_text.text = "SILVER!"
			medal_text.modulate = Color.LIGHT_GRAY
		"bronze":
			medal_icon.texture = bronze_medal
			medal_text.text = "BRONZE!"
			medal_text.modulate = Color(0.8, 0.5, 0.2)  # Bronze color
		_:
			medal_icon.visible = false
			medal_text.text = "Completed"
			medal_text.modulate = Color.WHITE
	
	# Show record info
	if is_new_record:
		record_label.text = "NEW RECORD!"
		record_label.modulate = Color.YELLOW
	else:
		record_label.text = "Best: " + format_time(best_time)
		record_label.modulate = Color.LIGHT_GRAY
	
	# Show the UI with animation
	visible = true
	var tween = create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Store level data for next level functionality
	self_current_level_data = current_level_data
	
	# Show next button and update text based on whether this is the last level
	if current_level_data:
		var next_level = GameManager.get_next_level_data(current_level_data.level_name)
		if next_level != null:
			$MarginContainer/VBoxContainer/VBoxContainer/NextLevel.text = "Next Level"
		else:
			$MarginContainer/VBoxContainer/VBoxContainer/NextLevel.text = "Next"
		$MarginContainer/VBoxContainer/VBoxContainer/NextLevel.visible = true

func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	return "Time: " + "%d:%02d" % [minutes, seconds]


func _on_next_level_pressed() -> void:
	if self_current_level_data:
		var next_level = GameManager.get_next_level_data(self_current_level_data.level_name)
		if next_level:
			GameManager.load_next_level(self_current_level_data.level_name)
		else:
			# This is the last level, load the finish game screen
			get_tree().paused = false
			get_tree().change_scene_to_file("res://UI/FinishGameScreen/FinishGameScreen.tscn")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_level()


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
