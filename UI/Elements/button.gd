extends Button

@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var click_audio: AudioStreamPlayer = $ClickAudio

func _on_mouse_entered() -> void:
	hover_audio.play()
	add_theme_font_size_override("font_size", get_theme_font_size("font_size_hover"))


func _on_mouse_exited() -> void:
	add_theme_font_size_override("font_size", get_theme_default_font_size())


func _on_pressed() -> void:
	click_audio.play()
