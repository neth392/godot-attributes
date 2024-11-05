## TODO docs
class_name WrappedAttributeMinimumCondition extends AttributeEffectCondition


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	if (!attribute is WrappedAttribute) || !active.get_effect().has_value:
		return true
	
	if active.get_effect().is_permanent():
		return attribute.has_base_min() \
		and attribute.get_base_min_value() <= active.get_pending_final_attribute_value()
	else:
		return attribute.has_current_min() \
		and attribute.get_current_min_value() <= active.get_pending_final_attribute_value()
