class_name WrappedAttributeValidator extends AttributeValueValidator


func _validate(attribute: Attribute, value: float, value_type: Attribute.Value) -> float:
	if value_type == Attribute.Value.BASE_VALUE:
		pass
	else:
		pass
	return value
