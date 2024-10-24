@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"add_conditions"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	var array: Array[AttributeEffectCondition] = []
	if effect.duration_type == AttributeEffect.DurationType.INSTANT:
		array.make_read_only()
	return array


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type != AttributeEffect.DurationType.INSTANT


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return (effect.duration_type == AttributeEffect.DurationType.INSTANT) == value.is_read_only()


func _get_requirements_string(value: Variant) -> String:
	if !value.is_read_only():
		return "duration_type != AttributeEffect.DurationType.INSTANT"
	else:
		return "duration_type == AttributeEffect.DurationType.INSTANT"
