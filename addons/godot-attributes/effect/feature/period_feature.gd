@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"period"


func _get_depends_on() -> Array[StringName]:
	return [&"type", &"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return AttributeEffectValue.new() if _has_period(effect) else null


func _show_in_editor(effect: AttributeEffect) -> bool:
	return _has_period(effect)


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return (value != null) == _has_period(effect)


func _get_requirements_string(value: Variant) -> String:
	if value != null:
		return "type == AttributeEffect.Type.PERMANENT && " +\
		"duration_type != AttributeEffect.DurationType.INSTANT"
	else:
		return "type != AttributeEffect.Type.PERMANENT || " +\
		"duration_type == AttributeEffect.DurationType.INSTANT"


# Shorthand method to make code cleaner here
func _has_period(effect: AttributeEffect) -> bool:
	return effect.type == AttributeEffect.Type.PERMANENT \
	and effect.duration_type != AttributeEffect.DurationType.INSTANT
