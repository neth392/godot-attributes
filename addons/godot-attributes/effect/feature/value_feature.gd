@tool
extends AttributeEffectFeature


func _get_property_name() -> StringName:
	return &"value"


func _get_depends_on() -> Array[StringName]:
	return [&"has_value"]


func _get_default_value(effect: AttributeEffect) -> Variant:
	return AttributeEffectValue.new() if effect.has_value else null


func _show_in_editor(effect: AttributeEffect) -> bool:
	return effect.has_value


func _meets_requirements(value: Variant, effect: AttributeEffect) -> bool:
	return value != null if effect.has_value else effect.value == null


func _get_requirements_string(value: Variant) -> String:
	if value != null:
		return "has_value == true"
	else:
		return "has_value == false"
