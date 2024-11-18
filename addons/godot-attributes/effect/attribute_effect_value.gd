## Represents a floating point value of an [AttributeEffect] that can be modified by
## [AttributeEffectModifier]s of the parent class [AttributeEffectModifierArray].
@tool
class_name AttributeEffectValue extends AttributeEffectModifierArray

## The floating point value, unmodified.
@export var unmodified_value: float


func _init(_unmodified_value: float = 0.0) -> void:
	unmodified_value = _unmodified_value


## Returns the raw, unmodified value.
func get_raw() -> float:
	return unmodified_value


## Returns [member value] modified by [member modifiers].
func get_modified(attribute: Attribute, active: ActiveAttributeEffect) -> float:
	return modify_value(get_raw(), attribute, active)
