# extending_platform.gd
@tool
class_name ExtendingPlatform
extends ReactiveElement

## An enum to define the direction in the Inspector.
enum ExtendDirection { RIGHT, LEFT }

@export_group("Platform Behavior")
@export var direction: ExtendDirection = ExtendDirection.RIGHT
# Drag the Node2D that contains all your segments here.
@export var segments_container: Node2D
# Drag all segment nodes from the scene tree into this array in the Inspector.
@export var segments: Array[Node2D]
# NEW: If true, one beat extends the platform, the next retracts it.
@export var toggle_on_beat: bool = true
# NEW: If true, segments will visually slide out from the previous one.
@export var animate_growth: bool = true

@export_group("Animation Timing")
@export var hold_duration: float = 0.5
@export var delay_between_segments: float = 0
# NEW: How fast each segment slides into its final position.
@export var segment_move_duration: float = 0.05

# --- Private variables ---
var move_tween: Tween
# NEW: Tracks the state for toggle mode.
var is_extended: bool = false
# NEW: We store the final positions of segments at the start.
var _segment_final_positions: Array = []

func _ready():
	if segments.is_empty(): return
	
	#segments.reverse()
	
	# NEW: Store the intended final position of each segment.
	# This is crucial for the growth animation.
	for segment in segments:
		_segment_final_positions.append(segment.position)

	# Ensure all segments start hidden, disabled, and at their correct final positions.
	if direction == ExtendDirection.LEFT:
		segments_container.scale.x = -1
	
	super._ready()


func deactivate():
	super.deactivate()
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	
	# NEW: When deactivating, reset everything to its initial state.
	is_extended = false
	_reset_all_segments()


# The main beat logic is now a router.
func _on_beat():
	if not segments or segments.is_empty(): return
	if move_tween and move_tween.is_valid(): return

	## FIX 1: The instance 'move_tween' is now ALWAYS created here.
	# This ensures we have one single, managed tween for any beat animation,
	# preventing overlaps between extend and retract tweens in toggle mode.
	move_tween = create_tween().set_trans(Tween.TRANS_SINE)

	if toggle_on_beat:
		if is_extended:
			_retract_platform(move_tween)
		else:
			_extend_platform(move_tween)
		# We now connect to the tween's finished signal to update the state.
		# This is more robust than changing the state immediately.
		move_tween.finished.connect(func(): is_extended = not is_extended)
	else:
		_extend_platform(move_tween)
		move_tween.tween_interval(hold_duration)
		_retract_platform(move_tween)

# --- CORE ANIMATION FUNCTIONS ---

func _extend_platform(tween: Tween):
	var segment_order = segments.duplicate()

	for i in segment_order.size():
		var segment = segment_order[i]
		var final_pos = _segment_final_positions[segments.find(segment)]

		var start_pos = Vector2.ZERO
		if i > 0:
			var prev_segment = segment_order[i - 1]
			start_pos = _segment_final_positions[segments.find(prev_segment)]
			
		_animate_segment_appearance(tween, segment, start_pos, final_pos)
		tween.tween_interval(delay_between_segments)

func _retract_platform(tween: Tween):
	var segment_order_for_retraction = segments.duplicate()
	## FIX 3: The retraction order is now simply the reverse of the appearance order.
	segment_order_for_retraction.reverse()

	for i in segment_order_for_retraction.size():
		var segment = segment_order_for_retraction[i]
		var final_pos = _segment_final_positions[segments.find(segment)]

		var target_pos = Vector2.ZERO
		if i < segment_order_for_retraction.size() - 1:
			var next_segment_to_retract = segment_order_for_retraction[i+1]
			target_pos = _segment_final_positions[segments.find(next_segment_to_retract)]

		_animate_segment_disappearance(tween, segment, final_pos, target_pos)
		tween.tween_interval(delay_between_segments)


# --- HELPER FUNCTIONS ---

func _animate_segment_appearance(tween: Tween, segment: Node2D, start_pos: Vector2, final_pos: Vector2):
	# Make the segment visible and enable its physics
	tween.tween_callback(Callable(self, "_set_segment_state").bind(segment, true))
	
	if animate_growth:
		# Set its position to the start point, then tween it to the end point.
		tween.tween_callback(func(): segment.position = start_pos)
		tween.tween_property(segment, "position", final_pos, segment_move_duration)
	else:
		# If not animating growth, just ensure it's at its final position.
		tween.tween_callback(func(): segment.position = final_pos)


func _animate_segment_disappearance(tween: Tween, segment: Node2D, _start_pos: Vector2, target_pos: Vector2):
	if animate_growth:
		# Tween from its current position back to where the previous segment was.
		tween.tween_property(segment, "position", target_pos, segment_move_duration)
		# Then hide it and disable physics.
		tween.tween_callback(Callable(self, "_set_segment_state").bind(segment, false))
	else:
		# If not animating growth, just hide it immediately.
		tween.tween_callback(Callable(self, "_set_segment_state").bind(segment, false))


func _set_segment_state(segment: Node2D, is_active: bool):
	if not is_instance_valid(segment): return
	if is_active:
		segment.show()
		segment.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		segment.hide()
		segment.process_mode = Node.PROCESS_MODE_DISABLED


func _reset_all_segments():
	for i in segments.size():
		var segment = segments[i]
		if is_instance_valid(segment):
			_set_segment_state(segment, false)
			segment.position = _segment_final_positions[i]
