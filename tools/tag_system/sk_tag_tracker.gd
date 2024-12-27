@tool
class_name SKTagTracker
extends Resource

const WORLD_TAG := &"world"
const ENTITY_TAG := &"entity"
const NETWORK_TAG := &"network"
const SEARCH_PATTERN := "(?P<name>[^\\/\n\\r]+)\\.(?:t?scn|t?res)"

var regex := RegEx.new()

@export var tag_map: Dictionary[StringName, PackedInt64Array] = {}
@export var name_map: Dictionary[int, String] = {}


func add_world(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	name_map[uid] = get_name_for_path(path)
	tag_map.get_or_add(WORLD_TAG, PackedInt64Array()).append(uid)


func remove_world(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	tag_map.get_or_add(WORLD_TAG, PackedInt64Array()).erase(uid)
	name_map.erase(uid)


func add_entity(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	name_map[uid] = get_name_for_path(path)
	tag_map.get_or_add(ENTITY_TAG, PackedInt64Array()).append(uid)


func remove_entity(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	tag_map.get_or_add(ENTITY_TAG, PackedInt64Array()).erase(uid)
	name_map.erase(uid)


func add_network(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	name_map[uid] = get_name_for_path(path)
	tag_map.get_or_add(NETWORK_TAG, PackedInt64Array()).append(uid)


func remove_network(path: String) -> void:
	var uid: int = ResourceLoader.get_resource_uid(path)
	tag_map.get_or_add(NETWORK_TAG, PackedInt64Array()).erase(uid)
	name_map.erase(uid)


func get_name_for_path(path: String) -> String:
	if not regex.is_valid():
		regex.compile(SEARCH_PATTERN)
	var reg_match: RegExMatch = regex.search(path)
	return reg_match.get_string(reg_match.names.get_or_add("name", 0))
