## Represents a floating point value of [AttributeEffect] that can be modified by
## [AttributeEffectModifier]s of the parent class [AttributeEffectModifierArray].
class_name ModifiableValue extends AttributeEffectModifierArray

enum ValueType {
	STATIC,
	ATTRIBUTE_BASE_VALUE,
	ATTRIBUTE_CURRENT_VALUE,
}

@export var type: ValueType

## The floating point value
@export var _value: float:
	get():
		match type:
			ValueType.STATIC:
				return _value
			ValueType.ATTRIBUTE_BASE_VALUE:
				# TODO implement
				assert(false, "ValueType.ATTRIBUTE_BASE_VALUE not yet implemented")
				return 0.0
			ValueType.ATTRIBUTE_CURRENT_VALUE:
				# TODO implement
				assert(false, "ValueType.ATTRIBUTE_CURRENT_VALUE not yet implemented")
				return 0.0
			_:
				assert(false, "no implementation written for type (%s)" % type)
				return 0.0


## Returns the raw, unmodified value.
func get_raw() -> float:
	return _value


## Returns [member value] modified by [member modifiers].
func get_modified(attribute: Attribute, active: ActiveAttributeEffect) -> float:
	return modify_value(_value, attribute, active)
