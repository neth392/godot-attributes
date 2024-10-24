@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"duration"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return AttributeEffectValue.new() if _has_duration(effect) else null


func _show_in_editor(effect: AttributeEffect) -> bool:
	return _has_duration(effect)


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return (value != null) == _has_duration(effect)


func _get_requirements_string(value: Variant) -> String:
	if value != null:
		return "duration_type == AttributeEffect.DurationType.HAS_DURATION"
	else:
		return "duration_type != AttributeEffect.DurationType.HAS_DURATION"


# Shorthand method to make code cleaner here
func _has_duration(effect: AttributeEffect) -> bool:
	return effect.duration_type == AttributeEffect.DurationType.HAS_DURATION
