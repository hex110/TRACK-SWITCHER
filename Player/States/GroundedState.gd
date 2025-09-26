# GroundedState.gd (CORRECTED)
class_name GroundedState
extends PlayerState

# Change the function signature to return a bool
func handle_transitions() -> bool:
	# PRIORITY 1: Fall off a ledge (but respect platform drop grace period)
	if not player.is_on_floor() and state_machine.platform_drop_grace_timer <= 0:
		transition_to("Fall")
		return true # Report that a transition happened

	# PRIORITY 2: Dash
	if Input.is_action_just_pressed("dash"):
		if state_machine.can_dash:
			transition_to("Dash")
			return true # Report that a transition happened
	
	# PRIORITY 3: Jump (only if jump input isn't suppressed)
	if state_machine.jump_input_suppress_timer <= 0:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
			state_machine.buffer_jump()

		if state_machine.is_jump_buffered() and (player.is_on_floor() or state_machine.can_coyote_jump()):
			state_machine.is_sprint_jumping = false
			transition_to("Jump")
			return true # Report that a transition happened
	
	# PRIORITY 4: Drop through platform (immediate or held)
	if (Input.is_action_just_pressed("move_down") or Input.is_action_pressed("move_down")) and state_machine.is_on_platform():
		state_machine.start_platform_drop_grace()  # Start grace period
		player.drop_through_platform()
		transition_to("Fall")
		return true # Report that a transition happened
	
	# If we got this far, no transition happened
	return false
