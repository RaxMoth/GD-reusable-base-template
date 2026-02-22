## Wave-based enemy spawner system
## Manages spawn waves, enemy groups, and difficulty scaling
##
## Features:
##   - Wave progression with delay between waves
##   - Multiple enemy types per wave
##   - Difficulty scaling across waves
##   - Customizable spawn patterns
##   - Signals for wave start/complete/all_complete
##   - XP/currency rewards per wave
##   - Easy configuration via export properties
##
## Dependencies:
##   - EntityBase (for enemies)
##   - Global autoload
##   - Types autoload

extends Node
class_name WaveSpawner

# ============================================
# SIGNALS
# ============================================

signal wave_started(wave_number: int, total_enemies: int)
signal wave_completed(wave_number: int, enemies_defeated: int)
signal all_waves_completed(total_waves: int)
signal enemy_spawned(enemy: Node, wave: int)
signal difficulty_increased(multiplier: float)

# ============================================
# EXPORT PROPERTIES
# ============================================

@export_group("Wave Settings")
@export var total_waves: int = 5
@export var delay_between_waves: float = 3.0
@export var max_spawned_at_once: int = 5

@export_group("Scaling")
@export var enemy_health_scale: float = 1.1 # Health multiplier per wave
@export var enemy_damage_scale: float = 1.05 # Damage multiplier per wave
@export var wave_size_scale: float = 1.15 # Enemy count multiplier per wave

@export_group("Rewards")
@export var base_xp_per_wave: float = 100.0
@export var base_currency_per_wave: float = 50.0
@export var reward_scale: float = 1.2

@export_group("Spawn Points")
@export var spawn_points: Array[Marker2D] = [] # Assign in editor

@export_group("Wave Data")
@export var waves: Array[WaveData] = [] # Populated in editor or via code

# ============================================
# INTERNAL STATE
# ============================================

var current_wave: int = 0
var is_spawning: bool = false
var active_enemies: Array[Node] = []
var wave_timer: Timer = null
var spawn_timer: Timer = null

var current_difficulty_multiplier: float = 1.0

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	# Create internal timers
	wave_timer = Timer.new()
	spawn_timer = Timer.new()
	add_child(wave_timer)
	add_child(spawn_timer)
	
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	if spawn_points.is_empty():
		push_warning("WaveSpawner: No spawn points assigned!")

func _physics_process(_delta: float) -> void:
	# Clean up dead enemies
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))

# ============================================
# WAVE MANAGEMENT
# ============================================

func start_waves() -> void:
	"""Begin wave spawning"""
	if is_spawning:
		return
	
	current_wave = 0
	is_spawning = true
	_start_next_wave()

func _start_next_wave() -> void:
	"""Start the next wave"""
	if current_wave >= total_waves:
		is_spawning = false
		all_waves_completed.emit(total_waves)
		return
	
	current_wave += 1
	_spawn_wave(current_wave)

func _spawn_wave(wave_number: int) -> void:
	"""Spawn all enemies for a wave"""
	if wave_number > waves.size():
		push_error("WaveSpawner: Wave %d not configured" % wave_number)
		return
	
	var wave_data = waves[wave_number - 1]
	var total_enemies = _calculate_wave_size(wave_data.base_enemy_count)
	
	wave_started.emit(wave_number, total_enemies)
	
	# Update difficulty
	current_difficulty_multiplier = pow(1.1, wave_number - 1)
	difficulty_increased.emit(current_difficulty_multiplier)
	
	# Spawn enemies over time using spawn timer
	var spawn_index = 0
	spawn_timer.start(wave_data.spawn_interval)

func _on_spawn_timer_timeout() -> void:
	"""Spawn next enemy in wave"""
	if current_wave > waves.size():
		spawn_timer.stop()
		_on_wave_completed()
		return
	
	var wave_data = waves[current_wave - 1]
	var total_to_spawn = _calculate_wave_size(wave_data.base_enemy_count)
	
	if active_enemies.size() < total_to_spawn:
		_spawn_single_enemy(wave_data)
	else:
		# Wait for enemies to die
		if active_enemies.is_empty():
			spawn_timer.stop()
			_on_wave_completed()

func _spawn_single_enemy(wave_data: WaveData) -> void:
	"""Spawn a single enemy"""
	if wave_data.enemy_scenes.is_empty():
		return
	
	var enemy_scene = wave_data.enemy_scenes[randi() % wave_data.enemy_scenes.size()]
	var spawn_point = spawn_points[randi() % spawn_points.size()] if not spawn_points.is_empty() else global_position
	
	var enemy = enemy_scene.instantiate() as Node
	spawn_point.add_child(enemy)
	enemy.global_position = spawn_point.global_position
	
	# Apply scaling
	if enemy.has_method("set_stats_multiplier"):
		enemy.set_stats_multiplier(current_difficulty_multiplier)
	elif "max_health" in enemy and "base_attack_damage" in enemy:
		enemy.max_health *= pow(enemy_health_scale, current_wave - 1)
		enemy.base_attack_damage *= pow(enemy_damage_scale, current_wave - 1)
	
	active_enemies.append(enemy)
	enemy_spawned.emit(enemy, current_wave)
	
	# Connect to death signal if available
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bindv([enemy]))

func _on_enemy_died(enemy: Node) -> void:
	"""Handle enemy death"""
	active_enemies.erase(enemy)
	
	# Reward player
	if current_wave <= waves.size():
		var wave_data = waves[current_wave - 1]
		var xp_reward = base_xp_per_wave * pow(reward_scale, current_wave - 1)
		var currency_reward = base_currency_per_wave * pow(reward_scale, current_wave - 1)

func _on_wave_completed() -> void:
	"""Wave finished (all enemies spawned and dead)"""
	wave_completed.emit(current_wave, active_enemies.size())
	
	# Start next wave after delay
	wave_timer.start(delay_between_waves)

func _on_wave_timer_timeout() -> void:
	"""Delay timer finished, start next wave"""
	_start_next_wave()

# ============================================
# HELPER METHODS
# ============================================

func _calculate_wave_size(base_size: int) -> int:
	"""Calculate total enemies for wave with scaling"""
	return int(base_size * pow(wave_size_scale, current_wave - 1))

func pause_spawning() -> void:
	"""Pause wave spawning"""
	if wave_timer:
		wave_timer.paused = true
	if spawn_timer:
		spawn_timer.paused = true

func resume_spawning() -> void:
	"""Resume wave spawning"""
	if wave_timer:
		wave_timer.paused = false
	if spawn_timer:
		spawn_timer.paused = false

func stop_all_waves() -> void:
	"""Stop all spawning"""
	is_spawning = false
	if wave_timer:
		wave_timer.stop()
	if spawn_timer:
		spawn_timer.stop()
	active_enemies.clear()

func get_wave_progress() -> float:
	"""Get current wave as decimal 0-1"""
	return float(current_wave) / float(total_waves)

func get_active_enemy_count() -> int:
	"""Get count of living enemies"""
	return active_enemies.size()

# ============================================
# WAVE DATA RESOURCE
# ============================================

class_name WaveData
extends Resource

@export var base_enemy_count: int = 5
@export var spawn_interval: float = 1.0
@export var enemy_scenes: Array[PackedScene] = []
@export var special_conditions: String = "" # Notes for custom behavior
