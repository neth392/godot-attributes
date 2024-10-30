## Implementation of [ActiveAttributeEffectArray] which has multiple other
## arrays as properties that only store [ActiveAttributeEffect]s with specific behavior
## to speed up the iteration process of those specific active effects, but the downside
## does result in slightly slower mutations.
@tool
class_name ActiveAttributeEffectCluster extends ActiveAttributeEffectArray

## Contains all actives that require processing; i.e, has a period or duration.
var processing_required: ActiveAttributeEffectArray
## Contains all temporary actives.
var temporaries_w_value: ActiveAttributeEffectArray
## Contains all modifier actives.
var value_modifiers: ActiveAttributeEffectArray
## Contains all modifier actives.
var duration_modifiers: ActiveAttributeEffectArray
## Contains all modifier actives.
var period_modifiers: ActiveAttributeEffectArray
## Contains all add blocker actives.
var add_blockers: ActiveAttributeEffectArray
## Contains all apply blocker actives.
var apply_blockers: ActiveAttributeEffectArray


func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod) -> void:
	super._init(same_priority_sorting_method, true)
	processing_required = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	temporaries_w_value = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	value_modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	duration_modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	period_modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	add_blockers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)
	apply_blockers = ActiveAttributeEffectArray.new(same_priority_sorting_method, false)


func add(active: ActiveAttributeEffect) -> void:
	super.add(active)
	if active.get_effect().has_period() || active.get_effect().has_duration():
		processing_required.add(active)
	if active.get_effect().is_temporary() && active.get_effect().has_value:
		temporaries_w_value.add(active)
	if active.get_effect().add_blocker:
		add_blockers.add(active)
	if active.get_effect().apply_blocker:
		apply_blockers.add(active)
	if active.get_effect().value_modifier:
		value_modifiers.add(active)
	if active.get_effect().period_modifier:
		period_modifiers.add(active)
	if active.get_effect().duration_modifier:
		duration_modifiers.add(active)



func erase(active: ActiveAttributeEffect, safe: bool = false) -> void:
	super.erase(active, false)
	processing_required.erase(active, true)
	temporaries_w_value.erase(active, true)
	add_blockers.erase(active, true)
	apply_blockers.erase(active, true)
	value_modifiers.erase(active, true)
	period_modifiers.erase(active, true)
	duration_modifiers.erase(active, true)


func clear() -> void:
	super.clear()
	processing_required.clear()
	temporaries_w_value.clear()
	add_blockers.clear()
	apply_blockers.clear()
	value_modifiers.clear()
	period_modifiers.clear()
	duration_modifiers.clear()
