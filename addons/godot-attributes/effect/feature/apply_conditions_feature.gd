@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"apply_conditions"


func _get_depends_on() -> Array[StringName]:
	return [&"has_apply_conditions"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	var array: Array[AttributeEffectCondition] = []
	if !effect.has_apply_conditions:
		array.make_read_only()
	return array


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.has_apply_conditions


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return effect.has_apply_conditions != value.is_read_only()


func _get_requirements_string(value: Variant) -> String:
	if !value.is_read_only():
		return "has_apply_conditions == true"
	else:
		return "has_apply_conditions == false"
