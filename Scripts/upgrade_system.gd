## Universal upgrade and progression system
## Manages purchasable upgrades, progression trees, and stat modifications
##
## Features:
##   - Tree-based upgrade progression
##   - Currency-based purchasing
##   - Level-based requirements
##   - Stat modification application
##   - Persistent upgrade state
##   - Easy integration with any entity
##
## Dependencies:
##   - Global autoload (for currency management)
##   - Types autoload (for upgrade metadata)

extends Resource
class_name UpgradeSystem

# ============================================
# SIGNALS
# ============================================

signal upgrade_purchased(upgrade_id: StringName)
signal upgrade_available(upgrade_id: StringName)
signal currency_changed(new_amount: float)
signal level_changed(new_level: int)

# ============================================
# EXPORT PROPERTIES - GAME STATE
# ============================================

@export var player_level: int = 1
@export var max_level: int = 50
@export var current_currency: float = 0.0
@export var purchased_upgrades: Dictionary = {} # upgrade_id -> true
@export var available_upgrades: Array[UpgradeData] = []

@export_group("Currency")
@export var currency_name: StringName = &"Gold"
@export var currency_per_kill: float = 10.0
@export var currency_per_level: float = 100.0

@export_group("Progression")
@export var xp_per_kill: float = 10.0
@export var xp_to_level_up: float = 100.0
@export var xp_multiplier_per_level: float = 1.1

# ============================================
# INTERNAL STATE
# ============================================

var current_xp: float = 0.0
var upgrade_effects: Dictionary = {} # upgrade_id -> [stat_changes]

# ============================================
# LIFECYCLE
# ============================================

func _init() -> void:
	if available_upgrades.is_empty():
		_setup_default_upgrades()

# ============================================
# CURRENCY SYSTEM
# ============================================

func add_currency(amount: float) -> void:
	"""Add currency to player"""
	current_currency += amount
	currency_changed.emit(current_currency)

func spend_currency(amount: float) -> bool:
	"""Attempt to spend currency"""
	if current_currency >= amount:
		current_currency -= amount
		currency_changed.emit(current_currency)
		return true
	return false

func get_currency() -> float:
	"""Get current currency amount"""
	return current_currency

# ============================================
# XP & LEVELING
# ============================================

func add_xp(amount: float) -> void:
	"""Add XP and check for level-up"""
	current_xp += amount
	var xp_needed = _calculate_xp_for_next_level()
	
	while current_xp >= xp_needed and player_level < max_level:
		current_xp -= xp_needed
		player_level += 1
		level_changed.emit(player_level)
		
		# Grant currency on level up
		add_currency(currency_per_level)
		
		# Check for new available upgrades
		_check_available_upgrades()
		
		xp_needed = _calculate_xp_for_next_level()

func _calculate_xp_for_next_level() -> float:
	"""Calculate XP threshold for next level"""
	return xp_to_level_up * pow(xp_multiplier_per_level, player_level - 1)

func get_xp_ratio() -> float:
	"""Get current XP as ratio to next level (0-1)"""
	var total_xp = _calculate_xp_for_next_level()
	return min(1.0, current_xp / total_xp)

# ============================================
# UPGRADE SYSTEM
# ============================================

func purchase_upgrade(upgrade_id: StringName) -> bool:
	"""Attempt to purchase an upgrade"""
	if purchased_upgrades.get(upgrade_id, false):
		#Already purchased
		return false
	
	var upgrade = _find_upgrade(upgrade_id)
	if not upgrade:
		push_error("Upgrade not found: %s" % upgrade_id)
		return false
	
	# Check requirements
	if not _check_requirements(upgrade):
		return false
	
	# Check currency
	if not spend_currency(upgrade.cost):
		return false
	
	# Apply upgrade
	purchased_upgrades[upgrade_id] = true
	_apply_upgrade_effects(upgrade)
	upgrade_purchased.emit(upgrade_id)
	
	return true

func is_upgrade_purchased(upgrade_id: StringName) -> bool:
	"""Check if upgrade was purchased"""
	return purchased_upgrades.get(upgrade_id, false)

