@tool
extends Node

const MIN_TRI_SIZE := 1.0
const Octree = preload("res://addons/skelerealms/scripts/network/octree.gd")

@export var nav_mesh: NavigationMesh
@export_tool_button("Bake") var bake_fn = bake


# TODO:
# - do portals in same world work?


func bake() -> CoarseNetwork:
	var barycenters: Array[Vector3]
	var areas: Dictionary[int, float] = {}
	var vert_map: Dictionary[int, PackedInt32Array] = {}
	
	# Stage 1
	
	var verts: PackedVector3Array = nav_mesh.get_vertices()
	for i: int in nav_mesh.get_polygon_count():
		var polygon: PackedInt32Array = nav_mesh.get_polygon(i)
		var point_a: Vector3 = verts[polygon[0]]
		var point_b: Vector3 = verts[polygon[1]]
		var point_c: Vector3 = verts[polygon[2]]
		
		var barycenter: Vector3 = get_barycenter(point_a, point_b, point_c)
		var area: float = area_of_triangle(point_a, point_b, point_c)
		
		var b_idx: int = barycenters.size()
		barycenters.append(barycenter)
		areas[b_idx] = area
		vert_map.get_or_add(point_a, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
		vert_map.get_or_add(point_b, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
		vert_map.get_or_add(point_c, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
	
	# Stage 2 - Connect points that share vertices 
	
	var connections: Array[Connection] = []
	var connections_map: Dictionary[int, Array] = {}
	for v_idx: int in vert_map:
		var vert_shares: PackedInt32Array = vert_map[v_idx]
		for a: int in vert_shares:
			for b: int in vert_shares:
				if a == b:
					continue
				var c := Connection.new(a, b)
				connections.append(c)
				connections_map.get_or_add(a, []).append(c)
				connections_map.get_or_add(b, []).append(c)
	
	# Stage 2.5 - Prune points
	
	var to_remove := PackedInt32Array()
	for idx: int in areas.size():
		if areas[idx] < MIN_TRI_SIZE:
			to_remove.append(idx)
	
	for idx: int in to_remove:
		var others := PackedInt32Array() 
		# Grab others this is connected to
		for c: Connection in connections_map.get_or_add(idx, []):
			var other_idx: int
			if c.a == idx:
				other_idx = c.b
			else:
				other_idx = c.a
			others.push_back(other_idx)
			connections_map.get_or_add(idx, []).erase(c)
			connections.erase(c)
		# connect others to eachother
		# inefficient but whatever it's a build time tool
		for a: int in others:
			for b: int in others:
				if a == b: continue
				var c := Connection.new(a, b)
				connections.append(c)
				connections_map.get_or_add(a, []).append(c)
				connections_map.get_or_add(b, []).append(c)
	
	# actually remove
	for idx: int in to_remove:
		areas.erase(idx)
		barycenters.remove_at(idx)
	
	# Stage 3 - Generate Octree
	
	var max_point: Vector3 = barycenters.max()
	var max_dist: float = Vector3.ZERO.distance_to(max_point)
	var min_point: Vector3 = barycenters.min()
	var min_dist: float = Vector3.ZERO.distance_to(min_point)
	
	var longest_distance: float = max_point[max_point.max_axis_index()] if max_dist > min_dist else min_point[min_point.max_axis_index()] 
	var octree := Octree.new()
	octree.aabb = AABB(-Vector3(longest_distance, longest_distance, longest_distance), Vector3(longest_distance, longest_distance, longest_distance) * 2.0)
	
	for pos: int in barycenters.size():
		octree.insert(barycenters, pos)
		
	# Stage 4 - Connect portals
	
	var portals: Array[Node] = get_tree().get_nodes_in_group(&"network portal")
	var connection_info: Array = (
		portals
		.filter(func(x: Node) -> bool: return x.has_method(&"get_coarse_nav_info"))
		.map(func(x: Node) -> Dictionary: return x.get_coarse_nav_info())
	)
	var portal_info: Dictionary[int, Dictionary] = {}
	for info: Dictionary in connection_info:
		var closest_index: int = octree.find_nearest_point(barycenters, info.position).best_point
		barycenters.append(info.position) # add portal
		var portal_index: int = barycenters.size() - 1
		portal_info[portal_index] = { # add portal info
			&"destination_world": info.destination_world,
			&"destination_position": info.destination_position,
		}
		connections.append(Connection.new(portal_index, closest_index))
	
	# Stage 5 - Build network
	
	var coarse_network := CoarseNetwork.new()
	var compressed_connections := PackedInt64Array()
	for c: Connection in connections:
		compressed_connections.append(c.a)
		compressed_connections.append(c.b)
	coarse_network.connections = compressed_connections
	coarse_network.octree = octree
	coarse_network.positions = barycenters
	coarse_network.portals = portals
	coarse_network.portal_destinations = portal_info
	coarse_network.portal_connections = analyze_portals(barycenters, portals, connections)
	
	return coarse_network


## Here's how this works:
## This checks what portals can connect with which other portals within the same world. The nav solver first checks if there is an avalible path from 1 world to another;
## This works by simply pathfinding around portals. But what if 2 portals in the same world cannot be pathfinded between in the same world?
## Instead of pathfinding through the world, it ignores the world entirely, and only needs to know *whether* portal A can be reached from portal B or not. This is calculated here
## at bake time. This was inspired by a [pathfinding optimization done in Factorio](https://factorio.com/blog/post/fff-317).
func analyze_portals(points: PackedVector3Array, portals: PackedInt64Array, node_connections: Array[Connection]) -> PackedInt64Array:
	var portal_connections := PackedInt64Array()
	# set up astar
	var astar := AStar3D.new()
	astar.reserve_space(points.size())
	for p_idx: int in points.size():
		astar.add_point(p_idx, points[p_idx])
	for c: Connection in node_connections:
		astar.connect_points(c.a, c.b)
	# check connections
	for a: int in portals:
		for b: int in portals:
			if a == b: continue
			var path: PackedInt64Array = astar.get_id_path(a, b) # Try to find a path between two portals
			if not path.is_empty(): # If one is found, add to connections list
				portal_connections.push_back(a)
				portal_connections.push_back(b)
	
	return portal_connections


func area_of_triangle(point_a: Vector3, point_b: Vector3, point_c: Vector3) -> float:
	var side_a := point_a.distance_to(point_b)
	var side_b := point_b.distance_to(point_c)
	var side_c := point_c.distance_to(point_a)

	var semi_perimeter: float = (side_a + side_b + side_c) / 2.0
	return sqrt(semi_perimeter * (semi_perimeter - side_a) * (semi_perimeter - side_b) * (semi_perimeter - side_c))


func get_barycenter(point_a: Vector3, point_b: Vector3, point_c: Vector3) -> Vector3:
	return (point_a + point_b + point_c) / 3.0


class Connection:
	var a: int
	var b: int
	
	func _init(p_a: int, p_b: int) -> void:
		a = p_a
		b = p_b
