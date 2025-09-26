extends CanvasLayer

@export var finish_song: Resource

func _ready() -> void:
	MusicManager.play_music(finish_song, "Finish Game Song")
	GameManager.mark_game_completed()


func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
