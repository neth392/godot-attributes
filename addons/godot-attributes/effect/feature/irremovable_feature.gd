@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"irremovable"


func _get_depends_on() -> Array[StringName]:
	return [&"duration_type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.duration_type == AttributeEffect.DurationType.INFINITE


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || effect.duration_type == AttributeEffect.DurationType.INFINITE


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "effect.duration_type == AttributeEffect.DurationType.INFINITE"
	return NO_REQUIREMENTS
