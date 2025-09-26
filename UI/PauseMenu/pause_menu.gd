extends Control

signal back_requested
signal open_settings

@export var animation_player: AnimationPlayer

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true

func show_menu() -> void:
	# This function is called by the UIManager.
	animation_player.play("Appear")

func hide_menu() -> void:
	# This function is also called by the UIManager.
	animation_player.play("Disappear")

func _on_resume_pressed() -> void:
	emit_signal("back_requested")
	hide_menu()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_settings_pressed() -> void:
	emit_signal("open_settings")

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
