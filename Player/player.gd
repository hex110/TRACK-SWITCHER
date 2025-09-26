# Player.gd
extends CharacterBody2D

#@onready var jump_sound = $JumpBass
#@onready var dash_sound = $DashDrum
@onready var state_machine = $StateMachine
@onready var UI = $UI

@onready var platform_drop_timer = $PlatformDropTimer
@onready var preemptive_drop_timer = $PreemptiveDropTimer
const PLATFORM_LAYER = 5

@export var ui_manager: Control

@export var anim_player: AnimationPlayer

# Add these near your other variables at the top of the script
@export var death_knockback_distance: float = 60.0
@export var death_knockback_duration: float = 0.4

var is_dead: bool = false
var last_velocity := Vector2.ZERO
  

func _ready():
	# State machine will handle all movement logic
	UI.visible = true

func _process(_delta: float) -> void:
	last_velocity = velocity

	# Check if player is standing on a die tile
	if state_machine.is_on_die_tile():
		die()

func die():
	# 1. Prevent the function from running more than once
	if is_dead:
		return
	is_dead = true
	
	GameManager.can_pause = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	process_mode = Node.PROCESS_MODE_DISABLED
	anim_player.play("Die")
	await get_tree().create_timer(anim_player.current_animation_length).timeout
	#GameManager.restart_level()
	get_tree().paused = true

func hide_ui() -> void:
	UI.hide()

func stop() -> void:
	state_machine.transition_to("Idle")

# This function is called by FallState when landing with 'down' held.
func start_preemptive_drop():
	preemptive_drop_timer.start()

# This function is called by our grounded states for an immediate drop.
func drop_through_platform():
	# Temporarily disable collision with the 'platforms' layer.
	set_collision_mask_value(PLATFORM_LAYER, false)
	# Start the timer to re-enable collision shortly after.
	platform_drop_timer.start()
	# Give a stronger downward push to ensure we're clearly falling
	velocity.y = 100

func _on_platform_drop_timer_timeout():
	# Re-enable collision with the 'platforms' layer.
	set_collision_mask_value(PLATFORM_LAYER, true)

# Connect the 'PreemptiveDropTimer' timeout signal to this.
func _on_preemptive_drop_timer_timeout():
	# Before dropping, one last check to ensure we are still on a platform.
	# This prevents dropping in mid-air if the player walked off the edge
	# during the 0.1s delay.
	if state_machine.is_on_platform():
		drop_through_platform()
		state_machine.transition_to("Fall")


func _on_secret_zone_detect_body_entered(body: Node2D) -> void:
	print("in secret zone")
	body.visible = true
	body.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(body, "modulate:a", 0.0, 0.25)
	await tween.finished
	body.visible = false

func _on_secret_zone_detect_body_exited(body: Node2D) -> void:
	print("out of secret zone")
	body.visible = true
	body.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(body, "modulate:a", 1.0, 0.25)
