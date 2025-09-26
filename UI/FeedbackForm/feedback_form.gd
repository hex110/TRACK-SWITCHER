extends CanvasLayer

signal feedback_closed

@onready var name_input = $Panel/VBoxContainer/MarginContainer/ContentContainer/NameContainer/NameInput
@onready var email_input = $Panel/VBoxContainer/MarginContainer/ContentContainer/EmailContainer/EmailInput
@onready var feedback_input = $Panel/VBoxContainer/MarginContainer/ContentContainer/FeedbackContainer/FeedbackInput
@onready var send_button = $Panel/VBoxContainer/MarginContainer/ContentContainer/ButtonContainer/SendButton
@onready var cancel_button = $Panel/VBoxContainer/MarginContainer/ContentContainer/ButtonContainer/CancelButton
@onready var status_label = $Panel/VBoxContainer/MarginContainer/ContentContainer/StatusLabel

var http_request: HTTPRequest

# Google Forms configuration - You'll need to replace these with your actual form details
const GOOGLE_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSdQTSkSmkc7v1BaSqS_Fk0VzxSm74_9AggYhsmMCtpwL7P0HA/formResponse"
const NAME_FIELD = "entry.653786296"  # Replace with actual field ID
const EMAIL_FIELD = "entry.2037067484"  # Replace with actual field ID
const FEEDBACK_FIELD = "entry.2099698388"  # Replace with actual field ID

func _ready():
	# Create HTTPRequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	# Set initial state
	status_label.text = ""
	name_input.grab_focus()

func _on_cancel_pressed():
	close_form()

func _on_send_pressed():
	if validate_form():
		submit_feedback()

func validate_form() -> bool:
	var name = name_input.text.strip_edges()
	var feedback = feedback_input.text.strip_edges()

	if name.is_empty():
		show_status("Please enter your name.", Color.RED)
		name_input.grab_focus()
		return false

	if feedback.is_empty():
		show_status("Please enter your feedback.", Color.RED)
		feedback_input.grab_focus()
		return false

	if feedback.length() < 5:
		show_status("Please provide more detailed feedback (at least 5 characters).", Color.RED)
		feedback_input.grab_focus()
		return false

	# Validate email if provided
	var email = email_input.text.strip_edges()
	if not email.is_empty():
		var email_regex = RegEx.new()
		email_regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
		if not email_regex.search(email):
			show_status("Please enter a valid email address or leave it empty.", Color.RED)
			email_input.grab_focus()
			return false

	return true

func submit_feedback():
	show_status("Sending feedback...", Color.YELLOW)
	send_button.disabled = true
	cancel_button.disabled = true

	# Prepare form data
	var form_data = {}
	form_data[NAME_FIELD] = name_input.text.strip_edges()
	form_data[EMAIL_FIELD] = email_input.text.strip_edges()
	form_data[FEEDBACK_FIELD] = feedback_input.text.strip_edges()

	# Convert to URL-encoded string
	var post_data = ""
	for key in form_data.keys():
		if post_data != "":
			post_data += "&"
		post_data += key + "=" + form_data[key].uri_encode()

	# Set headers
	var headers = [
		"Content-Type: application/x-www-form-urlencoded",
		"User-Agent: Godot Game Feedback"
	]

	# Send request
	var error = http_request.request(GOOGLE_FORM_URL, headers, HTTPClient.METHOD_POST, post_data)
	print(error)
	
	if error != OK:
		show_status("Failed to send feedback. Please try again.", Color.RED)
		reset_buttons()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print(result)
	print(response_code)
	print(headers)
	print(body)
	if response_code == 200:
		show_status("Feedback sent successfully! Thank you!", Color.GREEN)
		# Wait a moment then close
		await get_tree().create_timer(2.0).timeout
		close_form()
	else:
		show_status("Failed to send feedback. Please try again later.", Color.RED)
		reset_buttons()

func show_status(message: String, color: Color):
	status_label.text = message
	status_label.modulate = color

func reset_buttons():
	send_button.disabled = false
	cancel_button.disabled = false

func close_form():
	feedback_closed.emit()
	queue_free()

func clear_form():
	name_input.text = ""
	email_input.text = ""
	feedback_input.text = ""
	status_label.text = ""
	name_input.grab_focus()

# Handle escape key to close form
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close_form()
