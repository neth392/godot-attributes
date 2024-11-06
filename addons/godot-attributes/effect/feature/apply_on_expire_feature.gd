@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"apply_on_expire"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type", &"irremovable"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return _has_duration(effect) && !effect.irremovable


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || (_has_duration(effect) && !effect.irremovable)


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "duration_type == AttributeEffect.DurationType.HAS_DURATION && effect.irremovable == false"
	return NO_REQUIREMENTS


# Shorthand method to make code cleaner here
func _has_duration(effect: AttributeEffect) -> bool:
	return effect.duration_type == AttributeEffect.DurationType.HAS_DURATION
