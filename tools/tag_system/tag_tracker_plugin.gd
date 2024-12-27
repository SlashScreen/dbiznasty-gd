extends EditorContextMenuPlugin

const PATTERN := "(?:[^\\/\n\\r]+)\\.(?:t?scn|t?res)"

var regex := RegEx.new()
var tag_tracker: SKTagTracker


func _popup_menu(paths: PackedStringArray) -> void:
	if not regex.is_valid():
		regex.compile(PATTERN)
	
	if paths.size() > 1:
		return
	
	if regex.search(paths[0]):
		add_context_menu_item("Set as world", handle_world_add.bind())


func handle_world_add(paths: Array) -> void:
	var path: String = paths.front()
	if tag_tracker == null:
		tag_tracker = (ResourceLoader.load(ProjectSettings.get_setting("skelerealms/config_path")) as SKConfig).tag_tracker
	
	tag_tracker.add_world(path)
