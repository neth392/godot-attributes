## Represents a floating point value of an [AttributeEffect] that can be modified by
## [AttributeEffectModifier]s of the parent class [AttributeEffectModifierArray].
@tool
class_name AttributeEffectValue extends AttributeEffectModifierArray

## The floating point value
@export var _value: float


func _init(value: float = 0.0) -> void:
	_value = value


## Returns the raw, unmodified value.
func get_raw() -> float:
	return _value


## Returns [member value] modified by [member modifiers].
func get_modified(attribute: Attribute, active: ActiveAttributeEffect) -> float:
	return modify_value(get_raw(), attribute, active)
