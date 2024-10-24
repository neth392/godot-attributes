extends AttributeEffectFeature

func _get_property_name() -> StringName:
	return &"apply_on_expire_if_period_is_zero"


func _get_depends_on() -> Array[StringName]:
	return [&"period", &"apply_on_expire"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.period != null && !effect.apply_on_expire


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || (effect.period != null && !effect.apply_on_expire)


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "effect.period != null && effect.apply_on_expire == false"
	return NO_REQUIREMENTS
