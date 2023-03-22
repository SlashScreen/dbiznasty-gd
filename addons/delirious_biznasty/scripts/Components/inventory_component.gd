class_name InventoryComponent 
extends EntityComponent
## Keeps track of an inventory.

## The RefIDs of the items in the inventory.
var inventory: PackedStringArray
## The amount of cash moneys.
var snails: int


## Add an item to the inventory.
func add_to_inventory(id:String):
	var e = (%EntityManager as EntityManager).get_entity(id)
	if e.some():
		var ic = (e.unwrap() as Entity).get_component("ItemComponent")
		if ic.some():
			(ic.unwrap() as ItemComponent).move_to_inventory(id)
			inventory.append(id)


## Remove an item from the inventory.
func remove_from_inventory(id:String):
	inventory.remove_at(inventory.find(id))


## Add an amount of snails to the inventory.
func add_snails(amount:int):
	snails += amount
	_clamp_snails()


## Remove some snails from the inventory.
func remove_snails(amount:int):
	snails -= amount
	_clamp_snails()

## Keeps the number of snails from going below 0.
func _clamp_snails():
	if snails < 0:
		snails = 0
