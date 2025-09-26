extends Area2D
class_name BaseTrackUpgrade

# Use our new resource!
@export var track_data: TrackData

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var blur_rect: ColorRect = $CanvasLayer/BlurRect

var current_level_name: String
# NEW: A state variable to track if this was already unlocked on level start.
var is_already_unlocked: bool = false

var default_delta

func _ready():
	# Add to group for easy discovery
	add_to_group("track_upgrades")

	# Get the level name from the parent BaseLevel node.
	var owner_level = get_owner()
	if owner_level is BaseLevel and owner_level.level_data:
		current_level_name = owner_level.level_data.level_name
	else:
		push_error("BaseTrackUpgrade could not find a BaseLevel owner with LevelData!")
		queue_free() # Can't function without it
		return

	if not track_data:
		push_error("TrackData not assigned to this BaseTrackUpgrade instance!")
		queue_free()
		return
	
	# --- MODIFIED LOGIC ---
	# Instead of disappearing, we check the status, set our state, and change appearance.
	is_already_unlocked = GameManager.is_track_unlocked(current_level_name, track_data.layer_name)
	
	if is_already_unlocked:
		# Apply a "faded out" effect. Making it semi-transparent is a good way.
		# You can adjust this value to your liking.
		modulate.a = 0.5

func _process(_delta: float) -> void:
	if anim_player.is_playing():
		anim_player.advance(0.005)

func _on_body_entered(body: Node2D) -> void:
	# Make sure it's the player and that we haven't already started the collection animation
	if body.is_in_group("player") and not $CollisionShape2D.disabled:
		# This part runs for BOTH new and repeat collections to give player feedback.
		# Disable collision so it can't be triggered again in this session.
		$CollisionShape2D.set_deferred("disabled", true)
		# Play the collection animation
		if is_already_unlocked:
			anim_player.play("CollectedAlready")
		else:
			anim_player.play("Collected")
			# Use properties from our resource
			$CanvasLayer/LayerLabel.text = track_data.display_name + " track unlocked!"

						# Create dramatic time dilation effect
			var tween = create_tween()
			tween.tween_method(_set_time_scale, 0.5, 0, 0.25)

			# Add music blur effect
			GameManager.blur_music(1.0)

			# Add radial blur effect
			_start_radial_blur()

			# Add screen shake effect
			GameManager.screen_shake(3.0, 1.0, 30.0)

			# Tell the managers what happened
			GameManager.unlock_track_for_level(current_level_name, track_data.layer_name)

			# Add this track to the configured layers and apply immediately
			var current_layers = MusicManager.get_configured_layers()
			current_layers.append(track_data)
			MusicManager.configure_layers(current_layers)
			
			
			await tween.finished
			_set_time_scale(1)

func _set_time_scale(value: float) -> void:
	Engine.time_scale = value

func _start_radial_blur() -> void:
	# Use the existing BlurRect node
	blur_rect.visible = true

	# Make the rect transparent (we only want the shader effect)
	blur_rect.color = Color.TRANSPARENT

	# Set blur center to the upgrade's screen position
	var screen_pos = get_global_transform_with_canvas().origin
	var viewport_size = get_viewport().get_visible_rect().size
	var blur_center = Vector2(screen_pos.x / viewport_size.x, screen_pos.y / viewport_size.y)
	blur_rect.material.set_shader_parameter("blur_center", blur_center)

	# Show the canvas layer
	$CanvasLayer.visible = true

	# Animate the blur effect
	var blur_tween = create_tween()
	blur_tween.tween_method(_set_blur_strength, 0.0, 1.0, 0.3)
	blur_tween.tween_method(_set_blur_strength, 1.0, 0.0, 0.7)
	blur_tween.tween_callback(_hide_blur_rect)

func _set_blur_strength(strength: float) -> void:
	if blur_rect and blur_rect.material:
		blur_rect.material.set_shader_parameter("blur_strength", strength)

func _hide_blur_rect() -> void:
	blur_rect.visible = false


func _collected_anim_finish() -> void:
	# The object still disappears after the animation, but only for the current playthrough.
	#queue_free()
	Engine.time_scale = 1.0  # Reset time scale
	GameManager.restore_music(0.5)  # Restore music over 0.5 seconds

	# Small delay to let music restore before scene reload
	#await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()
