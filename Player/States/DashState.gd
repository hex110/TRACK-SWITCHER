# DashState.gd
class_name DashState
extends PlayerState

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var jump_buffered_during_dash: bool = false

func enter() -> void:
	update_animation()

	# Check for current frame input using individual actions for better timing
	var input_dir = 0.0
	if Input.is_action_pressed("move_right"):
		input_dir = 1.0
	elif Input.is_action_pressed("move_left"):
		input_dir = -1.0

	# Only use facing direction if truly no input is being pressed
	if input_dir == 0:
		input_dir = state_machine.facing_direction

	dash_direction = Vector2(input_dir, 0).normalized()
	dash_timer = movement_data.dash_duration
	state_machine.can_dash = false
	jump_buffered_during_dash = false
	
	# Set dash velocity
	player.velocity.x = dash_direction.x * movement_data.dash_speed
	
	
	# Play dash sound if available
	#if player.has_node("DashDrum"):
	#	player.get_node("DashDrum").play()

func physics_update(delta: float) -> void:
	# Set dash physics
	player.velocity.y = 0.0  # No gravity during dash
	player.velocity.x = dash_direction.x * movement_data.dash_speed

	# Update dash timer
	dash_timer -= delta

	# Check for jump input in the second half of dash
	if dash_timer <= movement_data.dash_duration * 0.5:
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			jump_buffered_during_dash = true
			state_machine.buffer_jump()

	# Check if dash is complete
	if dash_timer <= 0:
		exit_dash()
		return

	# Apply movement only if dash continues
	player.move_and_slide()

func exit_dash() -> void:
	# Check if we have a buffered jump from during the dash - only allow if on ground when dash ends
	if jump_buffered_during_dash and player.is_on_floor():
		# Recharge dash since we're able to jump (theoretically on ground)
		state_machine.can_dash = true
		# Maintain some horizontal momentum from the dash
		player.velocity.x = dash_direction.x * movement_data.speed
		transition_to("Jump")
		return

	# After dash, reduce velocity and transition based on current input
	player.velocity.x *= 0.5

	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		transition_to("Walk")
	else:
		transition_to("Idle")

func handle_transitions() -> void:
	# Dash state handles its own exit in exit_dash()
	pass
