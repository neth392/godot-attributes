## A validator which can only be applied to [WrappedAttribute]s. Ensures that
## the base & current values never exceed their set min & max.
class_name WrappedAttributeValidator extends AttributeValueValidator

func _validate(attribute: Attribute, value: float, value_type: Attribute.Value) -> float:
	assert(attribute is WrappedAttribute, "%s not of type WrappedAttribute" % attribute)
	var wrapped_attribute: WrappedAttribute = attribute as WrappedAttribute
	# Base value
	if value_type == Attribute.Value.BASE_VALUE:
		# Base min
		if wrapped_attribute.has_base_min():
			var base_min: float = wrapped_attribute._get_base_min_value()
			if value < base_min:
				return base_min
		# Base max
		if wrapped_attribute.has_base_max():
			var base_max: float = wrapped_attribute._get_base_max_value()
			if value > base_max:
				return base_max
		return value
	# Current value
	else:
		# Current min
		if wrapped_attribute.has_current_min():
			var current_min: float = wrapped_attribute._get_current_min_value()
			if value < current_min:
				return current_min
		# Current max
		if wrapped_attribute.has_current_max():
			var current_max: float = wrapped_attribute._get_current_max_value()
			if value > current_max:
				return current_max
		return value
