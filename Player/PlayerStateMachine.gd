# PlayerStateMachine.gd
class_name PlayerStateMachine
extends Node

@export var initial_state: NodePath
@export var movement_data: PlayerMovementData

@export var anim_controller: AnimationController

@export var collision_shape: CollisionShape2D

var current_state: PlayerState
var previous_state: PlayerState
var states: Dictionary = {}
var player: CharacterBody2D

# Shared state variables
var facing_direction: int = 1
var can_dash: bool = true
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_sprint_jumping: bool = false  # Track if we should maintain dash speed in air
var platform_drop_grace_timer: float = 0.0  # Prevents immediate re-grounding after platform drop
var platform_drop_input_suppress_timer: float = 0.0  # Suppresses horizontal input briefly after platform drop
var jump_input_suppress_timer: float = 0.0  # Suppresses jump input briefly after level start

func _ready():
	if not movement_data:
		movement_data = PlayerMovementData.new()
	
	player = get_parent() as CharacterBody2D
	
	# Initialize all child states
	for child in get_children():
		if child is PlayerState:
			states[child.name] = child
			child.player = player
			child.state_machine = self
			child.movement_data = movement_data
			child.animation_controller = anim_controller
	
	# Set initial state
	if initial_state:
		current_state = get_node(initial_state)
		current_state.enter()

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)
	
	# Update timers that persist across states
	update_timers(delta)

func _unhandled_input(event):
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: String) -> void:
	if not states.has(state_name):
		push_warning("State " + state_name + " does not exist")
		return
	
	if current_state and current_state.name == state_name:
		return # Avoid re-entering the same state
	
	if current_state:
		current_state.exit()
	
	previous_state = current_state
	current_state = states[state_name]
	current_state.enter()
	

func update_timers(delta: float) -> void:
	# Update coyote timer
	if not player.is_on_floor():
		coyote_timer -= delta
	else:
		coyote_timer = movement_data.coyote_time
		# Reset dash when landing (unless we're in dash state)
		if current_state.name != "Dash":
			can_dash = true

	# Update jump buffer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Update platform drop grace timer
	if platform_drop_grace_timer > 0:
		platform_drop_grace_timer -= delta

	# Update platform drop input suppression timer
	if platform_drop_input_suppress_timer > 0:
		platform_drop_input_suppress_timer -= delta

	# Update jump input suppression timer
	if jump_input_suppress_timer > 0:
		jump_input_suppress_timer -= delta

func update_facing_direction(direction: float) -> void:
	if direction != 0:
		facing_direction = sign(direction)
	
	anim_controller.update_direction(facing_direction)

func is_jump_buffered() -> bool:
	return jump_buffer_timer > 0

func can_coyote_jump() -> bool:
	return coyote_timer > 0

func buffer_jump() -> void:
	jump_buffer_timer = movement_data.jump_buffer_time

func consume_jump_buffer() -> void:
	jump_buffer_timer = 0
	coyote_timer = 0

func start_platform_drop_grace() -> void:
	platform_drop_grace_timer = 0.1  # 0.1 second grace period
	# Only suppress horizontal input if player is hitting a wall
	if is_hitting_wall():
		platform_drop_input_suppress_timer = 0.15  # Suppress horizontal input for 0.15 seconds

func suppress_jump_input(duration: float = 0.2) -> void:
	jump_input_suppress_timer = duration

func is_hitting_wall() -> bool:
	if not collision_shape:
		return false

	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir == 0:
		return false

	var shape = collision_shape.shape
	var shape_width = shape.size.x
	var shape_height = shape.size.y

	# Check the side the player is trying to move towards
	var check_offset = shape_width * 0.6 * sign(input_dir)
	var center_pos = player.global_position

	# Check multiple points along the player's side
	var check_points = [
		center_pos + Vector2(check_offset, -shape_height * 0.3),
		center_pos + Vector2(check_offset, 0),
		center_pos + Vector2(check_offset, shape_height * 0.3)
	]

	var space_state = player.get_world_2d().direct_space_state

	for point in check_points:
		var query = PhysicsRayQueryParameters2D.create(point, point + Vector2(check_offset * 0.2, 0))
		query.collision_mask = player.collision_mask
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider

			# Check if it's a wall (not a platform)
			if collider is TileMapLayer:
				var tilemap: TileMapLayer = collider
				var map_coords = tilemap.local_to_map(tilemap.to_local(result.position))
				var tile_data: TileData = tilemap.get_cell_tile_data(map_coords)

				if tile_data:
					# If it's not a one-way platform, it's a wall
					if not (tile_data.get_collision_polygons_count(2) > 0 and tile_data.is_collision_polygon_one_way(2, 0)):
						return true
			else:
				# For regular collision objects, check if it's NOT on platform layer
				if not (collider.collision_layer & (1 << 4)):
					return true

	return false

