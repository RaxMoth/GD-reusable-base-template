## Universal input handling system
## Manages touch, mouse, and keyboard input with customizable controls
##
## Features:
##   - Multi-device support (touch, mouse, keyboard)
##   - Customizable input mappings
##   - Gesture recognition (tap, drag, long-press)
##   - Signal-based input events
##   - Mobile-friendly touch detection
##   - Input remapping UI support
##
## Dependencies:
##   - Global autoload

extends Node
class_name InputHandler

# ============================================
# SIGNALS
# ============================================

signal input_pressed(action: StringName, position: Vector2)
signal input_released(action: StringName, position: Vector2)
signal input_dragged(position: Vector2, delta: Vector2)
signal touch_long_pressed(position: Vector2)
signal ui_back_pressed
signal ui_pause_pressed

# ============================================
# ENUMS
# ============================================

enum InputType {
	TOUCH,
	MOUSE,
	KEYBOARD,
}

# ============================================
# EXPORT PROPERTIES
# ============================================

@export_group("Input Settings")
@export var input_enabled: bool = true
@export var debug_input_positions: bool = false

@export_group("Touch Settings")
@export var touch_deadzone: float = 10.0
@export var long_press_duration: float = 0.5
@export var double_tap_delay: float = 0.3

@export_group("Control Mappings")
@export var action_map: Dictionary = {
	"select": ["LMB", "Touch"],
	"build": ["B", "Double_Tap"],
	"menu": ["ESC", "Back_Button"],
	"pause": ["P", "LMB_Long_Press"],
}

# ============================================
# INTERNAL STATE
# ============================================

var last_input_position: Vector2 = Vector2.ZERO
var last_input_type: InputType = InputType.KEYBOARD
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO

var long_press_timer: float = 0.0
var is_pressing: bool = false
var press_start_position: Vector2 = Vector2.ZERO

var last_tap_time: float = 0.0
var last_tap_position: Vector2 = Vector2.ZERO

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	if not input_enabled:
		return
	
	if event is InputEventMouseButton:
		_handle_mouse_input(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_handle_touch_input(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)
	elif event is InputEventKey:
		_handle_keyboard_input(event)

func _physics_process(delta: float) -> void:
	"""Update long-press detection"""
	if is_pressing:
		long_press_timer += delta
		if long_press_timer >= long_press_duration:
			_trigger_long_press()

# ============================================
# MOUSE INPUT
# ============================================

func _handle_mouse_input(event: InputEventMouseButton) -> void:
	"""Handle mouse clicks"""
	if event.pressed:
		is_pressing = true
		press_start_position = event.position
		last_input_position = event.position
		last_input_type = InputType.MOUSE
		long_press_timer = 0.0
		input_pressed.emit(&"select", event.position)
	else:
		is_pressing = false
		long_press_timer = 0.0
		input_released.emit(&"select", event.position)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	"""Handle mouse movement"""
	var delta = event.position - last_input_position
	last_input_position = event.position
	
	if is_pressing and delta.length() > touch_deadzone:
		if not is_dragging:
			is_dragging = true
			drag_start_position = press_start_position
		input_dragged.emit(event.position, delta)

# ============================================
# TOUCH INPUT
# ============================================

func _handle_touch_input(event: InputEventScreenTouch) -> void:
	"""Handle touch input"""
	if event.pressed:
		is_pressing = true
		press_start_position = event.position
		last_input_position = event.position
		last_input_type = InputType.TOUCH
		long_press_timer = 0.0
		input_pressed.emit(&"select", event.position)
	else:
		is_pressing = false
		
		# Check for double-tap
		var time_since_last = Time.get_ticks_msec() - last_tap_time
		if time_since_last < double_tap_delay * 1000.0 and event.position.distance_to(last_tap_position) < touch_deadzone * 2:
			input_pressed.emit(&"double_tap", event.position)
		
		last_tap_time = Time.get_ticks_msec()
		last_tap_position = event.position
		
		input_released.emit(&"select", event.position)
		long_press_timer = 0.0
		is_dragging = false

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	"""Handle touch drag"""
	var delta = event.position - last_input_position
	last_input_position = event.position
	
	if delta.length() > touch_deadzone:
		if not is_dragging:
			is_dragging = true
			drag_start_position = event.position - event.relative
		input_dragged.emit(event.position, delta)

# ============================================
# KEYBOARD INPUT
# ============================================

func _handle_keyboard_input(event: InputEventKey) -> void:
	"""Handle keyboard input"""
	if not event.pressed:
		return
	
	last_input_type = InputType.KEYBOARD
	
	match event.keycode:
		KEY_ESCAPE:
			ui_back_pressed.emit()
		KEY_P:
			ui_pause_pressed.emit()

# ============================================
# LONG PRESS DETECTION
# ============================================

func _trigger_long_press() -> void:
	"""Trigger long-press action"""
	long_press_timer = 0.0
	touch_long_pressed.emit(press_start_position)

# ============================================
# UTILITY METHODS
# ============================================

func is_pointer_over_ui() -> bool:
	"""Check if pointer is over UI element"""
	return get_tree().root.gui_is_focus_owner()

func get_last_input_position() -> Vector2:
	"""Get position of last input"""
	return last_input_position

func get_last_input_type() -> InputType:
	"""Get type of last input"""
	return last_input_type

func is_input_active() -> bool:
	"""Check if currently processing input"""
	return is_pressing or is_dragging

func get_drag_distance() -> float:
	"""Get distance dragged from start"""
	if is_dragging:
		return last_input_position.distance_to(drag_start_position)
	return 0.0

func set_input_enabled(enabled: bool) -> void:
	"""Enable or disable input processing"""
	input_enabled = enabled

func remap_action(action_name: StringName, new_input: String) -> void:
	"""Remap an action to new input"""
	if action_map.has(action_name):
		action_map[action_name] = [new_input]

func get_input_string(action_name: StringName) -> String:
	"""Get input description for action"""
	if action_map.has(action_name):
		var inputs = action_map[action_name]
		return ", ".join(PackedStringArray(inputs)) if inputs.size() > 0 else "Unbound"
	return "Unknown"

# ============================================
# DEBUG
# ============================================

func _get_debug_overlay() -> String:
	"""Return debug info string"""
	if not debug_input_positions:
		return ""
	
	return """
	Last Input: %s
	Position: (%.0f, %.0f)
	Dragging: %s
	Active: %s
	""" % [
		InputType.keys()[last_input_type],
		last_input_position.x,
		last_input_position.y,
		is_dragging,
		is_input_active()
	]
