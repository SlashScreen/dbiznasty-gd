class_name SKEntityManager
extends Node
## Manages entities in the game.

## The instance of the entity manager.
static var instance: SKEntityManager

var entities: Dictionary[StringName, SKEntity] = {}
var erased_entities: Array[StringName] = []
@onready var tag_tracker: SKTagTracker = (ResourceLoader.load(ProjectSettings.get_setting("skelerealms/config_path")) as SKConfig).tag_tracker


func _init() -> void:
	instance = self


func _ready():
	SkeleRealmsGlobal.entity_manager_loaded.emit()


## Gets an entity in the game. [br]
## This system follows a cascading pattern, and attempts to get entities by following the following steps. It will execute each step, and if it fails to get an entity, it will move onto the next one. [br]
## 1. Tries to get the entity from its internal hash table of entities. [br]
## 2. Scans its children entities to see if it missed any (this step may be removed in the future) [br]
## 3. Attempts to load the entity from disk. [br]
## Failing all of these, it will return [code]none[/code].
func get_entity(id: StringName) -> SKEntity:
	# stage 1: attempt find in cache
	if entities.has(id):
		(entities[id] as SKEntity).reset_stale_timer()  # FIXME: If another entity is carrying a reference to this entity, then we might break stuff by cleaning it up in this way?
		return entities[id]
	# stage 2: Check in save file
	var potential_data = SaveSystem.entity_in_save(id)  # check the save system
	if not potential_data.is_empty():  # if found:
		var e: SKEntity = add_entity_from_scene(ResourceLoader.load(ResourceUID.get_id_path(tag_tracker.get_uid_for_name(id))))  # load default from disk
		e.load_data(potential_data)  # and then load using the data blob we got from the save file
		e.reset_stale_timer()
		return e
	# stage 3: check on disk
	if tag_tracker.is_name_entity(id):
		var e: SKEntity = add_entity_from_scene(ResourceLoader.load(ResourceUID.get_id_path(tag_tracker.get_uid_for_name(id))))
		e.generate()  # generate, because the entity has never been seen before
		e.reset_stale_timer()
		return e

	# Other than that, we've failed. Attempt to find the entity in the child count as a failsave, then return none.
	return get_node_or_null(id as String)


# add a new entity.
#func add_entity(res: InstanceData) -> SKEntity:
#var new_entity = SKEntity.new(res)  # make a new entity
# add new entity to self, and the dictionary
#entities[res.ref_id] = new_entity
#add_child(new_entity)
#return new_entity


func _add_entity_raw(e: SKEntity) -> SKEntity:
	entities[e.name] = e
	add_child(e)
	return e


## ONLY call after save!!!
func _cleanup_stale_entities():
	# Get all children
	for c in get_children():
		if (c as SKEntity).stale_timer >= ProjectSettings.get_setting("skelerealms/entity_cleanup_timer"):  # If stale timer is beyond threshold
			remove_entity(c.name)  # remove


## Remove entity from the game.
func remove_entity(rid: StringName) -> void:
	if entities.has(rid):
		entities[rid].queue_free()
		entities.erase(rid)
		erased_entities.append(rid)


func add_entity_from_scene(scene: PackedScene) -> SKEntity:
	var e: SKEntity = scene.instantiate()
	if not e:
		push_error("Scene at path %s isn't a valid entity." % scene.resource_path)

	if not e.unique:
		var valid: bool = false
		var new_id: String = ""
		while not valid:
			new_id = SKIDGenerator.generate_id()
			valid = not entities.has(new_id)
			e.generate.call_deferred()
		e.name = new_id
	return _add_entity_raw(e)


# TODO: Store this, so that when a world is loaded, we touch all the entities
## Generates a dictionary that maps worlds to a list of entity rids that are inside them.
func get_entities_in_worlds() -> Dictionary[StringName, Array]:
	var res: Dictionary[StringName, Array] = {}
	for rid: StringName in entities:
		var world: StringName = entities[rid].world
		res.get_or_add(world, []).append(String(rid))
	return res
