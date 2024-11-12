## TODO docs
class_name WrappedAttributeMaximumCondition extends AttributeEffectCondition


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	if !active.get_effect().has_value:
		return true
	
	if attribute is WrappedAttribute:
		if attribute.block_effects_below_base_min
	
	return true
