# WalkState.gd (CORRECTED)
class_name WalkState
extends GroundedState

func physics_update(_delta: float) -> void:
	var direction = state_machine.get_movement_direction()
	state_machine.update_facing_direction(direction)
	player.velocity.x = movement_data.speed * direction

	# Apply movement first
	player.move_and_slide()

	# Check for shared transitions after movement (jump, dash, fall). If one happens, stop immediately.
	if super.handle_transitions():
		return

	# State-specific transitions only run if no high-priority transition occurred
	if direction == 0:
		transition_to("Idle")
		return
