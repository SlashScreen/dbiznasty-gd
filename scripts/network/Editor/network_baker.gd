@tool
extends Node

const MIN_TRI_SIZE := 1.0

@export var nav_mesh: NavigationMesh
@export_tool_button("Bake") var bake_fn = bake


func bake() -> void:
	var barycenters: Array[Vector3]
	var areas: Dictionary[int, float] = {}
	var vert_map: Dictionary[int, PackedInt32Array] = {}
	var poly_map: Dictionary[int, int]
	
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
		poly_map[i] = b_idx # Assign barycenter to polygon
		vert_map.get_or_add(point_a, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
		vert_map.get_or_add(point_b, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
		vert_map.get_or_add(point_c, PackedInt32Array()).append(b_idx) # assign barycenter to a vector index
	
	# Stage 2 - Connect points that share vertices 
	
	var connections: Array[Connection] = []
	for v_idx: int in vert_map:
		var vert_shares: PackedInt32Array = vert_map[v_idx]
		for a: int in vert_shares:
			for b: int in vert_shares:
				if a == b:
					continue
				connections.append(Connection.new(a, b))
	
	# Stage 3 - Connect portals
	
	# TODO


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
