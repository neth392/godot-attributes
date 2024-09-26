## A condition that will deny an [ActiveAttributeEffect] from applying.
class_name WrappedAttributeMaximumCondition extends AttributeEffectCondition


## Returns true if the [param attribute] & [param active] meets the conditions.
func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	assert(attribute is WrappedAttribute, "attribute not of type WrappedAttribute")
	if active.get_effect().is_permanent():
		var wrapped: WrappedAttribute = attribute as WrappedAttribute
		wrapped.get_maximum_value()
		# TODO (what was this for?)
	return true
