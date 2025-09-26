class_name PlayerMovementData
extends Resource

# Movement constants
@export_group("Basic Movement")
@export var speed = 150.0

@export_group("Jump")
@export var jump_velocity = -425.0 # from 2 to ~4.5 tiles of jump
@export var jump_release_multiplier = 5.0  # Higher = more gravity when releasing jump
@export var min_jump_height = 0.7  # Minimum jump height as fraction of full jump

@export_group("Dash")
@export var dash_speed = 600.0 # 6 tiles of dash
@export var dash_duration = 0.15

@export_group("Friction")
@export var friction = 8000.0  # How fast you stop when no input


@export_group("Physics")
@export var gravity_multiplier = 1.25  # Multiplier for default gravity

@export_group("Coyote Time & Buffering")
@export var coyote_time = 0.1
@export var jump_buffer_time = 0.1

@export_group("Debug")
