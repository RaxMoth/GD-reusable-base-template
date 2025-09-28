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
