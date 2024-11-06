extends AttributeEffectFeature

func _get_property_name() -> StringName:
	return &"apply_limit"


func _get_depends_on() -> Array[StringName]:
	return [&"type", &"duration_type", &"irremovable"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type != AttributeEffect.DurationType.INSTANT \
	and effect.type == AttributeEffect.Type.PERMANENT \
	and !effect.irremovable


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false \
	or (effect.duration_type != AttributeEffect.DurationType.INSTANT \
	and effect.type == AttributeEffect.Type.PERMANENT \
	and !effect.irremovable)


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "duration_type != AttributeEffect.DurationType.INSTANT && " + \
		"type == AttributeEffect.Type.PERMANENT && effect.irremovable == false"
	return NO_REQUIREMENTS
