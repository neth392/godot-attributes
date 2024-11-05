## Validates either the base and/or current value of an [Attribute], conducting
## operations such as clamping or rounding.
@tool
class_name AttributeValueValidator extends Resource


## Consumes [param attribute] & [param value] and returns the validated value.
## The [param value_type] is also provided which can be used to determine if this is
## currently a base or current value validator.
func _validate(attribute: Attribute, value: float, value_type: Attribute.Value) -> float:
	return value
