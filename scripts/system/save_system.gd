extends Node
## The savegame system.
## This should be autoloaded.

const DEBUG_JSON := false
const ENTITY_EXT := ".entity"
const WORLD_EXT := ".world"
const GAME_INFO_EXT := ".game"
const SAVE_FILE_EXT := ".save"
const GAME_INFO_GROUP := &"savegame gameinfo"
const OTHER_GROUP := &"savegame other"

## Called when the savegame is complete.
## Use this to, for example, freeze the game until complete, or tell the netity manager to clean up stale entities.
signal save_complete
## Called when the loading process is complete. See [signal save_complete].
signal load_complete

var active_save_file: ZIPReader:
	set(val):
		if active_save_file:
			active_save_file.close()
		active_save_file = val


## Save the game and write it to user://saves directory.
func save(character: int):
	var file_path: String = _get_most_recent_savegame(character)
	if file_path.is_empty():
		file_path = _generate_save_file_name() # Create a new file if there wasn't one already
	
	var packer := ZIPPacker.new()
	packer.open(file_path)
	#1: Entities
	var entities: Array[SKEntity] = SKEntityManager.instance.entities.values()
	_save_entites(packer, entities)
	#2: Game info
	var info_nodes: Array[Node] = get_tree().get_nodes_in_group(GAME_INFO_GROUP)
	save_all_game_info(packer, info_nodes)
	#3: World
	#4: Erased entities
	#5: Other
	var other_nodes: Array[Node] = get_tree().get_nodes_in_group(OTHER_GROUP)
	save_all_other(packer, other_nodes)
	
	packer.close()
	
	active_save_file = ZIPReader.new()
	active_save_file.open(file_path)
	
	save_complete.emit()


func cleanup() -> void:
	active_save_file = null # close save file


## Load the most recent savegame, if applicable.
func load_most_recent(character: int):
	var most_recent: String = _get_most_recent_savegame(character)
	# only load most recent if there are some
	if not most_recent.is_empty():
		load_game(most_recent)


## Load a game from a filepath.
func load_game(path: String):
	pass


## Check if an entity is accounted for in the save system. Returns the save data blob if there is, else none.
## Use sparingly; could get memory intensive.
func entity_in_save(ref_id: StringName) -> Dictionary:
	if not active_save_file:
		return {}
	var file_name: String = "%s%s" % [ref_id, ENTITY_EXT]
	if active_save_file.file_exists(file_name):
		return {}

	var bytes: PackedByteArray = active_save_file.read_file(file_name)

	return _deserialize(bytes)


## Gets the filepath for the most recent savegame. It is sorted by file modification time.
func _get_most_recent_savegame(character: int) -> String:
	var save_dir: String = "user://saves/%d/" % character
	if not DirAccess.dir_exists_absolute(save_dir):
		return ""

	var dir_files: Array[String] = []
	dir_files.append_array(DirAccess.get_files_at(save_dir))
	# if no saves, we got none
	if dir_files.is_empty():
		return ""
	# sort by modified time
	dir_files.sort_custom(func(a: String, b: String) -> bool: return FileAccess.get_modified_time(save_dir + a) < FileAccess.get_modified_time(save_dir + b))
	var most_recent_file: String = dir_files.pop_back()
	# format
	return save_dir + most_recent_file


## Turn the save game blob into a string.
func _serialize(data: Dictionary) -> PackedByteArray:
	if DEBUG_JSON:
		return JSON.stringify(data, "\t" if ProjectSettings.get_setting("skelerealms/savegame_indents") else "", true, true).to_utf8_buffer()
	else:
		return var_to_bytes_with_objects(data)


## Turn a string into a data blob.
## Like with [method _serialize], you can write your own.
func _deserialize(text: PackedByteArray) -> Dictionary:
	if DEBUG_JSON:
		return JSON.parse_string(text.get_string_from_utf8())
	else:
		return bytes_to_var_with_objects(text)


func _create_entity_file(handle: ZIPPacker, rid: StringName, data: Dictionary) -> void:
	var bytes: PackedByteArray = _serialize(data)
	var file_name: String = "%s%s" % [rid, ENTITY_EXT]

	handle.start_file(file_name)
	handle.write_file(bytes)
	handle.close_file()


func _save_entites(handle: ZIPPacker, entities: Array[SKEntity]) -> void:
	for e: SKEntity in entities:
		_create_entity_file(handle, e.name, e.save())


func _save_game_info(zip_handle: ZIPPacker, id: StringName, data: Dictionary) -> void:
	var bytes: PackedByteArray = _serialize(data)
	var file_name: String = "%s%s" % [id, GAME_INFO_EXT]

	zip_handle.start_file(file_name)
	zip_handle.write_file(bytes)
	zip_handle.close_file()


func save_all_game_info(zip_handle: ZIPPacker, objects: Array[Node]) -> void:
	for n: Node in objects:
		_save_game_info(zip_handle, n.name, n.save())


func _save_other(zip_handle: ZIPPacker, id: StringName, data: Dictionary) -> void:
	var bytes: PackedByteArray = _serialize(data)
	var file_name: String = "%s%s" % [id, OTHER_GROUP]

	zip_handle.start_file(file_name)
	zip_handle.write_file(bytes)
	zip_handle.close_file()


func save_all_other(zip_handle: ZIPPacker, objects: Array[Node]) -> void:
	for n: Node in objects:
		_save_other(zip_handle, n.name, n.save())


func open_file_for_saving(path: String) -> ZIPPacker:
	var zip := ZIPPacker.new()
	zip.open(path, ZIPPacker.APPEND_ADDINZIP)
	return zip


func open_file_for_loading(path: String) -> ZIPReader:
	var zip := ZIPReader.new()
	zip.open(path)
	return zip


func _generate_save_file_name() -> String:
	return "%s%s" % [Time.get_datetime_string_from_system(), SAVE_FILE_EXT]


func save_world(handle: ZIPPacker, world: StringName, rids: Array) -> void:
	var casted_rids := Array(rids, TYPE_STRING_NAME, &"", null)
	var bytes: PackedByteArray = var_to_bytes(casted_rids)
	var file_name: String = "%s%s" % [world, WORLD_EXT]

	handle.start_file(file_name)
	handle.write_file(bytes)
	handle.close_file()
