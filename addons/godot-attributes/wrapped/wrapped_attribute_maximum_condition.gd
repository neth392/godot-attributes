## A condition that will deny an [ActiveAttributeEffect] from applying.
class_name WrappedAttributeMaximumCondition extends AttributeEffectCondition


func _init() -> void:
	pass


## Returns true if the [param attribute] & [param active] meets the conditions.
func _meets_condition(attribute: Attribute, active: ActiveAttributeEffect) -> bool:
	assert(attribute is WrappedAttribute, "attribute not of type WrappedAttribute")
	if active.get_effect().has_value:
		var wrapped: WrappedAttribute = attribute as WrappedAttribute
		wrapped.get_maximum_value()
		# TODO finish
	return true
