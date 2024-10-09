## Implementation of [ActiveAttributeEffectArray] which has multiple other
## arrays as properties that only store [ActiveAttributeEffect]s with specific behavior
## to speed up the iteration process of those specific active effects.
@tool
class_name ActiveAttributeEffectCluster extends ActiveAttributeEffectArray

## Contains all temporary actives.
var temporaries_w_value: ActiveAttributeEffectArray
## Contains all modifier actives.
var modifiers: ActiveAttributeEffectArray
## Contains all blocker actives.
var blockers: ActiveAttributeEffectArray

func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod) -> void:
	super._init(same_priority_sorting_method, true)
	temporaries_w_value = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	blockers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)


func add(active: ActiveAttributeEffect) -> void:
	super.add(active)
	if active.get_effect().is_temporary() && active.get_effect().has_value:
		temporaries_w_value.add(active)
	if active.get_effect().is_blocker():
		blockers.add(active)
	if active.get_effect().is_modifier():
		modifiers.add(active)



func erase(active: ActiveAttributeEffect, safe: bool = false) -> void:
	super.erase(active, false)
	temporaries_w_value.erase(active, true)
	blockers.erase(active, true)
	modifiers.erase(active, true)

func clear() -> void:
	super.clear()
	temporaries_w_value.clear()
	blockers.clear()
	modifiers.clear()
