# TutorialTrigger.gd
extends Area2D
class_name TutorialTrigger

@export var tutorial_action: String = ""  # e.g., "move_left", "move_right" or "move_left,move_right"
@export var wait_time: float = 3.0
@export var tutorial_text: String = ""
@export var one_shot: bool = true

var player_in_area: bool = false
var timer: Timer
var tutorial_displayed: bool = false
var action_completed: bool = false

@onready var tutorial_control: Control = $Control
@onready var tutorial_label: Label = $Control/Label
@onready var completion_area: Area2D = $CompletionArea

func _ready():
	
	# Connect the completion area signals
	if completion_area:
		completion_area.body_entered.connect(_on_completion_area_entered)
	
	# Create and setup timer for showing tutorial
	timer = Timer.new()
	timer.wait_time = wait_time
	timer.timeout.connect(_show_tutorial)
	timer.one_shot = true
	add_child(timer)
	
	# Hide the tutorial UI initially
	tutorial_control.visible = false

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = true
		if not action_completed:
			timer.start()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_area = false
		timer.stop()
		# Don't hide tutorial when exiting main area - let completion area handle it
		# _hide_tutorial()

func _on_completion_area_entered(body: Node2D):
	if body.is_in_group("player"):
		action_completed = true
		_hide_tutorial()

func _show_tutorial():
	if not action_completed and tutorial_control and tutorial_label:
		tutorial_displayed = true
		var key_displays = _get_key_display_names()
		tutorial_label.text = tutorial_text.format(key_displays)
		tutorial_control.visible = true
		
		# Optional: Add a simple fade-in animation
		var tween = create_tween()
		tutorial_control.modulate.a = 0.0
		tween.tween_property(tutorial_control, "modulate:a", 1.0, 0.3)

func _hide_tutorial():
	if tutorial_displayed and tutorial_control:
		tutorial_displayed = false
		
		# Optional: Add a simple fade-out animation
		var tween = create_tween()
		tween.tween_property(tutorial_control, "modulate:a", 0.0, 0.2)
		await tween.finished
		tutorial_control.visible = false
		tutorial_control.modulate.a = 1.0  # Reset for next time
		if one_shot:
			queue_free()

func _get_key_display_names() -> Array:
	var keybinds = ConfigFileHandler.load_keybinds()
	var actions = tutorial_action.split(",")
	var key_names = []
	
	for action in actions:
		action = action.strip_edges()  # Remove any whitespace
		if keybinds.has(action):
			var event = keybinds[action]
			if event is InputEventKey:
				key_names.append(OS.get_keycode_string(event.keycode))
			elif event is InputEventMouseButton:
				key_names.append("Mouse " + str(event.button_index))
		else:
			key_names.append("?")
	
	return key_names
