extends AttributeEffectFeature

func _get_property_name() -> StringName:
	return &"apply_limit"


func _get_depends_on() -> Array[StringName]:
	return [&"type", &"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type != AttributeEffect.DurationType.INSTANT \
	and effect.type == AttributeEffect.Type.PERMANENT


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false \
	or effect.duration_type != AttributeEffect.DurationType.INSTANT \
	or effect.type == AttributeEffect.Type.PERMANENT


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "duration_type != AttributeEffect.DurationType.INSTANT && " + \
		"type == AttributeEffect.Type.PERMANENT"
	return NO_REQUIREMENTS
