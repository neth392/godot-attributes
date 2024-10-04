## Represents a floating point value of [AttributeEffect] that can be modified by
## [AttributeEffectModifier]s.
class_name ModifiableValue extends Resource

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

## Any [AttributeEffectModifier]s that can apply to the value.
@export var modifiers: AttributeEffectModifierArray = AttributeEffectModifierArray.new()

## Returns [member value] modified by [member modifiers].
func get_modified(attribute: Attribute, active: ActiveAttributeEffect) -> float:
	return modifiers.modify_value(_value, attribute, active)
