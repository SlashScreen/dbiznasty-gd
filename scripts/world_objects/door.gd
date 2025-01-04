@tool
class_name Door
extends InteractiveObject
## Example implementation of an interactive object.
## Interacting with this teleports the interactor.

@export var instance: DoorInstance
@export var destination_instance: DoorInstance
var dest_world: String:
	get:
		return destination_instance.world
var dest_pos: Vector3:
	get:
		return destination_instance.position


func _ready():
	add_to_group(&"network portal")
	if not Engine.is_editor_hint():
		on_interact.connect(_handle_teleport_request.bind())


# You could also override #interact, instead of binding to signal.
func _handle_teleport_request(id: String):
	print("teleporting %s to world %s at position %s" % [id, dest_world, dest_pos])
	var teleportee = SKEntityManager.instance.get_entity(id)  # get an entity
	if teleportee:  # if there is a valid object
		var tc = teleportee.get_component("TeleportComponent")  # Try to get a teleport component
		if tc:
			(tc as TeleportComponent).teleport(dest_world, dest_pos)


func get_coarse_nav_info() -> Dictionary:
	return {
		&"world": instance.world,
		&"position": instance.position,
		&"destination_world": destination_instance.world,
		&"destination_position": destination_instance.position,
	}
