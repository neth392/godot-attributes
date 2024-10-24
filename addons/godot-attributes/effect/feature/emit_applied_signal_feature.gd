@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"emit_applied_signal"


func _get_depends_on() -> Array[StringName]:
	return [&"type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return false


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.type == AttributeEffect.Type.PERMANENT


func _value_meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == false || effect.type == AttributeEffect.Type.PERMANENT


func _get_requirements_string(value: Variant) -> String:
	if value == true:
		return "type == AttributeEffect.Type.PERMANENT"
	return NO_REQUIREMENTS
