# level_select.gd
extends Control

signal back_pressed

@export var levels_container: HBoxContainer

@onready var click_audio: AudioStreamPlayer = $ClickAudio

func _ready():
	call_deferred("populate_levels")

func populate_levels():
	# Clear existing levels
	for child in levels_container.get_children():
		child.queue_free()

	# Add unlocked levels from database
	for level_data in GameManager.level_database:
		var level_button = preload("res://UI/LevelSelect/level.tscn").instantiate()
		level_button.level_data = level_data
		level_button.is_level_unlocked = GameManager.is_level_unlocked(level_data.level_name)
		levels_container.add_child(level_button)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		for level_button in levels_container.get_children():
			if level_button.is_mouse_over and level_button.is_level_unlocked:
				click_audio.play()
				GameManager.load_screen_to_scene(level_button.level_data.scene_path)

func _on_back_button_pressed() -> void:
	emit_signal("back_pressed")
