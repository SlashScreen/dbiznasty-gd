@tool

extends Resource

const Octree = preload("res://addons/skelerealms/scripts/network/octree.gd")
const MAX_POINT_COUNT: int = 4

var aabb: AABB
var data: PackedInt32Array
var children: Array[Octree] = []


func insert(points: PackedVector3Array, pos: int) -> void:
	if encloses(points[pos]):
		data.append(pos)
		if data.size() >= MAX_POINT_COUNT:
			_subdivide(points)


func encloses(point: Vector3) -> bool:
	return aabb.has_point(point)


func find_nearest_point(points: PackedVector3Array, point: Vector3, best_dist := INF, best_point: int = INF) -> Dictionary:
	if not data.is_empty(): # Leaf node
		for p: int in data:
			var dist: float = points[p].distance_squared_to(point)
			if dist < best_dist:
				best_dist = dist
				best_point = p
	elif not children.is_empty(): # branch node
		var octant: int = _get_octant_containing_point(point)
		match children[octant].find_nearest_point(points, point, best_dist, best_point):
			{&"best_point": var b_p, &"best_dist": var b_d}:
				best_point = b_p
				best_dist = b_d
		# Plane check
		# Distance to dividing planes
		var dx: float = abs(point.x - aabb.get_center().x)
		var dy: float = abs(point.y - aabb.get_center().y)
		var dz: float = abs(point.z - aabb.get_center().z)
		# if any dividing plane is better than best distance, check all children
		if min(dx, dy, dz) < best_dist:
			for o: Octree in children:
				match o.find_nearest_point(points, point, best_dist, best_point):
					{&"best_point": var b_p, &"best_dist": var b_d}:
						best_point = b_p
						best_dist = b_d
	return {
		&"best_point": best_point,
		&"best_dist": best_dist
	}


func _get_octant_containing_point(point: Vector3) -> int:
	var octant: int = 0
	if point.x >= aabb.get_center().x: octant |= 4
	if point.y >= aabb.get_center().y: octant |= 2
	if point.z >= aabb.get_center().z: octant |= 1
	return octant


func _subdivide(points: PackedVector3Array) -> void:
	var new_octrees: Array = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.end,
	].map(func(pos: Vector3) -> Octree: 
		var o: Octree = Octree.new()
		o.aabb = AABB(pos, aabb.size / 2.0)
		return o
		)
	
	children = new_octrees
	
	for point: int in data:
		var o: Octree = new_octrees[_get_octant_containing_point(points[point])]
		o.insert(points, point)
	
	data.clear()
