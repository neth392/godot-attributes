## Implementation of [ActiveAttributeEffectArray] which has multiple other
## arrays as properties that only store [ActiveAttributeEffect]s with specific behavior
## to speed up the iteration process of those specific active effects.
@tool
class_name ActiveAttributeEffectCluster extends ActiveAttributeEffectArray

## Contains all temporary actives.
var temporaries: ActiveAttributeEffectArray
## Contains all modifier actives.
var modifiers: ActiveAttributeEffectArray
## Contains all blocker actives.
var blockers: ActiveAttributeEffectArray

func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod) -> void:
	super._init(same_priority_sorting_method, true)
	temporaries = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	blockers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)


func add(active: ActiveAttributeEffect) -> void:
	super.add(active)
	if active.get_effect().is_temporary():
		temporaries.add(active)
	if active.get_effect().is_blocker():
		blockers.add(active)
	if active.get_effect().is_modifier():
		modifiers.add(active)


func erase(active: ActiveAttributeEffect, safe: bool = false) -> void:
	super.erase(active, false)
	temporaries.erase(active, true)
	blockers.erase(active, true)
	modifiers.erase(active, true)


func clear() -> void:
	super.clear()
	temporaries.clear()
	blockers.clear()
	modifiers.clear()
