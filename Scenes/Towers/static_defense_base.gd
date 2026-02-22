## Generic stationary defense/tower system
## Inherits from Node2D for positioning, uses Area2D for detection
## Automatically manages targeting, rotation, and attack cooldowns
##
## Features:
##   - Multiple targeting modes (first, last, strongest, weakest)
##   - Automatic enemy detection and targeting
##   - Rotation toward target
##   - Attack cooldown management
##   - XP-based leveling system
##   - Virtual fire() method for custom attack behavior
##   - Signal-based upgrades and level-ups
##
## Dependencies:
##   - Global autoload
##   - Types autoload
##   - Signals in connected area nodes

extends Node2D
class_name StaticDefenseBase

# ============================================
# SIGNALS
# ============================================

signal tower_clicked
signal enemy_spotted(enemy: Node)
signal enemy_lost(enemy: Node)
signal leveled_up(new_level: int)
signal fire_triggered(target: Node)
signal targeting_mode_changed(mode: StringName)

# ============================================
# EXPORT PROPERTIES
# ============================================

@export_group("Tower Stats")
@export var tower_name: StringName = &"Tower"
@export var max_health: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 300.0
@export var rate_of_fire: float = 1.0 # seconds between attacks
@export var rotation_speed: float = 5.0 # radians per second

@export_group("Leveling")
@export var xp_per_kill: float = 10.0
@export var xp_threshold: float = 50.0
@export var max_level: int = 5
@export var stat_scaling: float = 1.1 # damage multiplier per level

@export_group("Targeting")
@export var default_targeting_mode: StringName = &"first" # first, last, strongest, weakest

@export_group("Visual")
@export var show_range_on_start: bool = false
@export var range_color: Color = Color.BLUE

# ============================================
# ONREADY REFERENCES
# ============================================

@onready var detection_area: Area2D = %DetectionArea
@onready var turret_sprite: Sprite2D = %TurretSprite
@onready var range_display: Node2D = %RangeDisplay
@onready var fire_timer: Timer = %FireTimer

# ============================================
# INTERNAL STATE
# ============================================

var current_health: float
var current_level: int = 1
var current_xp: float = 0.0
var attack_timer: float = 0.0

var detected_enemies: Array[Node] = []
var current_target: Node = null
var is_built: bool = true

var targeting_modes: Dictionary = {
	&"first": _select_first_enemy,
	&"last": _select_last_enemy,
	&"strongest": _select_strongest_enemy,
	&"weakest": _select_weakest_enemy,
}

var current_targeting_mode: StringName = &"first"

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	current_health = max_health
	current_targeting_mode = default_targeting_mode
	
	# Connect detection area signals
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
		
		# Update range visualization
		var collision_shape = detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape and collision_shape.shape is CircleShape2D:
			(collision_shape.shape as CircleShape2D).radius = attack_range * 0.5
	
	# Setup click detection
	var input_area = get_node_or_null("ClickArea") as Area2D
	if input_area:
		input_area.input_event.connect(_on_input_event)
	
	if show_range_on_start and range_display:
		_update_range_display()

func _physics_process(delta: float) -> void:
	if not is_built or detected_enemies.is_empty():
		current_target = null
		return
	
	# Select target via current targeting mode
	_update_target()
	
	# Rotate toward target
	if current_target:
		_rotate_toward_target(delta)
		
		# Attack if ready
		if attack_timer <= 0.0:
			fire()
			attack_timer = rate_of_fire
		else:
			attack_timer -= delta

# ============================================
# TARGETING SYSTEM
# ============================================

func _update_target() -> void:
	"""Update current target using active targeting mode"""
	if targeting_modes.has(current_targeting_mode):
		targeting_modes[current_targeting_mode].call()

func _select_first_enemy() -> void:
	"""Target the first enemy in detection area"""
	if detected_enemies.size() > 0:
		current_target = detected_enemies[0]

func _select_last_enemy() -> void:
	"""Target the last enemy to enter detection area"""
	if detected_enemies.size() > 0:
		current_target = detected_enemies[detected_enemies.size() - 1]

func _select_strongest_enemy() -> void:
	"""Target the enemy with most health"""
	if detected_enemies.is_empty():
		return
	
	var strongest = detected_enemies[0]
	for enemy in detected_enemies:
		if _get_enemy_health(enemy) > _get_enemy_health(strongest):
			strongest = enemy
	current_target = strongest

