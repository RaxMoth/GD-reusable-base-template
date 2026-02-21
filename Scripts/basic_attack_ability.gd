## Basic attack ability - simple attack dealing damage to target
## Used as the primary damage source for all entities

extends AbilityBase
class_name BasicAttackAbility

@export var attack_damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_knockback: float = 200.0

func _ready() -> void:
	ability_name = &"BasicAttack"
	ability_description = "Basic melee/ranged attack"
	is_passive = false

func can_cast_ability(caster_entity: Node2D = null) -> bool:
	"""Check if basic attack can be cast"""
	if not caster_entity:
		return is_ability_ready()
	
	# Need a valid target
	if caster_entity.has_method("is_target_valid"):
		if not caster_entity.is_target_valid():
			return false
	
	return is_ability_ready()

func execute_ability(caster_entity: Node2D, target: Node2D = null) -> void:
	"""Execute basic attack"""
	if not caster_entity:
		return
	
	# Get target from caster if not provided
	if not target:
		if caster_entity.has_method("is_target_valid") and caster_entity.is_target_valid():
			target = caster_entity.target_entity
		else:
			return
	
	if not is_instance_valid(target):
		return
	
	# Check range
	var distance_to_target = caster_entity.global_position.distance_to(target.global_position)
	if distance_to_target > attack_range:
		return
	
	# Deal damage
	if target.has_method("take_damage"):
		var damage = attack_damage * randf_range(0.8, 1.2)
		target.take_damage(damage)
	
	# Apply knockback if target has velocity property
	if target.has_property("velocity"):
		var knockback_dir = (target.global_position - caster_entity.global_position).normalized()
		target.velocity = knockback_dir * attack_knockback
	
	# Start cooldown
	start_cooldown()
	ability_triggered.emit(ability_name)
