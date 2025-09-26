# MovingSaw.gd
@tool
class_name MovingSaw
extends ReactiveElement

@export_group("Saw Behavior")
@export var saw_body: AnimatableBody2D
@export var point_a: Marker2D
@export var point_b: Marker2D
@export var speed: float = 200.0

# --- NEW: Chain Generation ---
@export_group("Chain")
## If true, a chain will be automatically generated between the two points.
@export var generate_chain: bool = true
## The texture for a single link of the chain (e.g., chain.png).
@export var chain_texture: Texture2D
## The space between each chain link. If 0, it defaults to the texture's width.
@export var chain_spacing_override: float = 0.0

# --- Private variables ---
var _move_tween: Tween
var _is_moving_to_b: bool = true

# --- NEW: Variables for tool mode ---
var _chain_container: Node2D
var _last_a_pos: Vector2
var _last_b_pos: Vector2


func _ready():
	super._ready()
	
	# Initial validation for all nodes
	if not _are_nodes_valid():
		return

	# Set the saw's starting position.
	saw_body.global_position = point_a.global_position
	
	# Generate the chain visuals when the game runs.
	# We use call_deferred to make sure the points have their final positions.
	call_deferred("_generate_chain")


# --- NEW: Editor Live Update Logic ---
# This process function will run in the editor thanks to the @tool annotation.
func _process(delta):
	# We only want this logic to run inside the Godot editor, not in the game.
	if not Engine.is_editor_hint():
		super._process(delta)

	# Check if the required nodes are set up before trying to use them.
	if not is_instance_valid(point_a) or not is_instance_valid(point_b):
		return

	# If the position of either marker has changed, regenerate the chain.
	if point_a.global_position != _last_a_pos or point_b.global_position != _last_b_pos:
		_generate_chain()
		_last_a_pos = point_a.global_position
		_last_b_pos = point_b.global_position


# --- NEW: The core function for creating the chain ---
func _generate_chain():
	# First, remove any previously generated chain container.
	if is_instance_valid(_chain_container):
		_chain_container.queue_free()
		_chain_container = null

	# Stop if the feature is disabled or misconfigured.
	if not generate_chain or not chain_texture or not point_a or not point_b:
		return

	# Create a new container to hold all the chain link sprites.
	_chain_container = Node2D.new()
	_chain_container.name = "ChainContainer"
	add_child(_chain_container)
	# Move the container to be drawn behind other children (like the saw body).
	move_child(_chain_container, 0)

		# Determine the spacing between links.
	@warning_ignore("incompatible_ternary")
	var spacing = chain_spacing_override if chain_spacing_override > 0 else chain_texture.get_width()
	if spacing <= 0:
		printerr("Chain spacing is zero or negative. Cannot generate chain.", self)
		return

	# --- Calculation ---
	var start_pos = point_a.position
	var end_pos = point_b.position
	
	var direction_vector = end_pos - start_pos
	var total_distance = direction_vector.length() + spacing
	
	if total_distance < 1.0: return # Don't generate if points are on top of each other.
	
	var direction_normalized = direction_vector.normalized()
	var angle = direction_normalized.angle()

	# --- Generation Loop ---
	var num_links = floor(total_distance / spacing)
	var current_distance: float = 0.0

	for i in range(num_links):
		# Create a new sprite for the chain link.
		var link = Sprite2D.new()
		link.texture = chain_texture
		
		# Position it along the line from A to B.
		link.position = start_pos + direction_normalized * current_distance
		
		# Rotate it to face the correct direction.
		link.rotation = angle
		
		link.z_index = -10
		
		_chain_container.add_child(link)
		
		# For @tool scripts, we must set the owner for the node to be saved in the scene.
		if Engine.is_editor_hint():
			link.owner = get_tree().edited_scene_root
		
		current_distance += spacing


# --- Existing Functions (Unchanged) ---
func activate():
	process_mode = Node.PROCESS_MODE_INHERIT

func deactivate():
	process_mode = Node.PROCESS_MODE_DISABLED
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

func _on_beat():
	if not _are_nodes_valid(): return
	if point_a.global_position.is_equal_approx(point_b.global_position): return

	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

	var target_position = point_b.global_position if _is_moving_to_b else point_a.global_position
	_is_moving_to_b = not _is_moving_to_b
	
	var distance = saw_body.global_position.distance_to(target_position)
	if speed <= 0 or distance <= 0: return
		
	var duration = distance / speed
	_move_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(saw_body, "global_position", target_position, duration)

func _are_nodes_valid() -> bool:
	if not saw_body: return false
	if not point_a: return false
	if not point_b: return false
	return true
