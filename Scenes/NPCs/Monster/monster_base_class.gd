## Monster base class - boss/special enemy NPC
## Inherits from EntityBase with enhanced combat and scaling
##
## Signals:
##   health_changed(current: float, max: float) — emitted when health changes
##   stage_changed(new_stage: int, old_stage: int) — emitted on stage transition
##
## Dependencies:
##   - EntityBase (parent class)
##   - Types autoload
##   - Global autoload

extends EntityBase
class_name MonsterBase

signal health_changed(current: float, max: float)
signal stage_changed(new_stage: int, old_stage: int)

@export_group("Monster Stats")
@export var max_health: float = 200.0
@export var base_movement_speed: float = 100.0
@export var base_attack_range: float = 50.0
@export var base_attack_damage: float = 20.0
@export var attack_cooldown: float = 1.2

@export_group("Monster Progression")
@export var max_stages: int = 3
@export var health_per_stage: float = 200.0
@export var damage_multiplier_per_stage: float = 1.2

@export_group("Monster Behavior")
@export var base_idle_wander_radius: float = 200.0

# Runtime stats
var current_health: float
var attack_timer: float = 0.0
var current_stage: int = 1
var total_stage_damage_taken: float = 0.0

func _ready() -> void:
	current_health = max_health
	add_to_group("Monster")
	add_to_group("Enemy") # Monsters are also in Enemy group
	super._ready()
	
	current_stage = 1
	_apply_stage_configuration(current_stage)
	
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
	"""Take damage with stage progression"""
	current_health = max(0.0, current_health - damage_amount)
	total_stage_damage_taken += damage_amount
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health
	
	print(name + " took " + str(damage_amount) + " damage (Stage " + str(current_stage) + "). Health: " + str(current_health))
	
	# Check for stage transition
	if current_stage < max_stages:
		var stage_health_threshold = max_health - (health_per_stage * float(current_stage))
		if current_health <= stage_health_threshold:
			_transition_to_stage(current_stage + 1)
	
	if current_health <= 0.0:
		_on_monster_died()

func apply_damage_to_target(target: Node2D, damage: float) -> void:
	"""Deal damage to a target entity"""
	if not is_instance_valid(target):
		return
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print(name + " (Stage " + str(current_stage) + ") dealt " + str(damage) + " damage to " + target.name)

# ============================================
# STAGE SYSTEM
# ============================================

func _apply_stage_configuration(stage: int) -> void:
	"""Apply stat modifiers based on current stage"""
	var stage_multiplier = pow(damage_multiplier_per_stage, float(stage - 1))
	base_attack_damage = 20.0 * stage_multiplier
	
	# Update health pool for this stage
	var previous_damage = total_stage_damage_taken
	max_health = health_per_stage * float(stage)
	current_health = max_health - previous_damage
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	print(name + " is now Stage " + str(stage) + " (Damage: " + str(base_attack_damage) + ", Max HP: " + str(max_health) + ")")

func _transition_to_stage(new_stage: int) -> void:
	"""Transition to a new stage"""
	if new_stage <= current_stage or new_stage > max_stages:
		return
	
	var old_stage = current_stage
	current_stage = new_stage
	_apply_stage_configuration(new_stage)
	
	stage_changed.emit(new_stage, old_stage)
	print(name + " has entered Stage " + str(new_stage) + "!")

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
	"""Monster level defaults to current stage"""
	return current_stage

func _get_move_speed() -> float:
	"""Get movement speed"""
	return base_movement_speed

func _get_attack_range() -> float:
	"""Get attack range"""
	return base_attack_range

func _get_idle_retarget_time() -> float:
	"""How often to pick new idle destination"""
	return 2.0

func _get_idle_wander_radius() -> float:
	"""How far to wander during idle"""
	return base_idle_wander_radius

func _get_keep_distance() -> float:
	"""Minimum distance from target"""
	return 40.0

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
	
	# Attack damage scales with stage
	var damage = base_attack_damage * randf_range(0.8, 1.2)
	apply_damage_to_target(target_entity as Node2D, damage)

# ============================================
# DEATH HANDLING
# ============================================

func _on_monster_died() -> void:
	"""Handle monster death"""
	print(name + " has been defeated at Stage " + str(current_stage) + "!")
	
	# Grant bonus XP for defeating boss
	if xp_value > 0:
		xp_value *= float(current_stage) # Scale XP by difficulty
	
	# Could add:
	# - Boss death animation
	# - Special loot drops
	# - Achievement unlock
	# - Scene transition
	
	queue_free()
