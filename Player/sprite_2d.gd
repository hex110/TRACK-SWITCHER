extends Sprite2D

var player: CharacterBody2D

func _ready() -> void:
	player = get_parent()

func die() -> void:
	var knockback_direction = player.last_velocity.normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.UP
	var tween = create_tween()
	
	# We want to move in the OPPOSITE direction of the player's last movement
	var target_position_x = player.global_position.x - (knockback_direction.x * player.death_knockback_distance)
	var target_position_y = player.global_position.y + (knockback_direction.y * player.death_knockback_distance)
	
	var target_position = Vector2(target_position_x, target_position_y)
	
	#print(knockback_direction, player.global_position, target_position)
	
	# Set up the tween:
	# - Animate the `global_position` property of `self` (the Player node)
	# - Move it to the `target_position`
	# - Take `death_knockback_duration` seconds to do it
	# - Use an easing function to make it look smooth (starts fast, slows down at the end)
	tween.tween_property(self, "global_position", target_position, player.death_knockback_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
