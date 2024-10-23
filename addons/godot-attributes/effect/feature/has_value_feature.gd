@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"has_value"


func _get_depends_on() -> Array[StringName]:
	return [&"type"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return true


func _show_in_editor(effect: AttributeEffect) -> bool:
	return true


func _make_read_only(effect: AttributeEffect) -> bool:
	return effect.type == AttributeEffect.Type.PERMANENT


func _meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value == true || effect.type == AttributeEffect.Type.TEMPORARY


func _get_requirements_string(value: Variant) -> String:
	if value == false:
		return "type == AttributeEffect.Type.TEMPORARY"
	return NO_REQUIREMENTS
