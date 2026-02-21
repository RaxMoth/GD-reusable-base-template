extends Node

func get_node_from_group(group_name: String) -> Node2D:
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		print("No node found in group : ", group_name)
		return null
	return nodes[0] as Node2D

func get_map_from_group(group_name: String) -> TileMapLayer:
	var maps = get_tree().get_nodes_in_group(group_name)
	return maps[0] if maps.size() > 0 else null


func apply_rotation_and_flip(
	sprite_node: Node2D,
	area_node: Node2D,
	direction: Vector2,
	jitter_threshold: float = 0.05,
	side_scroll_flip: bool = false
) -> void:
	if direction.length_squared() < jitter_threshold * jitter_threshold:
		return

	var angle = direction.angle()

	if sprite_node:
		sprite_node.rotation = angle
		if side_scroll_flip:
			sprite_node.scale.x = -1 if direction.x < 0 else 1

	if area_node:
		area_node.rotation = angle
# ============================================
# ANGLE UTILITIES
# ============================================

func angle_difference(from: float, to: float) -> float:
	"""Calculate the shortest angle difference in radians"""
	var diff = fmod(to - from, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff

func normalize_angle(angle: float) -> float:
	"""Normalize angle to -PI to PI range"""
	var normalized = fmod(angle, TAU)
	if normalized > PI:
		normalized -= TAU
	elif normalized < -PI:
		normalized += TAU
	return normalized

func lerp_angle(from: float, to: float, weight: float) -> float:
	"""Smoothly interpolate between two angles"""
	var diff = angle_difference(from, to)
	return from + diff * weight

func angle_to_vector(angle: float) -> Vector2:
	"""Convert angle to unit vector"""
	return Vector2(cos(angle), sin(angle))

# ============================================
# SPATIAL QUERIES - WALL DETECTION
# ============================================

func is_point_too_close_to_wall(
	world: World2D,
	point: Vector2,
	min_radius: float = 32.0,
	collision_mask: int = 1,
	samples: int = 8
) -> bool:
	"""Check if a point is too close to any walls"""
	var space_state = world.direct_space_state
	
	for i in range(samples):
		var angle = i * TAU / samples
		var offset = Vector2.from_angle(angle) * min_radius
		var check_point = point + offset
		
		var query = PhysicsRayQueryParameters2D.create(point, check_point)
		query.collision_mask = collision_mask
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result:
			return true # Wall too close!
	
	return false

func count_walls_in_radius(
	world: World2D,
	point: Vector2,
	radius: float = 50.0,
	collision_mask: int = 1,
	samples: int = 12
) -> int:
	"""Count number of walls in radius around a point"""
	var space_state = world.direct_space_state
	var count = 0
	
	for i in range(samples):
		var angle = i * TAU / samples
		var check_point = point + Vector2.from_angle(angle) * radius
		
		var query = PhysicsRayQueryParameters2D.create(point, check_point)
		query.collision_mask = collision_mask
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result:
			count += 1
	
	return count

# ============================================
# TARGETING UTILITIES
# ============================================

func can_entity_target(attacker: Node, target: Node) -> bool:
	"""Determine if attacker can target this entity based on group affiliation"""
	if attacker == target:
		return false
	
	if attacker.is_in_group("Monster"):
		# Monsters attack Heroes and Mobs (but not other Monsters)
		if target.is_in_group("Hero"):
			return true
		elif target.is_in_group("Enemy") and not target.is_in_group("Monster"):
			return true # It's a Mob
	
	elif attacker.is_in_group("Enemy"):
		# Mobs attack Heroes and Monsters (but not other Mobs)
		if target.is_in_group("Hero"):
			return true
		elif target.is_in_group("Monster"):
			return true
	
	elif attacker.is_in_group("Hero"):
		# Heroes attack all enemies (Mobs and Monsters)
		if target.is_in_group("Enemy"):
			return true
	
	return false

func get_valid_targets_in_area(attacker: Node, detection_area: Area2D) -> Array[Node]:
	"""Get all valid targets in a detection area for an attacker"""
	var valid_targets: Array[Node] = []
	
	if not is_instance_valid(detection_area):
		return valid_targets
	
	for area in detection_area.get_overlapping_areas():
		var target_entity = area.get_owner()
		
		if not is_instance_valid(target_entity):
			continue
		if target_entity == attacker:
			continue
		
		if can_entity_target(attacker, target_entity):
			valid_targets.append(target_entity)
	
	return valid_targets

func find_nearest_valid_target(attacker: Node, detection_area: Area2D) -> Node:
	"""Find the closest valid target in a detection area"""
	var targets = get_valid_targets_in_area(attacker, detection_area)
	if targets.is_empty():
		return null
	
	var closest: Node = null
	var closest_dist = INF
	
	for target in targets:
		var dist = attacker.global_position.distance_squared_to(target.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = target
	
	return closest

# ============================================
# FOG OF WAR UTILITIES
# ============================================

func is_position_explored(fog_system: Node, position: Vector2) -> bool:
	"""Check if a position has been explored (for fog of war systems)"""
	if not is_instance_valid(fog_system):
		return false
	
	if fog_system.has_method("is_tile_explored"):
		return fog_system.is_tile_explored(position)
	
	return false