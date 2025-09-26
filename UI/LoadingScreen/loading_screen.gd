extends Control

@export_file("*.tscn") var next_scene_path: String

var progress = []
var scene_load_status = 0

func _ready() -> void:
	ResourceLoader.load_threaded_request(next_scene_path)

func _process(_delta: float) -> void:
	scene_load_status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	$Label.text = str(floor(progress[0]*100)) + "%"
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
