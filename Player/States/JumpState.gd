# JumpState.gd (FINALIZED - FIXES FLOATING BUG)
class_name JumpState
extends AirborneState

var min_jump_velocity: float
var jump_grace_timer: float = 0.0

func enter() -> void:
	# Ensure jump animation is set immediately
	if animation_controller:
		animation_controller.update_animation("Jump")

	player.velocity.y = movement_data.jump_velocity
	state_machine.consume_jump_buffer()

	min_jump_velocity = movement_data.jump_velocity * movement_data.min_jump_height
	jump_grace_timer = 0.1  # Small grace period to prevent immediate landing detection

func physics_update(delta: float) -> void:
	# Update grace timer
	jump_grace_timer -= delta

	# Let the parent do ALL physics and movement.
	# It will call our _get_gravity_multiplier() function automatically.
	super.physics_update(delta)

# We override the parent's gravity logic here.
func _get_gravity_multiplier() -> float:
	var jump_held = Input.is_action_pressed("jump") or Input.is_action_pressed("ui_accept")

	# If player releases jump button while moving up fast, apply extra gravity
	if not jump_held and player.velocity.y < 0 and player.velocity.y > min_jump_velocity:
		return movement_data.jump_release_multiplier

	# Otherwise, use the default gravity
	return movement_data.gravity_multiplier

# We override the parent's transitions to add the "fall" check
func handle_transitions() -> bool:
	# HIGHEST PRIORITY: Air dash (allow dashing even at the moment of falling)
	if Input.is_action_just_pressed("dash") and state_machine.can_dash:
		transition_to("Dash")
		return true

	# PRIORITY 2: Check if we've started falling
	if player.velocity.y > 0.0:
		transition_to("Fall")
		return true

	# During grace period, don't allow landing transitions
	if jump_grace_timer > 0.0:
		return false

	# If we are not falling and grace period is over, defer to the parent's checks (landing)
	return super.handle_transitions()
