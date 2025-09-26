# level_timer.gd
extends Control
class_name LevelTimer

@export var bronze_time: float = 45.0 
@export var silver_time: float = 30.0 
@export var gold_time: float = 15.0

var start_time: float
var end_time: float
var is_running: bool = false

signal level_completed(completion_time: float, medal_type: String)

func start_timer():
	start_time = Time.get_unix_time_from_system()
	is_running = true

func stop_timer():
	if is_running:
		end_time = Time.get_unix_time_from_system()
		is_running = false
		var completion_time = floor(end_time - start_time)
		var medal = get_medal_type(completion_time)
		level_completed.emit(completion_time, medal)

func get_completion_time() -> float:
	if is_running:
		return Time.get_unix_time_from_system() - start_time
	else:
		return end_time - start_time

func get_medal_type(time: float) -> String:
	if time <= gold_time:
		return "gold"
	elif time <= silver_time:
		return "silver" 
	elif time <= bronze_time:
		return "bronze"
	else:
		return "none"
