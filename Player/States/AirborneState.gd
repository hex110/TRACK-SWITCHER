# AirborneState.gd (FINALIZED)
class_name AirborneState
extends PlayerState

func physics_update(delta: float) -> void:
	# 1. Ask the current state for the correct gravity and apply it
	var gravity_multiplier = _get_gravity_multiplier()
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_multiplier
	player.velocity.y += gravity * delta

	# 2. Handle horizontal air movement
	var direction = state_machine.get_movement_direction()
	state_machine.update_facing_direction(direction)

	if direction != 0:
		var target_speed = movement_data.speed
		if state_machine.is_sprint_jumping:
			target_speed = movement_data.dash_speed
		player.velocity.x = target_speed * direction
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, movement_data.friction * 0.5 * delta)

	# 3. Handle transitions. If one happens, stop immediately.
	if handle_transitions():
		return

	# 4. Apply movement
	player.move_and_slide()

# This is the "virtual" function. Children can override it.
# By default, it returns the standard gravity multiplier.
func _get_gravity_multiplier() -> float:
	return movement_data.gravity_multiplier

# Change the function signature to return a bool
func handle_transitions() -> bool:
	# 1. Air Dash
	if Input.is_action_just_pressed("dash") and state_machine.can_dash:
		transition_to("Dash")
		return true

	# 2. Land on ground - but only if we have a real floor collision (not wall collision)
	if player.is_on_floor() and state_machine.platform_drop_grace_timer <= 0 and _has_floor_collision():
		state_machine.is_sprint_jumping = false

		if state_machine.is_jump_buffered():
			transition_to("Jump")
		else:
			var direction = state_machine.get_movement_direction()
			if direction != 0:
				transition_to("Walk")
			else:
				transition_to("Idle")
				# Only play land animation if we're actually landing (not buffering a jump)
				if animation_controller:
					animation_controller.update_animation("Land")
		return true
	
	return false

# Helper function to check if we have a real floor collision (normal pointing up)
# This prevents wall collisions from being detected as landing surfaces
func _has_floor_collision() -> bool:
	for i in range(player.get_slide_collision_count()):
		var collision = player.get_slide_collision(i)
		# Check if collision normal points upward (indicating a floor)
		if collision.get_normal().dot(Vector2.UP) > 0.7:  # Allow slight slopes
			return true
	return false
