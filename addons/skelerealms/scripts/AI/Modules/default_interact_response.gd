class_name DefaultInteractResponseModule # oh god this is getting java like
extends AIModule


func _initialize() -> void:
	_npc.interacted.connect(on_interact.bind())


func on_interact(refID:StringName) -> void:
	DialogueHooks.start_dialogue(_npc.data.start_dialogue_node, [_npc.parent_entity.name, refID])
	_npc.start_dialogue.emit()
	_npc._busy = true