func _select_weakest_enemy() -> void:
	"""Target the enemy with least health"""
	if detected_enemies.is_empty():
		return
	
	var weakest = detected_enemies[0]
	for enemy in detected_enemies:
		if _get_enemy_health(enemy) < _get_enemy_health(weakest):
			weakest = enemy
	current_target = weakest

func set_targeting_mode(mode: StringName) -> void:
	"""Change targeting mode"""
	if targeting_modes.has(mode):
		current_targeting_mode = mode
		targeting_mode_changed.emit(mode)

# ============================================
# ROTATION
# ============================================

func _rotate_toward_target(delta: float) -> void:
	"""Smoothly rotate turret toward target"""
	if not current_target or not turret_sprite:
		return
	
	var direction = (current_target.global_position - global_position).normalized()
	var target_angle = direction.angle()
	var current_angle = turret_sprite.rotation
	
	# Smooth rotation
	var angle_diff = angle_difference(current_angle, target_angle)
	var rotation_step = sign(angle_diff) * min(abs(angle_diff), rotation_speed * delta)
	turret_sprite.rotation += rotation_step

# ============================================
# ATTACK SYSTEM
# ============================================

func fire() -> void:
	"""Virtual method - override in child classes to implement attack behavior"""
	if current_target:
		fire_triggered.emit(current_target)
		_apply_damage_to_target(current_target)

func _apply_damage_to_target(target: Node) -> void:
	"""Apply damage to target"""
	var damage_amount = calculate_damage()
	
	# Call take_damage if target has it
	if target.has_method("take_damage"):
		target.take_damage(damage_amount)
	# Otherwise try direct health subtraction
	elif "current_health" in target:
		target.current_health = max(0.0, target.current_health - damage_amount)

func calculate_damage() -> float:
	"""Calculate damage with level scaling"""
	return attack_damage * pow(stat_scaling, current_level - 1)

# ============================================
# HEALTH & LEVELING
# ============================================

func take_damage(damage_amount: float) -> void:
	"""Tower takes damage"""
	current_health = max(0.0, current_health - damage_amount)
	if current_health == 0.0:
		_on_tower_destroyed()

func heal(amount: float) -> void:
	"""Restore tower health"""
	current_health = min(max_health, current_health + amount)

func add_xp(amount: float) -> void:
	"""Add XP and trigger level-up if threshold reached"""
	if current_level >= max_level:
		return
	
	current_xp += amount
	if current_xp >= xp_threshold:
		_level_up()

func _level_up() -> void:
	"""Level up the tower"""
	if current_level >= max_level:
		return
	
	current_xp = 0.0
	current_level += 1
	
	# Scale stats
	max_health *= stat_scaling
	current_health = max_health
	
	leveled_up.emit(current_level)

func _on_tower_destroyed() -> void:
	"""Tower destroyed"""
	queue_free()

# ============================================
# DETECTION
# ============================================

func _on_detection_area_entered(body: Node2D) -> void:
	"""Enemy entered detection range"""
	if body.is_in_group("Enemy") and body not in detected_enemies:
		detected_enemies.append(body)
		enemy_spotted.emit(body)

func _on_detection_area_exited(body: Node2D) -> void:
	"""Enemy left detection range"""
	if body.is_in_group("Enemy") and body in detected_enemies:
		detected_enemies.erase(body)
		if body == current_target:
			current_target = null
		enemy_lost.emit(body)

func _get_enemy_health(enemy: Node) -> float:
	"""Get enemy current health safely"""
	if enemy.has_method("get_health"):
		return enemy.get_health()
	elif "current_health" in enemy:
		return enemy.current_health
	return 0.0

# ============================================
# VISIBILITY & UI
# ============================================

func set_range_visible(visible: bool) -> void:
	"""Toggle range display"""
	if range_display:
		range_display.visible = visible

func _update_range_display() -> void:
	"""Draw range indicator"""
	if not range_display:
		return
	
	# Clear previous draw
	range_display.queue_redraw()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	"""Handle tower click"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tower_clicked.emit()

# ============================================
# HELPER METHODS
# ============================================

func get_detected_enemy_count() -> int:
	"""Return number of enemies in range"""
	return detected_enemies.size()

func get_level_percentage() -> float:
	"""Return XP as percentage to next level"""
	return min(1.0, current_xp / xp_threshold)

func get_health_percentage() -> float:
	"""Return current health as percentage"""
	return current_health / max_health

func is_targeting_enemy() -> bool:
	"""Check if tower has active target"""
	return current_target != null
