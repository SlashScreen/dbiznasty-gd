extends Node
## OBEY THE CRIME MASTER[br]
## This keeps track of any crimes committed against various [Coven]s.


## Bounty amounts for various crime severity levels.
const bounty_amount:Dictionary = {
	0 : 0,
	1 : 500,
	2 : 10000,
	5 : 100000,
}


## Tracked crimes.
## [codeblock]
## {
##		coven: {
##			"punished" : []
##			"unpunished": []
##		}
## }
## [/codeblock]
var crimes:Dictionary = {}
## This is a has set. All crimes reported will go into this set to be processed in the next frame.
## This is so that the same crime doesn't get reported over and over again. 
var crime_queue:Dictionary = {}
signal crimes_against_covens_updated(affected:Array[StringName])
signal crime_committed(crime:Crime, position:NavPoint)


func _ready():
	add_to_group("savegame_gameinfo")


## Move all unpunished crimes to punished crimes.
func punish_crimes(coven:StringName):
	crimes[coven]["punished"].append(crimes[coven]["unpunished"])
	crimes[coven]["unpunished"].clear


# TODO: Track crimes against others?
## Report a crime. The caller is also added as a witness.
func add_crime(crime:Crime, witness:StringName):
	crime_queue[crime] = true


func _process_crime_queue() -> void:
	if crime_queue.size() > 0:
		for crime in crime_queue:
		# add crime to covens
			var cc = EntityManager.instance.get_entity(crime.victim).unwrap().get_component("CovensComponent")
			if cc.some():
				for coven in (cc.unwrap() as CovensComponent).covens:
					## Skip if doesn't track crime
					if not CovenSystem.get_coven(coven).track_crime:
						continue

					if crimes.has(coven):
						crimes[coven]["unpunished"].append(crime)
					else: # if coven doesnt have crimes against it, initialize table
						crimes[coven] = {
							"punished" : [],
							"unpunished" : [crime]
						}
				crimes_against_covens_updated.emit((cc.unwrap() as CovensComponent).covens)
		crime_queue.clear()

## Returns the max wanted level for crimes against a Coven.
func max_crime_severity(id:StringName, coven:StringName) -> int:
	if not crimes.has(coven):
		return 0
	var cr = crimes[coven]["unpunished"]\
		.filter(func(x:Crime): return x.perpetrator == id)\
		.map(func(x:Crime): return x.severity)
	return 0 if cr.is_empty() else cr.max()


## Calculate the bounty a Coven has for an entity.
func bounty_for_coven(id:StringName, coven:StringName) -> int:
	if not crimes.has(coven):
		return 0
	return crimes[coven]["unpunished"]\
		.filter(func(x:Crime): return x.perpetrator == id)\
		.reduce(func(sum:int, x:Crime): return sum + bounty_amount[x.severity], 0)


func save() -> Dictionary:
	return {
		"crime" : crimes
	}


func load_data(data:Dictionary) -> void:
	crimes = data["crime"]


func reset_data() -> void:
	crimes = {}
