# IdleState.gd (CORRECTED)
class_name IdleState
extends GroundedState

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, movement_data.friction * delta)

	# Apply movement first
	player.move_and_slide()

	# Check for shared transitions after movement (jump, dash, fall). If one happens, stop immediately.
	if super.handle_transitions():
		return

	# State-specific transitions only run if no high-priority transition occurred
	var direction = state_machine.get_movement_direction()
	if direction != 0:
		transition_to("Walk")
		return
