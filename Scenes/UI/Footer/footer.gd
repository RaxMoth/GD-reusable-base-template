## Footer UI component - displays game info and controls at bottom of screen
##
## Signals:
##   button_pressed(button_name: StringName) — emitted when a button in the footer is pressed
##
## Usage:
##   - Attach to a Control node positioned at bottom of screen
##   - Use anchors to keep it at bottom edge
##   - Add containers for status information and controls

extends Control
class_name FooterUI

signal button_pressed(button_name: StringName)

@export_group("Display")
@export var show_on_startup: bool = true

# UI element references (optional)
@onready var status_label: Label = %StatusLabel if has_node("%StatusLabel") else null
@onready var health_progress: ProgressBar = %HealthBar if has_node("%HealthBar") else null

func _ready() -> void:
	visible = show_on_startup

func set_status(text: String) -> void:
	"""Update footer status text"""
	if status_label:
		status_label.text = text

func update_health_display(current_health: float, max_health: float) -> void:
	"""Update health bar display"""
	if health_progress:
		health_progress.max_value = max_health
		health_progress.value = current_health

func show_footer() -> void:
	"""Make footer visible"""
	visible = true

func hide_footer() -> void:
	"""Hide footer"""
	visible = false

func _on_button_pressed(button_name: StringName) -> void:
	"""Forward button presses as signals"""
	button_pressed.emit(button_name)
