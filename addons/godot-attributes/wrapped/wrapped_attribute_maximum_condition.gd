## TODO docs
class_name WrappedAttributeMaximumCondition extends AttributeEffectCondition


func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	if (!attribute is WrappedAttribute) || !active.get_effect().has_value:
		return true
	
	if active.get_effect().is_permanent():
		return attribute.has_base_max() \
		and attribute.get_base_max_value() >= active.get_pending_raw_attribute_value()
	else:
		return attribute.has_current_max() \
		and attribute.get_current_max_value() >= active.get_pending_raw_attribute_value()