func get_movement_direction() -> float:
	# During platform drop input suppression, ignore horizontal input
	if platform_drop_input_suppress_timer > 0:
		return 0.0
	return Input.get_axis("move_left", "move_right")



# Checks if the player is currently on the floor AND if that floor is a platform.
# Uses direct raycasting instead of relying on slide collisions to avoid wall collision interference
func is_on_platform() -> bool:
	if not player.is_on_floor():
		return false

	if not collision_shape:
		push_warning("PlayerStateMachine needs a reference to the player's CollisionShape2D.")
		return false

	var shape = collision_shape.shape
	var shape_width = shape.size.x
	var horizontal_offset = shape_width * 0.45

	# Define the two points we will check, in global space.
	var bottom_center_pos = player.global_position + Vector2(0, shape.size.y / 2)
	var left_check_pos = bottom_center_pos - Vector2(horizontal_offset, 0)
	var right_check_pos = bottom_center_pos + Vector2(horizontal_offset, 0)

	var check_points = [left_check_pos, right_check_pos]
	var platforms_found = 0
	var normal_tiles_found = 0

	# Use direct raycasting downward to detect what's below us
	var space_state = player.get_world_2d().direct_space_state

	for point in check_points:
		# Cast a short ray downward from each check point
		var query = PhysicsRayQueryParameters2D.create(point, point + Vector2(0, 5))
		query.collision_mask = player.collision_mask  # Use same mask as player
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider

			if collider is TileMapLayer:
				var tilemap: TileMapLayer = collider
				var map_coords = tilemap.local_to_map(tilemap.to_local(result.position))
				var tile_data: TileData = tilemap.get_cell_tile_data(map_coords)

				if tile_data:
					if tile_data.get_collision_polygons_count(2)>0 and tile_data.is_collision_polygon_one_way(2, 0):
						platforms_found += 1
					else:
						# This is a normal tile (not a platform)
						normal_tiles_found += 1
			else:
				# Handle regular collision objects (not tilemaps)
				# Check if the collider is on collision layer 5 (platform layer)
				if collider.collision_layer & (1 << 4):  # Layer 5 is bit 4 (0-indexed)
					platforms_found += 1
				else:
					normal_tiles_found += 1

	# Return true only if we have platforms and no normal tiles
	# (either both corners on platforms, or one platform + one empty space)
	return platforms_found > 0 and normal_tiles_found == 0

# Checks if the player is currently touching a die tile/object by examining collision polygons on layer 1 (die layer) or collision layer 3
func is_on_die_tile() -> bool:
	if not collision_shape:
		push_warning("PlayerStateMachine needs a reference to the player's CollisionShape2D.")
		return false

	var shape = collision_shape.shape
	var shape_width = shape.size.x
	var shape_height = shape.size.y
	var horizontal_offset = shape_width * 0.5

	# Define the four corner points we will check, in global space.
	var bottom_center_pos = player.global_position + Vector2(0, shape_height / 2 + 1)
	var top_center_pos = player.global_position - Vector2(0, shape_height / 2 - 1)

	var bottom_left_check_pos = bottom_center_pos - Vector2(horizontal_offset, 0)
	var bottom_right_check_pos = bottom_center_pos + Vector2(horizontal_offset, 0)
	var top_left_check_pos = top_center_pos - Vector2(horizontal_offset, 0)
	var top_right_check_pos = top_center_pos + Vector2(horizontal_offset, 0)

	var check_points = [bottom_left_check_pos, bottom_right_check_pos, top_left_check_pos, top_right_check_pos]

	# Check all collisions in the last frame
	for i in range(player.get_slide_collision_count()):
		var collision = player.get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer:
			var tilemap: TileMapLayer = collider

			for point in check_points:
				var map_coords = tilemap.local_to_map(tilemap.to_local(point))
				var tile_data: TileData = tilemap.get_cell_tile_data(map_coords)

				if tile_data:
					# Check if this tile has collision polygons on layer 1 (die layer)
					if tile_data.get_collision_polygons_count(1) > 0:
						return true
		else:
			# Handle regular collision objects (not tilemaps)
			# Check if the collider is on collision layer 3 (die layer)
			if collider.collision_layer & (1 << 2):  # Layer 3 is bit 2 (0-indexed)
				return true

	return false
