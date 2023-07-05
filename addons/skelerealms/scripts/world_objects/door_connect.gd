class_name DoorJumpPlugin
extends EditorInspectorPlugin


var p:EditorPlugin


func _can_handle(object):
	return object is Door


func _parse_begin(obj:Object):
	var go_to_button:Button = Button.new()
	go_to_button.text = "Jump to door location"
	go_to_button.pressed.connect(func(): _jump_to_door_location(obj as Door))
	add_custom_control(go_to_button)
	var set_position_button:Button = Button.new()
	set_position_button.text = "Set position data"
	set_position_button.pressed.connect(func(): _set_position(obj as Door))
	add_custom_control(set_position_button)


func _jump_to_door_location(obj:Door):
	var path = ProjectSettings.get_setting("skelerealms/worlds_path")
	var res = _find_world(path, obj.destination_instance.world)
	if res == "":
		return
	print("Jumping to location...")
	# Workaround from https://github.com/godotengine/godot/issues/75669#issuecomment-1621230016
	p.get_editor_interface().open_scene_from_path.call_deferred(res)
	p.get_editor_interface().edit_resource.call_deferred(load(res)) # switch tab


func _set_position(obj:Door) -> void:
	obj.instance.position = obj.position
	obj.instance.world = obj.owner.name


func _find_world(path:String, target:String) -> String:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir(): # if is directory, search subdirectory
				var res = _find_world(file_name, target)
				if not res == "":
					return res
			else: # if filename, cache filename
				var result = file_name.contains(target)
				if result:
					return "%s/%s" % [path, file_name] 
			file_name = dir.get_next()
		dir.list_dir_end()
	return ""


func _init(plug:EditorPlugin):
	p = plug
