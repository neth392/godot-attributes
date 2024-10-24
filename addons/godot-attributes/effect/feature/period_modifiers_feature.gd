@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"period_modifiers"


func _get_depends_on() -> Array[StringName]:
	return [&"period_modifier"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	var array: Array[AttributeEffectCondition] = []
	if !effect.period_modifier:
		array.make_read_only()
	return array


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.period_modifier


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value.is_read_only() != effect.period_modifier


func _get_requirements_string(value: Variant) -> String:
	if !value.is_read_only():
		return "effect.period_modifier == true"
	else:
		return "effect.period_modifier == false"
