@tool
extends Node
## A singleton that allows any script to access various important nodes without having to deal with scene scope.
## It also has some important utility functions for working with entities.


## World states for the GOAP system.
var world_states:Dictionary
## Status effects registered in the game.
var status_effects:Dictionary = {}
## The SKConfig resource. 
var config:SKConfig 
## The current character slot being played.
var current_character: int = 0

## Called when the [SKEntityManager] has finished loading.
signal entity_manager_loaded
## When a chest (or other inventory) is opened.
signal inventory_opened(id:StringName)


func _ready() -> void:
	ProjectSettings.settings_changed.connect(_reload_config.bind())
	_reload_config()


func _reload_config() -> void:
	var path:Variant = ProjectSettings.get_setting("skelerealms/config_path")
	
	if path == null:
		return
	if not path is String:
		return
	
	if not ResourceLoader.exists(path):
		config = null
		return 
	
	config = ResourceLoader.load(path)
	
	if Engine.is_editor_hint():
		return
	
	config.compile()
	for se:StatusEffect in config.status_effects:
		SkeleRealmsGlobal.register_effect(se.name, se)


## Attempts to find an entity in the tree above a node. Returns null if none found. Automatically takes account of reparented puppets.
func get_entity_in_tree(child:Node) -> SKEntity:
	var checking = child
	while not checking.get_parent() == null:
		if checking is SKEntity:
			return checking
		
		# Check if puppet and getting puppeteer
		if checking.has_method("get_puppeteer"):
			if checking.get_puppeteer():
				checking = checking.get_puppeteer()
				continue
		
		checking = checking.get_parent()
	
	return null


## Recursively get [RID]s of all children below this node if it is a [CollisionObject3D].
func get_child_rids(child:Node) -> Array:
	var output = []
	
	for c in child.get_children():
		if c is CollisionObject3D:
			output.append(c.get_rid())
		output.append_array(get_child_rids(c))
	
	return output


## Get any damageable node in parent chain or children 1 layer deep; either [DamageableObject] or [DamageableComponent]. Null if none found.
func get_damageable_node(n:Node) -> Node:
	return _walk_for_component(n, "DamageableComponent", func(x:Node): return x is DamageableObject)


## Get any interactible node in parent chain or children 1 layer deep; either [InteractiveObject] or [InteractiveComponent]. Null if none found.
func get_interactive_node(n:Node) -> Node:
	return _walk_for_component(n, "InteractiveComponent", func(x:Node): return x is InteractiveObject)


## Get any spell target node in parent chain or children 1 layer deep; either [SpellTargetObject] or [SpellTargetComponent]. Null if none found.
func get_spell_target_component(n:Node) -> Node:
	return _walk_for_component(n, "SpellTargetComponent", func(x:Node): return x is SpellTargetObject)


## Walks the tree in parent chain above or 1 layer of children below for a node that satisfies one of the following condition:
## - Is an entity with a component of type component_type, returning the component
## - Makes callable wo_check return true
## See [method get_damageable_node] for a use case.
func _walk_for_component(n:Node, component_type:String, wo_check:Callable) -> Node:
	# Check children
	for c in n.get_children():
		if wo_check.call(c):
			return c
	
	# Check for world object in parents
	var checking = n
	while not checking.get_parent() == null:
		if wo_check.call(checking):
			return checking
		
		# Check if puppet and getting puppeteer
		if checking.has_method("get_puppeteer"):
			if checking.get_puppeteer():
				checking = checking.get_puppeteer()
				continue
		
		checking = checking.get_parent()
	
	# Check for entity component
	var e = get_entity_in_tree(n)
	if e:
		var dc = e.get_component(component_type)
		return dc
	
	return null


func register_effect(what:String, eff:StatusEffect) -> void:
	status_effects[what] = eff
