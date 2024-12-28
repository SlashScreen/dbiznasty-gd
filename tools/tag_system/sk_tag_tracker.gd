@tool
class_name SKTagTracker
extends Resource

const WORLD_TAG := &"world"
const ENTITY_TAG := &"entity"
const NETWORK_TAG := &"network"
const SEARCH_PATTERN := "(?P<name>[^\\/\n\\r]+)\\.(?:t?scn|t?res)"

var regex := RegEx.new()

@export var tag_map: Dictionary[StringName, PackedInt64Array] = {}
@export var name_map: Dictionary[int, StringName] = {}
@export var reverse_name_map: Dictionary[StringName, int] = {} 


func add_to_tag(tag: StringName, path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	add_to_name_map(path, uid)
	if not tag_map.get_or_add(tag, PackedInt64Array()).has(uid):
		tag_map[tag].append(uid)


func remove_from_tag(tag: StringName, path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	var arr: PackedInt64Array = tag_map.get_or_add(tag, PackedInt64Array())
	var idx: int = arr.find(uid)
	if not idx == -1:
		arr.remove_at(idx)
	remove_from_name_map(uid)


func is_in_tag(tag: StringName, path:String) -> bool:
	var uid: int = ResourceLoader.get_resource_uid(path)
	return tag_map.get_or_add(tag, PackedInt64Array()).has(uid)


func is_name_in_tag(tag: StringName, n: StringName) -> bool:
	if not has_name(n):
		return false
	var uid: int = get_uid_for_name(n)
	return tag_map.get_or_add(tag, PackedInt64Array()).has(uid)


func add_world(path: String) -> void:
	add_to_tag(WORLD_TAG, path)


func remove_world(path: String) -> void:
	remove_from_tag(WORLD_TAG, path)


func is_world(path: String) -> bool:
	return is_in_tag(WORLD_TAG, path)


func is_name_world(n: StringName) -> bool:
	return is_name_in_tag(WORLD_TAG, n)


func add_entity(path: String) -> void:
	add_to_tag(ENTITY_TAG, path)


func remove_entity(path: String) -> void:
	remove_from_tag(WORLD_TAG, path)


func is_entity(path: String) -> bool:
	return is_in_tag(ENTITY_TAG, path)


func is_name_entity(n: StringName) -> bool:
	return is_name_in_tag(ENTITY_TAG, n)


func add_network(path: String) -> void:
	add_to_tag(NETWORK_TAG, path)


func remove_network(path: String) -> void:
	remove_from_tag(WORLD_TAG, path)


func is_network(path: String) -> bool:
	return is_in_tag(NETWORK_TAG, path)


func is_name_network(n: StringName) -> bool:
	return is_name_in_tag(NETWORK_TAG, n)


func get_uid_for_name(n: StringName) -> int:
	if has_name(n):
		return reverse_name_map[n]
	else:
		return ResourceUID.INVALID_ID


func add_to_name_map(path: String, uid: int) -> void:
	var p_name: StringName = get_name_for_path(path)
	name_map[uid] = p_name
	reverse_name_map[p_name] = uid


func remove_from_name_map(uid: int) -> void:
	var p_name: StringName = name_map[uid]
	name_map.erase(uid)
	reverse_name_map.erase(p_name)


func has_name(n: StringName) -> bool:
	return reverse_name_map.has(n)


func get_name_for_path(path: String) -> StringName:
	if not regex.is_valid():
		regex.compile(SEARCH_PATTERN)
	var reg_match: RegExMatch = regex.search(path)
	return StringName(reg_match.get_string(reg_match.names.get_or_add("name", 0)))
