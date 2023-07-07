class_name EquipmentComponent
extends EntityComponent


var equipment_slot:Dictionary

signal equipped(item:StringName, slot:EquipmentSlots.Slots)
signal unequipped(item:StringName, slot:EquipmentSlots.Slots)


func _init() -> void:
	name = "EquipmentComponent"


func _ready() -> void:
	super._ready()


func equip(item:StringName, slot:EquipmentSlots.Slots, silent:bool = false) -> bool:
	# Get component
	var e = EntityManager.instance.get_entity(item)
	if not e.some():
		return false
	# Get item component
	var ic = e.unwrap().get_component("ItemComponent")
	if not ic.some():
		return false
	# Get equippable data component
	var ec = (ic.unwrap() as ItemComponent).data.get_component("EquippableDataComponent")
	if not ec.some():
		return false
	# Check slot validity
	if not (ec.unwrap() as EquippableDataComponent).valid_slots.has(slot):
		return false
	# Unequip if already in slot so we ca nput it in a new slot
	unequip_item(item)

	equipment_slot[slot] = item
	if not silent:
		equipped.emit(item, slot)
	return true


## Unequip anything in a slot.
func clear_slot(slot:EquipmentSlots.Slots, silent:bool = false) -> void:
	if equipment_slot.has(slot):
		var to_unequip = equipment_slot[slot]
		equipment_slot[slot] = null
		if not silent:
			unequipped.emit(to_unequip, slot)


## Unequip a specific item, no matter what slot it's in.
func unequip_item(item:StringName, silent:bool = false) -> void:
	for s in equipment_slot:
		if equipment_slot[s] == item:
			equipment_slot[s] = null
			if not silent:
				unequipped.emit(item, s)
			return


func is_item_equipped(item:StringName, slot:EquipmentSlots.Slots) -> bool:
	if not equipment_slot.has(slot):
		return false
	return equipment_slot[slot] == item


func is_slot_occupied(slot:EquipmentSlots.Slots) -> Option:
	if equipment_slot.has(slot):
		return Option.wrap(equipment_slot[slot])
	else:
		return Option.none()
