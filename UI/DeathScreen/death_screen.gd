extends Control

@onready var background: Polygon2D = $BlurBackground

func _ready():
	setup_death_screen_polygon()
	#await get_tree().create_timer(0.5).timeout
#
	#play_appear_animation()

func setup_death_screen_polygon():
	var screen_size = get_viewport().get_visible_rect().size
	
	# Create starting points as a line along the top edge
	var start_points = create_top_line_start_points(screen_size)
	
	# Set initial state (collapsed to top line)
	background.polygon = PackedVector2Array(start_points)

func create_top_line_start_points(screen_size: Vector2) -> Array:
	# Find where the diagonal line intersects the top edge
	var angle = deg_to_rad(-60)
	var slope = tan(angle)
	var top_intersect_x = (0 - screen_size.y) / slope + screen_size.x * 0.35
	
	# Create a thin line along the top edge
	var points = []
	points.append(Vector2(screen_size.x, 0))  # Top-right corner
	points.append(Vector2(top_intersect_x, 0))  # Where diagonal meets top
	points.append(Vector2(top_intersect_x, 0))  # Same point (making it a line)
	points.append(Vector2(screen_size.x, 0))  # Back to top-right corner
	
	return points

func calculate_final_polygon_points(screen_size: Vector2) -> Array:
	var start_point = Vector2(screen_size.x * 0.35, screen_size.y)
	var angle = deg_to_rad(-60)
	var slope = tan(angle)
	
	var right_intersect_y = slope * (screen_size.x - screen_size.x * 0.35) + screen_size.y
	var top_intersect_x = (0 - screen_size.y) / slope + screen_size.x * 0.35
	
	var points = []
	points.append(Vector2(screen_size.x, screen_size.y))
	points.append(start_point)
	
	if right_intersect_y >= 0 and right_intersect_y <= screen_size.y:
		points.append(Vector2(screen_size.x, right_intersect_y))
	else:
		points.append(Vector2(top_intersect_x, 0))
		points.append(Vector2(screen_size.x, 0))
	
	return points

func play_appear_animation() -> void:
	# Start the polygon slide animation
	animate_polygon_slide()
	
	# Start the text animation (which waits 0.5s)
	$AnimationPlayer.play("Appear")

func animate_polygon_slide():
	var screen_size = get_viewport().get_visible_rect().size
	var final_points = calculate_final_polygon_points(screen_size)
	
	# Create a tween for the sliding animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)  # Exponential transition for the ease out effect
	
	# Animate the polygon from current position to final position
	tween.tween_property(background, "polygon", PackedVector2Array(final_points), 0.5)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_level()

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu/MainMenu.tscn")
