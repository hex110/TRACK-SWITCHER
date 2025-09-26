extends Control

@onready var play_button = $Menu/VBoxContainer/Play
@onready var settings_button = $Menu/VBoxContainer/Settings
@onready var quit_button = $Menu/VBoxContainer/Quit
@onready var credits_button = $Menu/MarginContainer/VBoxContainer/Credits
@onready var feedback_button = $Menu/MarginContainer/VBoxContainer/Feedback

@export var main_menu_song: Resource = preload("res://UI/MainMenu/MainMenuSong.wav")

@export var ui_manager: Control
@export var level_select: Control

@export var animation_player: AnimationPlayer

func _ready() -> void:
	get_tree().paused = false
	MusicManager.play_music(main_menu_song, "Main Menu Song")
	ui_manager.hide()
	level_select.connect("back_pressed", level_select_to_main_menu)
	level_select.show()
	level_select.force_update_transform()
	await get_tree().process_frame
	level_select.hide()

	credits_button.visible = GameManager.is_game_completed()

func level_select_to_main_menu():
	animation_player.play("LevelSelectToMainMenu")

func _on_play_pressed() -> void:
	animation_player.play("MainMenuToLevelSelect")


func _on_settings_pressed() -> void:
	ui_manager.open_settings()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/FinishGameScreen/FinishGameScreen.tscn")


func _on_feedback_pressed() -> void:
	open_feedback_form()


func open_feedback_form():
	var feedback_form = preload("res://UI/FeedbackForm/FeedbackForm.tscn").instantiate()
	get_tree().current_scene.add_child(feedback_form)
	feedback_form.feedback_closed.connect(_on_feedback_closed)


func _on_feedback_closed():
	pass
