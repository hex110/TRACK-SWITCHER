extends Area2D

signal level_completed

func _on_body_entered(body):
	print(body)
	if body.is_in_group("player"):
		level_completed.emit()
		# Optional: disable the flag so it can't be triggered again
		set_deferred("monitoring", false)
