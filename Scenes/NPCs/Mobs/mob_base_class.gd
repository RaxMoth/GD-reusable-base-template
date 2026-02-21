## Mob base class - generic enemy/minion NPC
## Inherits from EntityBase for combat, movement, targeting
##
## Signals:
##   health_changed(current: float, max: float) — emitted when health changes
##
## Dependencies:
##   - EntityBase (parent class)
##   - Types autoload
##   - Global autoload

extends EntityBase
class_name MobBase

signal health_changed(current: float, max: float)

@export_group("Mob Stats")
@export var max_health: float = 50.0
@export var base_movement_speed: float = 80.0
@export var base_attack_range: float = 40.0
@export var base_attack_damage: float = 8.0
@export var attack_cooldown: float = 1.5

@export_group("Mob Behavior")
@export var base_idle_retarget_time: float = 1.2
@export var base_idle_wander_radius: float = 150.0
@export var base_keep_distance: float = 30.0
@export var chase_distance: float = 400.0

# Runtime stats
var current_health: float
var attack_timer: float = 0.0
var spawn_area: Node = null
var spawn_position: Vector2 = Vector2.ZERO

# Combat tracking
var is_in_combat: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("Enemy")
	spawn_position = global_position
	super._ready()
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _physics_process(delta: float) -> void:
	"""Update attack cooldown"""
	if attack_timer > 0.0:
		attack_timer -= delta

# ============================================
# HEALTH & DAMAGE SYSTEM
# ============================================

func take_damage(damage_amount: float) -> void:
	"""Take damage and update health bar"""
	current_health = max(0.0, current_health - damage_amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health
	
	print(name + " took " + str(damage_amount) + " damage. Health: " + str(current_health))
	
	if current_health <= 0.0:
		_on_mob_died()

func apply_damage_to_target(target: Node2D, damage: float) -> void:
	"""Deal damage to a target entity"""
	if not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print(name + " dealt " + str(damage) + " damage to " + target.name)

# ============================================
# VIRTUAL METHOD OVERRIDES (EntityBase)
# ============================================

func _is_attack_ready() -> bool:
	"""Check if attack is off cooldown"""
	return attack_timer <= 0.0

func is_alive() -> bool:
	"""Check if health > 0"""
	return current_health > 0.0

func get_health() -> float:
	"""Get current health"""
	return current_health

func _get_entity_level() -> int:
	"""All mobs are level 1 by default"""
	return 1

func _get_move_speed() -> float:
	"""Get movement speed"""
	return base_movement_speed

func _get_attack_range() -> float:
	"""Get attack range"""
	return base_attack_range

func _get_idle_retarget_time() -> float:
	"""How often to pick new idle destination"""
	return base_idle_retarget_time

func _get_idle_wander_radius() -> float:
	"""How far to wander during idle"""
	return base_idle_wander_radius

func _get_keep_distance() -> float:
	"""Minimum distance to keep from target"""
	return base_keep_distance

# ============================================
# COMBAT TRACKING
# ============================================

func _on_idle_state_entered() -> void:
	"""Track state changes"""
	is_in_combat = false
	super._on_idle_state_entered()

func _on_approach_state_entered() -> void:
	"""Track state changes"""
	is_in_combat = true
	super._on_approach_state_entered()

func _on_fight_state_entered() -> void:
	"""Track state changes"""
	is_in_combat = true
	super._on_fight_state_entered()

func _on_dead_state_entered() -> void:
	"""Track state changes"""
	is_in_combat = false
	_on_mob_died()
	super._on_dead_state_entered()

# ============================================
# COMBAT EXECUTION
# ============================================

func _on_fight_logic(delta: float) -> void:
	"""Execute attack when in fight state and ready"""
	if _is_attack_ready() and is_target_valid():
		_perform_attack()

func _perform_attack() -> void:
	"""Perform a basic attack on target"""
	if not is_target_valid():
		return
	
	attack_timer = attack_cooldown
	
	# Simple attack: deal damage
	var damage = base_attack_damage * randf_range(0.7, 1.3) # Variance
	apply_damage_to_target(target_entity as Node2D, damage)

# ============================================
# DEATH HANDLING
# ============================================

func _on_mob_died() -> void:
	"""Handle mob death"""
	print(name + " has been defeated!")
	
	# Grant XP to killer (handled by EntityBase._grant_xp_to_killer)
	
	# Could add:
	# - Death animation/particles
	# - Loot drops
	# - Sound effects
	# - Respawn mechanics
	
	queue_free()

# ============================================
# UTILITY
# ============================================

func reset_to_spawn() -> void:
	"""Return to spawn position (useful for reset mechanics)"""
	global_position = spawn_position
	current_health = max_health
	if health_bar:
		health_bar.value = current_health
