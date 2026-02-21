## Hero base class - player-controlled or hero group NPC
## Inherits from EntityBase for combat, movement, targeting
##
## Signals:
##   health_changed(current: float, max: float) — emitted when health changes
##   leveled_up(new_level: int, xp: float) — emitted when reaching new level
##
## Dependencies:
##   - EntityBase (parent class)
##   - Types autoload
##   - Global autoload

extends EntityBase
class_name HeroBase

signal health_changed(current: float, max: float)
signal leveled_up(new_level: int, xp: float)

@export_group("Hero Stats")
@export var max_health: float = 100.0
@export var base_movement_speed: float = 120.0
@export var base_attack_range: float = 50.0
@export var base_attack_damage: float = 15.0
@export var attack_cooldown: float = 1.0

@export_group("Hero Progression")
@export var hero_level: int = 1
@export var xp_to_level_up: float = 100.0

# Runtime stats
var current_health: float
var current_xp: float = 0.0
var attack_timer: float = 0.0
var total_damage_dealt: float = 0.0

# Combat state
var is_attacking: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("Hero")
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
		_on_hero_died()

func heal(amount: float) -> void:
	"""Restore health"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health
	
	print(name + " healed for " + str(amount) + ". Health: " + str(current_health))

func apply_damage_to_target(target: Node2D, damage: float) -> void:
	"""Deal damage to a target entity"""
	if not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		total_damage_dealt += damage
		print(name + " dealt " + str(damage) + " damage to " + target.name)

# ============================================
# XP & LEVELING
# ============================================

func gain_xp(amount: float) -> void:
	"""Gain experience points"""
	current_xp += amount
	print(name + " gained " + str(amount) + " XP")
	
	if current_xp >= xp_to_level_up:
		_level_up()

func _level_up() -> void:
	"""Advance to next level"""
	hero_level += 1
	current_xp = 0.0
	
	# Stat increases
	max_health += 20.0
	current_health = max_health
	base_attack_damage += 3.0
	attack_cooldown = max(0.3, attack_cooldown - 0.1)
	
	xp_to_level_up *= 1.2 # Exponential scaling
	
	leveled_up.emit(hero_level, current_xp)
	print(name + " leveled up to " + str(hero_level) + "!")

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
	"""Get hero level"""
	return hero_level

func _get_move_speed() -> float:
	"""Get movement speed"""
	return base_movement_speed

func _get_attack_range() -> float:
	"""Get attack range"""
	return base_attack_range

func _get_idle_retarget_time() -> float:
	"""How often to pick new idle destination"""
	return 3.0

func _get_idle_wander_radius() -> float:
	"""How far to wander during idle"""
	return 200.0

func _get_keep_distance() -> float:
	"""Minimum distance to keep from target"""
	return 40.0

# ============================================
# COMBAT OVERRIDES (StateChart Handlers)
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
	is_attacking = true
	
	# Simple attack: deal damage
	var damage = base_attack_damage * randf_range(0.8, 1.2) # Variance
	apply_damage_to_target(target_entity as Node2D, damage)
	
	# Could add:
	# - Attack animation trigger
	# - Particle effect
	# - Hit sound
	# - Knockback
	
	is_attacking = false

# ============================================
# DEATH HANDLING
# ============================================

func _on_hero_died() -> void:
	"""Handle hero death"""
	print(name + " has been defeated!")
	
	# Emit death signal (already emitted by EntityBase)
	died.emit()
	
	# Could add:
	# - Death animation
	# - Respawn logic
	# - Game over screen
	
	queue_free()
