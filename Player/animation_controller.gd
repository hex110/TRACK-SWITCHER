class_name AnimationController
extends Node

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

@export var state_machine: PlayerStateMachine

func update_direction(direction: int):
	# Handle sprite flipping
	if sprite and direction != 0:
		sprite.flip_h = direction < 0

func update_animation(state_name: String):
	# This is called by each state when it needs to update animation
	
	if animation_player.current_animation != state_name:
		animation_player.play(state_name)

func get_animation_name_old(state_name: String, direction: int) -> String:
	var dir_suffix = "Right" if direction >= 0 else "Right"
	
	match state_name:
		"Idle":
			return "Idle" + dir_suffix
		"Walk":
			return "Walk" + dir_suffix
		"Dash":
			return "Dash" + dir_suffix
		"Jump":
			return "Jump" + dir_suffix
		"Fall":
			return "Fall" + dir_suffix
		_:
			return "Idle" + dir_suffix
