extends AttributeEffectFeature

func _get_property_name() -> StringName:
	return &"apply_limit_amount"


func _get_depends_on() -> Array[StringName]:
	return [&"apply_limit"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return 1


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.apply_limit


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return effect.apply_limit && value > 0


func _get_requirements_string(value: Variant) -> String:
	return "apply_limit == true && apply_limit_amount > 0"
