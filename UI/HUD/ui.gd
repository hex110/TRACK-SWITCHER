extends CanvasLayer

@onready var song_control: VBoxContainer = $SongControl
@onready var timer_label: Label = $TimerLabel

var level_timer: LevelTimer

func _ready() -> void:
	var tween = create_tween()
	song_control.modulate.a = 0.0
	tween.tween_property(song_control, "modulate:a", 1.0, 0.5)

	var level_scene = get_tree().current_scene
	level_timer = level_scene.get_node_or_null("LevelTimer")

func _process(_delta: float) -> void:
	if level_timer and level_timer.is_running:
		var time = level_timer.get_completion_time()
		timer_label.text = format_time(time)

func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60
	var remaining_seconds = total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]

func die() -> void:
	var tween = create_tween()
	tween.tween_property(song_control, "modulate:a", 0.0, 0.5)
