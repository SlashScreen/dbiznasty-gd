extends Node

var worlds: Dictionary[StringName, World] = {}
var portal_map: PortalNetwork

func build(networks: Dictionary[StringName, CoarseNetwork]) -> void:
	portal_map = PortalNetwork.new()
	
	for world_name: StringName in networks:
		var cs: CoarseNetwork = networks[world_name]
		var new_world := World.new()
		new_world.load_network(cs)
		worlds[world_name] = new_world
		
		_compile_portals(new_world, world_name, cs.portals, cs.portal_destinations, cs.portal_connections)


func _compile_portals(world: World, for_world: StringName, portals: PackedInt32Array, portal_info: Dictionary[int, Dictionary], portal_connections: PackedInt32Array) -> void:
	portal_map = PortalNetwork.new()
	
	# Pass 1: Add world portals
	
	for p: int in portals:
		portal_map.add_world_point(world.get_point_position(p), for_world, p)
	# Add precomputed intra-world connections
	for conn_idx in range(0, world.portal_connections.size(), 2):
		portal_map.add_intra_world_connection(for_world, portal_connections[conn_idx], portal_connections[conn_idx + 1])

# Pass 2: Add inter-world connections

	for p: int in portal_info:
		var p_i: Dictionary = world.portal_info[p]
		
		var dest_world: StringName = p_i.destination_world
		var dest_pos: Vector3 = p_i.destination_position
		var dest_idx: int = worlds[dest_world].get_closest_point(dest_pos)
		portal_map.add_inter_world_connection(for_world, p, dest_world, dest_idx)


func find_path(from_world: StringName, from_position: Vector3, to_world: StringName, to_position: Vector3) -> Array[CoarseNavStep]:
	return []


func _find_path_within_world(world_name: StringName, from: Vector3, to: Vector3) -> CoarseNavStep.MoveThroughWorldStep:
	var world: World = worlds[world_name]
	var from_idx: int = world.get_closest_point(from)
	var to_idx: int = world.get_closest_point(to)
	var path: PackedVector3Array = world.get_point_path(from_idx, to_idx)
	if path.is_empty():
		return null
	
	var step := CoarseNavStep.MoveThroughWorldStep.new()
	step.path = path
	return step


class World:
	extends AStar3D

	func load_network(cn: CoarseNetwork) -> void:
		reserve_space(cn.positions.size())
		var idx: int = 0

		for p: Vector3 in cn.positions:
			add_point(idx, p)
			idx += 1

		for conn_idx in range(0, cn.connections.size(), 2):
			connect_points(cn.connections[conn_idx], cn.connections[conn_idx + 1])


class PortalNetwork:
	extends AStar3D

	const SAME_WORLD_COST := 1.0
	const DIFFERENT_WORLD_COST := 1000.0

	var portal_id_to_world_info: Dictionary[int, Dictionary] = {}
	var world_info_to_portal_id: Dictionary[Dictionary, int] = {}
	
	func add_world_point(point: Vector3, world_name: StringName, source_index: int) -> void:
		var p_idx: int = get_point_capacity()
		add_point(p_idx, point)
		portal_id_to_world_info[p_idx] = {
			&"world": world_name,
			&"source_index": source_index,
		}
		world_info_to_portal_id[{
			&"world": world_name,
			&"source_index": source_index,
		}] = p_idx
	
	func add_intra_world_connection(world_name: StringName, from_src: int, to_src: int) -> void:
		var from: int = world_info_to_portal_id[{
			&"world": world_name,
			&"source_index": from_src,
		}]
		var to: int = world_info_to_portal_id[{
			&"world": world_name,
			&"source_index": to_src,
		}]
		connect_points(from, to)
	
	func add_inter_world_connection(from_world: StringName, from_src_idx: int, to_world: StringName, to_src_idx: int) -> void:
		var from: int = world_info_to_portal_id[{
			&"world": from_world,
			&"source_index": from_src_idx,
		}]
		var to: int = world_info_to_portal_id[{
			&"world": to_world,
			&"source_index": to_src_idx,
		}]
		connect_points(from, to)
	
	func _compute_cost(from_id: int, to_id: int) -> float:
		if portal_id_to_world_info[from_id].world == portal_id_to_world_info[to_id].world:
			return SAME_WORLD_COST
		else:
			return DIFFERENT_WORLD_COST

	func _estimate_cost(from_id: int, end_id: int) -> float:
		return _compute_cost(from_id, end_id)


class CoarseNavStep:
	class MoveThroughWorldStep:
		var path: PackedVector3Array
	
	class MoveBetweenWorldsStep:
		var to_world: StringName
		var to_pos: Vector3
