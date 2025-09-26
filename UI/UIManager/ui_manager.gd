# UIManager.gd
extends Control

@export var background: ColorRect
@export var bg_anim_player: AnimationPlayer

@export var settings_menu: Control
@export var pause_menu: Control

# A stack to keep track of the menu history (e.g., Pause -> Settings)
var menu_stack: Array[Control] = []

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if menu_stack.is_empty() and get_tree().current_scene.name != "MainMenu" and GameManager.can_pause == true:
			open_pause_menu()
			pass
		else:
			close_current_menu()

func _ready() -> void:
	background.visible = false
	
	pause_menu.visible = false
	settings_menu.visible = false
	
	# Connect signals from each menu to the manager's logic
	settings_menu.back_requested.connect(_on_back_requested)
	pause_menu.back_requested.connect(_on_back_requested)
	pause_menu.open_settings.connect(open_settings)

func open_menu(menu: Control) -> void:
	# If there's already a menu open, hide it first
	if not menu_stack.is_empty():
		var current_menu = menu_stack.back()
		await current_menu.hide_menu() # Wait for its disappear animation
	
	# If this is the first menu, show the background
	if menu_stack.is_empty():
		bg_anim_player.play("FadeIn")
	
	# Add the new menu to the stack and show it
	menu_stack.push_back(menu)
	menu.show_menu() # This plays its appear animation

func close_current_menu() -> void:
	if menu_stack.is_empty():
		return

	# Hide the current menu
	var menu_to_close = menu_stack.pop_back()
	if menu_to_close == pause_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		resume()
	await menu_to_close.hide_menu()

	# If there are other menus in the stack, show the previous one
	if not menu_stack.is_empty():
		var new_top_menu = menu_stack.back()
		new_top_menu.visible = true
		new_top_menu.show_menu()
	else:
		# No menus left, so hide the background
		bg_anim_player.play("FadeOut")

# --- Signal Handlers ---

func _on_back_requested() -> void:
	# A generic back button was pressed on the current menu
	close_current_menu()

func open_settings() -> void:
	# The pause menu asked to open the settings menu
	open_menu(settings_menu)

func open_pause_menu() -> void:
	pause()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	open_menu(pause_menu)

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true
