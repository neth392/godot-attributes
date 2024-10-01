@tool
class_name ActiveAttributeEffectCluster extends ActiveAttributeEffectArray

var temporaries: ActiveAttributeEffectArray
var modifiers: ActiveAttributeEffectArray
var blockers: ActiveAttributeEffectArray

func _init(same_priority_sorting_method: Attribute.SamePrioritySortingMethod) -> void:
	super._init(same_priority_sorting_method)
	temporaries = ActiveAttributeEffectArray.new(same_priority_sorting_method)
	modifiers = ActiveAttributeEffectArray.new(same_priority_sorting_method)
	blockers = ActiveAttributeEffectArray.new(same_priority_sorting_method)


func add(active: ActiveAttributeEffect) -> void:
	super.add(active)
	if active.get_effect().is_temporary():
		temporaries.add(active)
	if active.get_effect().is_blocker():
		blockers.add(active)
	if active.get_effect().is_modifier():
		modifiers.add(active)



func erase(active: ActiveAttributeEffect) -> void:
	super.erase(active)
	temporaries.erase(active)
	blockers.erase(active)
	modifiers.erase(active)


func clear() -> void:
	super.clear()
	temporaries.clear()
	blockers.clear()
	modifiers.clear()
