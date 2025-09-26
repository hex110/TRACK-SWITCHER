# moving_head.gd
@tool
class_name MovingHead
extends ReactiveElement

@export_group("Head Behavior")
## The AnimatableBody2D that represents the head.
@export var head_body: AnimatableBody2D
## The AnimationPlayer that controls the head's animations.
@export var head_animation_player: AnimationPlayer
## An array of Marker2D nodes defining the patrol path in order.
@export var path_points: Array[Marker2D]
## The speed of the head in pixels per second.
@export var speed: float = 200.0
## The mandatory delay (in seconds) after hitting a point before it can move again.
@export var post_hit_delay: float = 0.5
## If true, the head only starts moving when the player steps on it.
@export var start_when_player_steps: bool = false
## The Area2D that detects when the player steps on the head.
@export var player_detector: Area2D

# --- Private State Variables ---
var _move_tween: Tween
var _current_target_index: int = 1
var _is_moving: bool = false
var _is_on_hit_delay: bool = false
var _player_has_stepped: bool = false


func _ready():
	super._ready() # Calls parent _ready(), which handles deactivation and music setup.

	if not _is_setup_valid():
		return

	# Set the head's starting position to the first point in the path.
	head_body.global_position = path_points[0].global_position
	# Start with the idle animation.
	if head_animation_player:
		head_animation_player.play("Blink")

	# Connect player detector signal if it exists
	if start_when_player_steps and is_instance_valid(player_detector):
		player_detector.body_entered.connect(_on_player_entered)

# We override these so the head is always visible, just inactive.
func activate():
	process_mode = Node.PROCESS_MODE_INHERIT

func deactivate():
	process_mode = Node.PROCESS_MODE_DISABLED
	# Stop any movement and reset state if deactivated.
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()
	_is_moving = false
	_is_on_hit_delay = false
	# Optionally reset to start position
	# if _is_setup_valid():
	#     head_body.global_position = path_points[0].global_position
	#     _current_target_index = 1


# This is the main trigger from the ReactiveElement parent.
func _on_beat():
	# Ignore the beat if the setup is invalid, it's already moving, or it's in the post-hit delay.
	if not _is_setup_valid() or _is_moving or _is_on_hit_delay:
		return

	# If we need to wait for player to step on the head, check if they have
	if start_when_player_steps and not _player_has_stepped:
		return

	_start_movement()


func _start_movement():
	_is_moving = true

	var start_pos = head_body.global_position
	var target_pos = path_points[_current_target_index].global_position
	
	# Stop the idle animation
	if head_animation_player:
		head_animation_player.stop()

	# Calculate movement duration based on distance and speed.
	var distance = start_pos.distance_to(target_pos)
	if speed <= 0 or distance <= 0:
		# Should not happen, but a good safeguard.
		_on_arrival()
		return
	
	var duration = distance / speed

	# Create a tween to handle the movement.
	_move_tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	_move_tween.tween_property(head_body, "global_position", target_pos, duration)
	# When the tween finishes, call the _on_arrival function.
	_move_tween.finished.connect(_on_arrival)


func _on_arrival():
	_is_moving = false
	
	# --- Play Hit Animation ---
	var last_point_index = (_current_target_index - 1 + path_points.size()) % path_points.size()
	var last_pos = path_points[last_point_index].global_position
	var current_pos = path_points[_current_target_index].global_position
	var move_vector = (current_pos - last_pos).normalized()

	var hit_animation = _get_hit_animation_from_vector(move_vector)
	if head_animation_player and head_animation_player.has_animation(hit_animation):
		head_animation_player.play(hit_animation)
	
	$AudioStreamPlayer2D.play()

	# --- Start Post-Hit Delay ---
	_is_on_hit_delay = true
	# Use a simple tween as a timer for the delay.
	var delay_tween = create_tween()
	delay_tween.tween_interval(post_hit_delay)
	# When the delay is over, reset the state and play the idle animation.
	delay_tween.finished.connect(func():
		_is_on_hit_delay = false
		if head_animation_player:
			head_animation_player.play("Blink")
	)

	# --- Update Target for Next Move ---
	# The modulo (%) operator makes the index wrap around to 0 when it reaches the end.
	_current_target_index = (_current_target_index + 1) % path_points.size()


# Helper function to determine animation name from movement direction.
func _get_hit_animation_from_vector(vector: Vector2) -> String:
	# Check if movement was primarily horizontal or vertical
	if abs(vector.x) > abs(vector.y):
		if vector.x > 0:
			return "Right Hit"
		else:
			return "Left Hit"
	else:
		if vector.y > 0:
			return "Bottom Hit"
		else:
			return "Top Hit"

# Called when the player enters the detector area.
func _on_player_entered(body: Node2D):
	# Assuming the player has a specific name or is in a specific group
	# You may need to adjust this check based on your player implementation
	if body.name == "Player" or body.is_in_group("player"):
		_player_has_stepped = true

# Helper function for validation.
func _is_setup_valid() -> bool:
	if not is_instance_valid(head_body): return false
	if not is_instance_valid(head_animation_player): return false
	if path_points.is_empty() or path_points.size() < 2:
		if not Engine.is_editor_hint():
			printerr("MovingHead needs at least 2 points in its path to function.", self)
		return false
	return true


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	head_animation_player.play("Blink")
