@tool
class_name SKConfig
extends Resource

## This resource is needed to configure some Skelerealms behavior without changing code in the addon scripts itself.
## This should be given to an [class SKEntityManager] to be used.

## The equipment slots available to the equipment.
@export var equipment_slots: Array[StringName]
## Default skills for [class SkillsComponent]s.
@export var skills: Dictionary = {}
## Default attributes for [class AttributesComponent]s.
@export var attributes: Dictionary = {}
## The tag tracker for the different kinds of special objects.
@export var tag_tracker: SKTagTracker
## Status effects that will be registered when the game starts.
@export var status_effects: Array[StatusEffect] = []
## The formula for determining the amount of XP needed for a skill to level up, in GDScript. The given skill level is the current skill level,
## and the formula's result (int) is the XP needed to raise to the next level.
## Inputs: skill_level (int)
## Outputs: int
@export_multiline var skill_xp_formula: String
## The formula for determining the amount of XP needed for a character to level up, in GDScript. The given character level is the current character level,
## and the formula's result (int) is the XP needed to raise to the next level
## Inputs: character_level (int)
## Outputs: int
@export_multiline var character_xp_formula: String
## The compiled skill xp check expression.
var compiled_skill: Expression
## The compiles character xp check expression.
var compiled_character: Expression


func compile() -> void:
	compiled_skill = Expression.new()
	var err: Error = compiled_skill.parse(skill_xp_formula, PackedStringArray(["skill_level"]))
	if not err == 0:
		push_error("Skill level expression compilation failed: ", compiled_skill.get_error_text(), " - Check your SKConfig resource.")
		return

	compiled_character = Expression.new()
	err = compiled_character.parse(character_xp_formula, PackedStringArray(["character_level"]))
	if not err == 0:
		push_error("Character level expression compilation failed: ", compiled_character.get_error_text(), " - Check your SKConfig resource.")


## Compute the skill xp needed to level up.
func compute_skill(level: int) -> int:
	var res: Variant = compiled_skill.execute([level])
	if compiled_skill.has_execute_failed():
		push_error("Skill level expression execution failed: ", compiled_skill.get_error_text(), " - Check your SKConfig resource.")
		return -1
	if not res is int:
		push_error("Skill level expression did not return an integer.")
		return -1
	return res as int


## Compute the character xp needed to level up.
func compute_character(level: int) -> int:
	var res: Variant = compiled_character.execute([level])
	if compiled_character.has_execute_failed():
		push_error("Character level expression execution failed: ", compiled_character.get_error_text(), " - Check your SKConfig resource.")
		return -1
	if not res is int:
		push_error("Character level expression did not return an integer.")
		return -1
	return res as int
