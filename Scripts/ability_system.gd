## Ability system manager - handles ability slots and casting
## Manages ability cooldowns, energy costs, and execute calls
##
## Signals:
##   ability_executed(ability_name: StringName) — emitted when ability is cast
##   ability_failed(ability_name: StringName, reason: String) — emitted on failure

extends Node
class_name AbilitySystem

signal ability_executed(ability_name: StringName)
signal ability_failed(ability_name: StringName, reason: String)

const MAX_ABILITY_SLOTS: int = 4

@export_group("Energy System")
@export var max_energy: float = 100.0
@export var energy_regen_per_second: float = 10.0

var owner_entity: Node2D = null
var current_energy: float

# Ability slots
var ability_slots: Array[AbilityBase] = []

func _ready() -> void:
	owner_entity = get_parent()
	current_energy = max_energy
	await get_tree().process_frame
	_setup_initial_abilities()

func _process(delta: float) -> void:
	"""Regenerate energy and update ability cooldowns"""
	current_energy = min(max_energy, current_energy + energy_regen_per_second * delta)
	
	# Update all ability cooldowns
	for ability in ability_slots:
		if ability and ability.current_cooldown > 0.0:
			ability.current_cooldown -= delta

func _setup_initial_abilities() -> void:
	"""Override this to add starting abilities"""
	# Add basic attack as first slot
	var basic_attack = BasicAttackAbility.new()
	add_ability(basic_attack, 0)

# ============================================
# ABILITY SLOT MANAGEMENT
# ============================================

func add_ability(ability: AbilityBase, slot: int = -1) -> bool:
	"""Add ability to a slot"""
	if slot < 0:
		# Find first empty slot
		for i in range(MAX_ABILITY_SLOTS):
			if ability_slots[i] == null:
				slot = i
				break
	
	if slot < 0 or slot >= MAX_ABILITY_SLOTS:
		push_error("Invalid ability slot: " + str(slot))
		return false
	
	ability_slots[slot] = ability
	ability.caster = owner_entity
	return true

func remove_ability(slot: int) -> void:
	"""Remove ability from slot"""
	if slot >= 0 and slot < MAX_ABILITY_SLOTS:
		ability_slots[slot] = null

func get_ability(slot: int) -> AbilityBase:
	"""Get ability in slot"""
	if slot >= 0 and slot < MAX_ABILITY_SLOTS:
		return ability_slots[slot]
	return null

func get_ability_by_name(ability_name: StringName) -> AbilityBase:
	"""Find ability by name"""
	for ability in ability_slots:
		if ability and ability.ability_name == ability_name:
			return ability
	return null

# ============================================
# ABILITY CASTING
# ============================================

func try_cast_ability(slot: int, target: Node2D = null) -> bool:
	"""Attempt to cast ability in slot"""
	var ability = get_ability(slot)
	if not ability:
		ability_failed.emit("", "No ability in slot " + str(slot))
		return false
	
	if not ability.can_cast_ability(owner_entity):
		ability_failed.emit(ability.ability_name, "Ability not ready or insufficient energy")
		return false
	
	# Deduct energy cost
	if energy_cost > 0.0:
		current_energy -= ability.energy_cost
	
	# Execute ability
	ability.execute_ability(owner_entity, target)
	ability_executed.emit(ability.ability_name)
	
	return true

func try_cast_ability_by_name(ability_name: StringName, target: Node2D = null) -> bool:
	"""Attempt to cast ability by name"""
	var ability = get_ability_by_name(ability_name)
	if not ability:
		ability_failed.emit(ability_name, "Ability not found")
		return false
	
	if not ability.can_cast_ability(owner_entity):
		ability_failed.emit(ability_name, "Ability not ready or insufficient energy")
		return false
	
	# Deduct energy cost
	if ability.energy_cost > 0.0:
		current_energy -= ability.energy_cost
	
	# Execute ability
	ability.execute_ability(owner_entity, target)
	ability_executed.emit(ability_name)
	
	return true

# ============================================
# ENERGY SYSTEM
# ============================================

func add_energy(amount: float) -> void:
	"""Add energy"""
	current_energy = min(max_energy, current_energy + amount)

func consume_energy(amount: float) -> bool:
	"""Consume energy, return success"""
	if current_energy >= amount:
		current_energy -= amount
		return true
	return false

func get_energy() -> float:
	"""Get current energy"""
	return current_energy

func get_energy_percent() -> float:
	"""Get energy as percentage (0.0 to 1.0)"""
	return current_energy / max_energy if max_energy > 0 else 0.0

# ============================================
# COOLDOWN UTILITIES
# ============================================

func get_ability_cooldown(slot: int) -> float:
	"""Get remaining cooldown for ability in slot"""
	var ability = get_ability(slot)
	return ability.get_remaining_cooldown() if ability else 0.0

func reset_all_cooldowns() -> void:
	"""Reset all ability cooldowns to zero"""
	for ability in ability_slots:
		if ability:
			ability.reset_cooldown()

func is_any_ability_ready() -> bool:
	"""Check if at least one ability is ready to cast"""
	for ability in ability_slots:
		if ability and ability.is_ability_ready():
			return true
	return false
