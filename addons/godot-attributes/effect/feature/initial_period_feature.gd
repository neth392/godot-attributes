extends AttributeEffectFeature

func _get_property_name() -> StringName:
	return &"initial_period"


func _get_depends_on() -> Array[StringName]:
	return [&"period"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.period != null


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || effect.period != null


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "effect.period != null"
	return NO_REQUIREMENTS
