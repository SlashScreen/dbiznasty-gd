@tool
extends EditorContextMenuPlugin

enum {
	NONE_BUTTON,
	WORLD_BUTTON,
	ENTITY_BUTTON,
	NETWORK_BUTTON,
}

const PATTERN := "(?:[^\\/\n\\r]+)\\.(?:t?scn|t?res)"

var regex := RegEx.new()
var tag_tracker: SKTagTracker


func _popup_menu(paths: PackedStringArray) -> void:
	if not regex.is_valid():
		regex.compile(PATTERN)
	
	if paths.size() > 1:
		return
	
	if regex.search(paths[0]):
		add_context_submenu_item("Skelerealms", setup_popup(paths[0]))


func setup_popup(path: String) -> PopupMenu:
	print("Setup popup")
	var new_popup: PopupMenu = PopupMenu.new()
	
	new_popup.add_radio_check_item("Is None", NONE_BUTTON)
	new_popup.add_radio_check_item("Is World", WORLD_BUTTON)
	new_popup.add_radio_check_item("Is Entity", ENTITY_BUTTON)
	new_popup.add_radio_check_item("Is Network", NETWORK_BUTTON)
	
	var is_scene := path.ends_with(".tscn") or path.ends_with(".scn")
	try_load_tracker()
	
	if tag_tracker.is_world(path):
		new_popup.set_item_checked(WORLD_BUTTON, true)
	elif tag_tracker.is_entity(path):
		new_popup.set_item_checked(ENTITY_BUTTON, true)
	elif tag_tracker.is_network(path):
		new_popup.set_item_checked(NETWORK_BUTTON, true)
	else:
		new_popup.set_item_checked(NONE_BUTTON, true)
	print("Set initial value")
	if is_scene:
		new_popup.set_item_disabled(NETWORK_BUTTON, true)
	else:
		new_popup.set_item_disabled(WORLD_BUTTON, true)
		new_popup.set_item_disabled(ENTITY_BUTTON, true)
	print("Set enabled")
	new_popup.id_pressed.connect(handle_menu_selection.bind(path))
	print("Connected")
	return new_popup


func handle_menu_selection(id: int, path: String) -> void:
	try_load_tracker()
	
	match id:
		NONE_BUTTON:
			tag_tracker.remove_entity(path)
			tag_tracker.remove_network(path)
			tag_tracker.remove_world(path)
		WORLD_BUTTON:
			tag_tracker.remove_entity(path)
			tag_tracker.remove_network(path)
			tag_tracker.add_world(path)
		ENTITY_BUTTON:
			tag_tracker.remove_entity(path)
			tag_tracker.remove_network(path)
			tag_tracker.add_entity(path)
		NETWORK_BUTTON:
			tag_tracker.remove_entity(path)
			tag_tracker.remove_world(path)
			tag_tracker.add_network(path)


func try_load_tracker() -> void:
	if tag_tracker == null:
		tag_tracker = (ResourceLoader.load(ProjectSettings.get_setting("skelerealms/config_path")) as SKConfig).tag_tracker
