## Header UI component - displays game state and player info at top of screen
## 
## Signals:
##   button_pressed(button_name: StringName) — emitted when a button in the header is pressed
##
## Usage:
##   - Attach to a Control node positioned at top of screen
##   - Use anchors to keep it at top edge
##   - Add Button children with unique names for each action

extends Control
class_name HeaderUI

signal button_pressed(button_name: StringName)

@export_group("Display")
@export var show_on_startup: bool = true

# UI element references
@onready var title_label: Label = %TitleLabel if has_node("%TitleLabel") else null
@onready var score_label: Label = %ScoreLabel if has_node("%ScoreLabel") else null

func _ready() -> void:
	visible = show_on_startup

func set_title(text: String) -> void:
	"""Update header title text"""
	if title_label:
		title_label.text = text

func set_score(value: int) -> void:
	"""Update score display"""
	if score_label:
		score_label.text = "Score: %d" % value

func show_header() -> void:
	"""Make header visible"""
	visible = true

func hide_header() -> void:
	"""Hide header"""
	visible = false

func _on_button_pressed(button_name: StringName) -> void:
	"""Forward button presses as signals"""
	button_pressed.emit(button_name)
