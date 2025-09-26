class_name PlayerState
extends Node

var player: CharacterBody2D
var state_machine: PlayerStateMachine
var movement_data: PlayerMovementData
var animation_controller: AnimationController

func _ready():
	set_physics_process(false)
	set_process(false)

func enter() -> void:
	update_animation()

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

# Helper function to update animation
func update_animation() -> void:
	if animation_controller:
		animation_controller.update_animation(name)

# Helper function to transition to another state
func transition_to(state_name: String) -> void:
	state_machine.transition_to(state_name)
