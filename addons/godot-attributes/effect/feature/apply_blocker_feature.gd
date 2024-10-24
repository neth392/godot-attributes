@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"apply_blocker"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type != AttributeEffect.DurationType.INSTANT


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || effect.duration_type != AttributeEffect.DurationType.INSTANT


func _get_requirements_string(value: Variant) -> String:
	if value == false:
		return NO_REQUIREMENTS
	else:
		return "duration_type != AttributeEffect.DurationType.INSTANT"
