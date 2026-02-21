## Ability base class - defines interface for all abilities
## All abilities (passive, active, basic) inherit from this
##
## Signals:
##   ability_triggered(ability_name: StringName) — emitted when ability activates
##   ability_cooldown_started(ability_name: StringName, duration: float) — emitted when cooldown begins
##   ability_ready(ability_name: StringName) — emitted when ability comes off cooldown
##
## Virtual Methods (override in child classes):
##   get_ability_name() -> StringName
##   is_ability_ready() -> bool
##   can_cast_ability() -> bool
##   execute_ability(caster: Node2D, target: Node2D = null) -> void

extends Resource
class_name AbilityBase

signal ability_triggered(ability_name: StringName)
signal ability_cooldown_started(ability_name: StringName, duration: float)
signal ability_ready(ability_name: StringName)

@export var ability_name: StringName = &"Ability"
@export var ability_description: String = "Base ability"
@export var cooldown_duration: float = 1.0
@export var energy_cost: float = 0.0
@export var is_passive: bool = false

var caster: Node2D = null
var current_cooldown: float = 0.0

func _ready() -> void:
	"""Initialize ability (can be overridden)"""
	pass

func _process(delta: float) -> void:
	"""Update cooldown (usually called by caster)"""
	if current_cooldown > 0.0:
		current_cooldown -= delta
		if current_cooldown <= 0.0:
			current_cooldown = 0.0
			ability_ready.emit(ability_name)

func get_ability_name() -> StringName:
	"""Get ability name"""
	return ability_name

func is_ability_ready() -> bool:
	"""Check if ability is off cooldown"""
	return current_cooldown <= 0.0

func can_cast_ability(caster_entity: Node2D = null) -> bool:
	"""Check if ability can be cast (override for special logic)"""
	if caster_entity and caster_entity.has_method("get_energy"):
		var current_energy = caster_entity.call("get_energy")
		return is_ability_ready() and current_energy >= energy_cost
	return is_ability_ready()

func execute_ability(caster_entity: Node2D, target: Node2D = null) -> void:
	"""Execute the ability (must override in child classes)"""
	push_warning("execute_ability() not implemented in " + ability_name)

func start_cooldown() -> void:
	"""Start ability cooldown"""
	current_cooldown = cooldown_duration
	ability_cooldown_started.emit(ability_name, cooldown_duration)

func reset_cooldown() -> void:
	"""Reset cooldown to zero (ability ready immediately)"""
	current_cooldown = 0.0
	ability_ready.emit(ability_name)

func get_remaining_cooldown() -> float:
	"""Get how long until ability is ready"""
	return max(0.0, current_cooldown)
