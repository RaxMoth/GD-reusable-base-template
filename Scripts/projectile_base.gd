## Base projectile class for bullets, spells, and effects
## Implements movement, collision detection, and damage on impact
##
## Features:
##   - Velocity-based movement
##   - Automatic lifetime management
##   - Collision-based targeting with damage falloff
##   - Signals for hit/miss events
##   - Knockback application
##   - Easy to extend for custom projectiles
##
## Dependencies:
##   - Physics detection (can be Area2D or RigidBody2D)
##   - Global autoload
##   - Types autoload (if using damage types)

extends Area2D
class_name ProjectileBase

# ============================================
# SIGNALS
# ============================================

signal hit_target(target: Node)
signal hit_world(position: Vector2)
signal projectile_destroyed

# ============================================
# EXPORT PROPERTIES
# ============================================

@export_group("Movement")
@export var projectile_speed: float = 500.0
@export var max_lifetime: float = 10.0
@export var direction: Vector2 = Vector2.RIGHT

@export_group("Damage")
@export var base_damage: float = 10.0
@export var damage_falloff: float = 1.0 # 1.0 = no falloff
@export var can_pierce: bool = false
@export var max_targets: int = 1

@export_group("Effects")
@export var apply_knockback: bool = true
@export var knockback_force: float = 100.0
@export var lifetime_visual_scale: Vector2 = Vector2.ONE

# ============================================
# INTERNAL STATE
# ============================================

var lifetime: float = 0.0
var targets_hit: Array[Node] = []
var sprite: Sprite2D = null

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	area_entered.connect(_on_area_entered)
	
	# Set initial rotation
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	# Destroy if max lifetime reached
	if lifetime >= max_lifetime:
		_destroy_projectile()
		return
	
	# Move projectile
	global_position += direction.normalized() * projectile_speed * delta

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with target"""
	var target_parent = area.get_parent()
	
	# Skip if we already hit this target or it's the source
	if target_parent in targets_hit:
		return
	
	# Check if it's an enemy
	if target_parent.is_in_group("Enemy"):
		_hit_target(target_parent)
	elif not area.is_in_group("Entity"):
		# Hit world obstacle
		hit_world.emit(global_position)
		if not can_pierce:
			_destroy_projectile()

func _hit_target(target: Node) -> void:
	"""Apply damage and effects to target"""
	targets_hit.append(target)
	hit_target.emit(target)
	
	# Apply damage
	var damage = base_damage * pow(damage_falloff, targets_hit.size() - 1)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Apply knockback
	if apply_knockback and target.has_method("apply_knockback"):
		target.apply_knockback(direction * knockback_force)
	
	# Destroy if not piercing or max targets reached
	if not can_pierce or targets_hit.size() >= max_targets:
		_destroy_projectile()

func _destroy_projectile() -> void:
	"""Clean up projectile"""
	projectile_destroyed.emit()
	queue_free()

# ============================================
# HELPER METHODS
# ============================================

func set_direction(new_direction: Vector2) -> void:
	"""Set projectile direction"""
	direction = new_direction.normalized()
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func set_speed(new_speed: float) -> void:
	"""Set projectile speed"""
	projectile_speed = new_speed

func set_damage(new_damage: float) -> void:
	"""Set projectile base damage"""
	base_damage = new_damage

func get_lifetime_ratio() -> float:
	"""Get time remaining as ratio (0-1)"""
	return 1.0 - (lifetime / max_lifetime)

func apply_lifetime_effects() -> void:
	"""Visual effects that change over lifetime (override for custom behavior)"""
	if sprite:
		var fade = get_lifetime_ratio()
		sprite.modulate.a = fade * lifetime_visual_scale.y
		sprite.scale = Vector2.ONE * fade * lifetime_visual_scale.x