func can_purchase_upgrade(upgrade_id: StringName) -> bool:
	"""Check if upgrade can be purchased"""
	if purchased_upgrades.get(upgrade_id, false):
		return false
	
	var upgrade = _find_upgrade(upgrade_id)
	if not upgrade:
		return false
	
	return _check_requirements(upgrade) and current_currency >= upgrade.cost

func get_upgrade_status(upgrade_id: StringName) -> Dictionary:
	"""Get detailed status of an upgrade"""
	var upgrade = _find_upgrade(upgrade_id)
	if not upgrade:
		return {}
	
	return {
		"id": upgrade_id,
		"name": upgrade.upgrade_name,
		"description": upgrade.description,
		"cost": upgrade.cost,
		"purchased": is_upgrade_purchased(upgrade_id),
		"can_purchase": can_purchase_upgrade(upgrade_id),
		"level_required": upgrade.required_level,
		"prerequisite": upgrade.prerequisite_id,
	}

func get_available_upgrades() -> Array[UpgradeData]:
	"""Get list of currently purchasable upgrades"""
	var available: Array[UpgradeData] = []
	for upgrade in available_upgrades:
		if can_purchase_upgrade(upgrade.id):
			available.append(upgrade)
	return available

func _check_requirements(upgrade: UpgradeData) -> bool:
	"""Check if upgrade requirements are met"""
	# Check level requirement
	if player_level < upgrade.required_level:
		return false
	
	# Check prerequisite
	if upgrade.prerequisite_id != &"" and not is_upgrade_purchased(upgrade.prerequisite_id):
		return false
	
	return true

func _find_upgrade(upgrade_id: StringName) -> UpgradeData:
	"""Find upgrade by ID"""
	for upgrade in available_upgrades:
		if upgrade.id == upgrade_id:
			return upgrade
	return null

func _apply_upgrade_effects(upgrade: UpgradeData) -> void:
	"""Apply stat modifications from upgrade"""
	upgrade_effects[upgrade.id] = upgrade.stat_changes.duplicate()

func _check_available_upgrades() -> void:
	"""Check which upgrades became available after level up"""
	for upgrade in available_upgrades:
		if can_purchase_upgrade(upgrade.id):
			upgrade_available.emit(upgrade.id)

# ============================================
# DEFAULT UPGRADES SETUP
# ============================================

func _setup_default_upgrades() -> void:
	"""Create sample upgrade tree"""
	var base_attack = UpgradeData.new()
	base_attack.id = &"base_attack_1"
	base_attack.upgrade_name = "Attack Power I"
	base_attack.description = "Increase attack damage by 10%"
	base_attack.cost = 100.0
	base_attack.required_level = 1
	base_attack.stat_changes = {"damage": 1.1}
	available_upgrades.append(base_attack)
	
	var base_health = UpgradeData.new()
	base_health.id = &"base_health_1"
	base_health.upgrade_name = "Toughness I"
	base_health.description = "Increase max health by 20%"
	base_health.cost = 75.0
	base_health.required_level = 2
	base_health.stat_changes = {"max_health": 1.2}
	available_upgrades.append(base_health)

# ============================================
# HELPER METHODS
# ============================================

func apply_stat_modifier(target: Node, stat_name: String, modifier: float) -> void:
	"""Apply stat modifier to target node"""
	if stat_name in target and typeof(target[stat_name]) == TYPE_FLOAT:
		target[stat_name] *= modifier

func get_level_percentage() -> float:
	"""Get player progression as percentage"""
	return float(player_level) / float(max_level)

func reset_progression() -> void:
	"""Reset all upgrades (for testing)"""
	purchased_upgrades.clear()
	player_level = 1
	current_xp = 0.0
	current_currency = 0.0
	upgrade_effects.clear()

# ============================================
# UPGRADE DATA RESOURCE
# ============================================

class_name UpgradeData
extends Resource

@export var id: StringName = &"upgrade_id"
@export var upgrade_name: String = "Upgrade Name"
@export var description: String = "Upgrade description"
@export var cost: float = 100.0
@export var required_level: int = 1
@export var prerequisite_id: StringName = &"" # Empty string = no prerequisite
@export var icon: Texture2D = null
@export var stat_changes: Dictionary = {} # stat_name -> multiplier or value
@export var max_purchases: int = 1 # -1 for infinite purchases per level
