# FallState.gd (FINALIZED)
class_name FallState
extends AirborneState

# enter() function is still needed to set is_sprint_jumping correctly
func enter() -> void:
	update_animation()
	if state_machine.previous_state:
		var previous_name = state_machine.previous_state.name
		if previous_name != "Jump":
			state_machine.is_sprint_jumping = (previous_name == "Dash")

func physics_update(delta: float) -> void:
	# Buffer jump input for coyote time
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		state_machine.buffer_jump()

	# Handle preemptive platform drop
	if Input.is_action_pressed("move_down") and player.is_on_floor() and state_machine.is_on_platform():
		player.start_preemptive_drop()

	# Let the parent do ALL physics, movement, and transition checks
	super.physics_update(delta)

# Override parent's transitions to add coyote jump check
func handle_transitions() -> bool:
	if state_machine.is_jump_buffered() and state_machine.can_coyote_jump():
		# Recharge dash on successful coyote jump since we were recently on ground
		state_machine.can_dash = true
		transition_to("Jump")
		return true

	# If no coyote jump, defer to parent's checks (air dash, landing)
	return super.handle_transitions()
